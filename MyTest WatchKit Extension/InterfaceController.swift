//
//  InterfaceController.swift
//  MyTest WatchKit Extension
//
//  Created by 沈文 on 2018/11/20.
//  Copyright © 2018 沈文. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController,HKWorkoutSessionDelegate {

    
    @IBOutlet weak var HRlabel: WKInterfaceLabel!
    @IBOutlet weak var acclabel: WKInterfaceLabel!
    @IBOutlet weak var gyrlabel: WKInterfaceLabel!
    @IBOutlet weak var timelabel: WKInterfaceLabel!
    @IBOutlet weak var loglabel: WKInterfaceLabel!
    @IBOutlet weak var starStopBtn: WKInterfaceButton!
    
    let healthStore = HKHealthStore()
    let heartRateUnit = HKUnit(from: "count/min")
    var currenQuery : HKQuery?
    //State of the app - is the workout activated
    var workoutActive = false
    
    var workoutSession : HKWorkoutSession?
    var workoutStarDate : Date?
    var workoutEndDate : Date?
    var workoutEvents = [HKWorkoutEvent]()
    var metadata = [String: Any]()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        guard HKHealthStore.isHealthDataAvailable() == true else {
            loglabel.setText("HealthData not available")
            return
        }
        
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            displayNotAllowed()
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success == false {
                self.displayNotAllowed()
            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func displayNotAllowed() {
        loglabel.setText("not allowed")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            workoutDidStart(date)
        case .ended:
            workoutDidEnd(date)
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // Do nothing for now
        print("Workout error")
    }
    
    func workoutDidStart(_ date : Date) {
        if let query = createHeartRateStreamingQuery(date) {
            self.currenQuery = query
            healthStore.execute(query)
        } else {
            loglabel.setText("cannot start")
        }
    }
    
    func workoutDidEnd(_ date : Date) {
        healthStore.stop(self.currenQuery!)
        
        workoutSession = nil
    }
    
    @IBAction func startBtnTaped() {
        if (self.workoutActive) {
            //finish the current workout
            self.workoutActive = false
            self.starStopBtn.setTitle("Start")
            if let workout = self.workoutSession {
                healthStore.end(workout)
            }
        } else {
            //start a new workout
            self.workoutActive = true
            self.starStopBtn.setTitle("Stop")
            startWorkout()
        }
    }
    
    func startWorkout() {
        
        // If we have already started the workout, then do nothing.
        if (workoutSession != nil) {
            return
        }
        
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .crossTraining
        workoutConfiguration.locationType = .indoor
        
        do {
            workoutSession = try HKWorkoutSession(configuration: workoutConfiguration)
            workoutSession?.delegate = self
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        healthStore.start(self.workoutSession!)
    }
    
    func createHeartRateStreamingQuery(_ workoutStartDate: Date) -> HKQuery? {
        
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return nil }
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictEndDate )
        //let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate])
        
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            //guard let newAnchor = newAnchor else {return}
            //self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            //self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }

    func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        DispatchQueue.main.async {
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValue(for: self.heartRateUnit)
            self.HRlabel.setText(String(UInt16(value)))
            
            // retrieve source from sample
//            let name = sample.sourceRevision.source.name
//            self.updateDeviceName(name)
//            self.animateHeart()
        }
    }
    
    
    


}
