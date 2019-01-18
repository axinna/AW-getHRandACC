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
import CoreMotion
import WatchConnectivity

class InterfaceController: WKInterfaceController,HKWorkoutSessionDelegate, WCSessionDelegate {

    var count = 0
    
    @IBOutlet weak var HRlabel: WKInterfaceLabel!
    @IBOutlet weak var accXlabel: WKInterfaceLabel!
    @IBOutlet weak var accYlabel: WKInterfaceLabel!
    @IBOutlet weak var accZlabel: WKInterfaceLabel!
    @IBOutlet weak var gyrlabel: WKInterfaceLabel!
    @IBOutlet weak var timelabel: WKInterfaceLabel!
    @IBOutlet weak var loglabel: WKInterfaceLabel!
    @IBOutlet weak var starStopBtn: WKInterfaceButton!
    
    let healthStore = HKHealthStore()
    let heartRateUnit = HKUnit(from: "count/min")
    var currenQuery : HKQuery?
    //State of the app - is the workout activated
    var workoutActive = false
    var heartRateProducedTime :Date?
    var workoutSession : HKWorkoutSession?
    var workoutStarDate : Date?
    var workoutEndDate : Date?
    var workoutEvents = [HKWorkoutEvent]()
    var metadata = [String: Any]()
    
    //加速度 陀螺仪
    let manager = CMMotionManager()
    var managerActive = false
    
    // MARK: Properties 消息传输
    let session: WCSession!
    var messageDict = [String: Double]() //消息传输字典
    
    // life cycle
    override init() {
        if(WCSession.isSupported()) {
            session =  WCSession.default
        } else {
            session = nil
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        if manager.isAccelerometerAvailable{
            accXlabel.setTextColor(UIColor.green)
            accYlabel.setTextColor(UIColor.green)
            accZlabel.setTextColor(UIColor.green)
        }
        
        if manager.isGyroAvailable{
            gyrlabel.setTextColor(UIColor.green)
        }
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if (WCSession.isSupported()) {
            session.delegate = self
            session.activate()
        }
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
    
    
    //
    @IBAction func startBtnTaped() {
        if (self.workoutActive) {
            //finish the current workout
            self.workoutActive = false
            self.starStopBtn.setTitle("To Start")
            self.starStopBtn.setBackgroundColor(UIColor.red)
            if let workout = self.workoutSession {
                healthStore.end(workout)
            }
        } else {
            //start a new workout
            self.workoutActive = true
            self.starStopBtn.setTitle("To Stop")
            self.starStopBtn.setBackgroundColor(UIColor.green)
            startWorkout()
        }
        /////////////////
        if (self.managerActive) {
            self.managerActive = false
            self.manager.stopAccelerometerUpdates()
        }else{
            self.managerActive = true
            manager.accelerometerUpdateInterval = 1
            manager.startAccelerometerUpdates(to: OperationQueue.main){
                (data, error) -> Void in
                if data == nil{
                    return
                }
                
                self.messageDict.updateValue(data!.acceleration.x, forKey: "accX")
                self.messageDict.updateValue(data!.acceleration.y, forKey: "accY")
                self.messageDict.updateValue(data!.acceleration.z, forKey: "accZ")
                self.accXlabel.setText(String(self.messageDict["accX"]!))
                self.accYlabel.setText(String(self.messageDict["accY"]!))
                self.accZlabel.setText(String(self.messageDict["accZ"]!))
            }
            
        }
        /////////////////

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
//            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            //self.anchor = newAnchor!
            self.updateHeartRate(samples)
            //
            self.mysendData()
            // samples 产生的时间
            self.heartRateProducedTime = Date()
            let dformatter = DateFormatter()
            dformatter.dateFormat = "HH:mm:ss"
            self.timelabel.setText("\(dformatter.string(from: self.heartRateProducedTime!))")
        }
        return heartRateQuery
    }

    func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        guard let sample = heartRateSamples.first else{return}
        let value = sample.quantity.doubleValue(for: self.heartRateUnit)
        self.messageDict.updateValue(value, forKey: "heart rate")
        DispatchQueue.main.async {
            self.HRlabel.setText(String(UInt16(self.messageDict["heart rate"] ?? 0)))
        }
    }
    
    // 消息f传输。
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else {
            self.loglabel.setText("WCSession is not activated.")
            return
        }

    }
    
    func mysendData()  {
        
        self.count = count + 1
        if (WCSession.isSupported()) {
            
            session.sendMessage(self.messageDict, replyHandler: { (content: [String: Any]) -> Void in
                print("Our counterpart sent something back. This is optional")
            }, errorHandler: { (error) -> Void in
                print("Watch ： We got an error from our paired device : \(error.localizedDescription)")
            })
        }
    }
    

 
    
    @IBAction func myclean() {
        self.count = 0
        self.accXlabel.setText("accx")
        self.accYlabel.setText("accy")
        self.accZlabel.setText("accz")
        self.loglabel.setText("log")
        self.timelabel.setText("time")
        self.HRlabel.setText("heart rate")
    }
    

}
