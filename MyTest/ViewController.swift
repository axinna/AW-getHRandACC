//
//  ViewController.swift
//  MyTest
//
//  Created by 沈文 on 2018/11/20.
//  Copyright © 2018 沈文. All rights reserved.
//

import UIKit
import HealthKit

class ViewController:  UIViewController{


    var healthStore = HKHealthStore()
    let heartRateUnit:HKUnit = HKUnit(from: "count/min")
    let heartRateVariabilityUnit:HKUnit = HKUnit(from: "ms")
    let stepCountUnit: HKUnit = HKUnit(from: LengthFormatter.Unit.meter)
    var myAnchor: HKQueryAnchor? = nil
    
    @IBAction func testButton(_ sender: Any) {
        print("press button")
//        self.testHKAnchorObjectQueue()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("hahaha")
        // Do any additional setup after loading the view, typically from a nib.
        self.activateHealthKit()

    }
    
    
    // TODO：requestAuthorization 要修改 info.plist 不然闪退
    func activateHealthKit() {
        // Define what HealthKit data we want to ask to read
        let typestoRead = Set([
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
            , HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
            , HKObjectType.quantityType(forIdentifier: .stepCount)!])
        
        // Define what HealthKit data we want to ask to write
        let typestoShare = Set([
            HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
            ,HKObjectType.quantityType(forIdentifier: .stepCount)!])
        
        // Prompt the User for HealthKit Authorization
        self.healthStore.requestAuthorization(toShare: typestoShare, read: typestoRead) { (success, error) -> Void in
            if !success{
                print("HealthKit Auth error\(error)")
            }else{
                print("seccessfully get healthKit authorization")
            }
            self.retrieveValues()
//            self.testHKAnchorObjectQueue()
//            self.testObseverQueue()
        }
    }
    
    func retrieveValues()  {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let heartRateVariabilityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        let stepCountType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        
        let sortDesc = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        // Get all samples from the last 24 hours
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-1.0 * 60.0 * 5.0)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let query = HKSampleQuery(sampleType: heartRateVariabilityType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDesc])
        {
            (query, samplesOrNil, error) in
            if let samples = samplesOrNil {
                print("样本数据长度为：  \(samples.count)")
                for i in stride(from: 0, to: samples.count, by: 1)
                {
                    guard let currData:HKQuantitySample = samples[i] as? HKQuantitySample else { return }
                    
                    let hearhRate: Double = (currData.quantity.doubleValue(for: self.heartRateVariabilityUnit))
                    let tempStringForHR:String = String(format:"%.1f", hearhRate)
                    
                    print(tempStringForHR)
                }
                DispatchQueue.main.async{
                   
                }
                
            } else {
                print("No heart rate samples available.")
            }
        }
        self.healthStore.execute(query)
    }
        
//
//    func testHKAnchorObjectQueue()  {
//        // Create the step count type.
//        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
//            // This should never fail when using a defined constant.
//            fatalError("*** Unable to get the step count type ***")
//        }
//
//
//
//        let endDate = Date()
//        let startDate = endDate.addingTimeInterval(-1.0 * 60.0 * 60.0)
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
//
//        // Create the query.
//        let query = HKAnchoredObjectQuery(type: heartRateType,
//                                          predicate: predicate,
//                                          anchor: self.myAnchor,
//                                          limit: HKObjectQueryNoLimit)
//        { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
//
//            guard let samples = samplesOrNil, let deletedObjects = deletedObjectsOrNil else {
//                // Handle the error here.
//                fatalError("*** An error occurred during the initial query: \(errorOrNil!.localizedDescription) ***")
//            }
//
//            self.myAnchor = newAnchor
//
//            for heartRateSample in samples {
//                // Process the new step count samples here.
//                print("HKAnchoredObjectQuery: \(heartRateSample.endDate)")
//
//                guard let currData:HKQuantitySample = heartRateSample as? HKQuantitySample else { return }
//
//                let hearhRate: Double = (currData.quantity.doubleValue(for: self.heartRateUnit))
//                let tempStringForHR:String = String(format:"%.1f", hearhRate)
//
//                print(tempStringForHR)
//
//
//            }
//
//            for deletedStepCountSamples in deletedObjects {
//                // Process the deleted step count samples here.
//            }
//        }
//
//        // Optionally, add an update handler.
//        query.updateHandler = { (query, samplesOrNil, deletedObjectsOrNil, newAnchor, errorOrNil) in
//
//            guard let samples = samplesOrNil, let deletedObjects = deletedObjectsOrNil else {
//                // Handle the error here.
//                fatalError("*** An error occurred during an update: \(errorOrNil!.localizedDescription) ***")
//            }
//
//            self.myAnchor = newAnchor
//
//            for heartRateSample in samples {
//                // Process the step counts from the update here.
//                guard let currData:HKQuantitySample = heartRateSample as? HKQuantitySample else { return }
//
//                let hearhRate: Double = (currData.quantity.doubleValue(for: self.heartRateUnit))
//                let tempStringForHR:String = String(format:"%.1f", hearhRate)
//
//                print(tempStringForHR)
//                print("HKAnchoredObjectQuery.updateHandler: \(heartRateSample.endDate)")
//
//            }
//
//            for deletedStepCountSamples in deletedObjects {
//                // Process the deleted step count samples from the update here.
//            }
//        }
//
//        // Run the query.
//        healthStore.execute(query)
//    }
//
//    func testObseverQueue() {
//        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
//            // This should never fail when using a defined constant.
//            fatalError("*** Unable to get the  type ***")
//        }
//
//        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) {
//            query, completionHandler, error in
//
//            if error != nil {
//
//                // Perform Proper Error Handling Here...
//                print("*** An error occured while setting up the  observer. \(error!.localizedDescription) ***")
//                abort()
//            }
//            print("new sample added")
//            // Take whatever steps are necessary to update your app's data and UI
//            // This may involve executing other queries
//            self.retrieveValues()
//
//            // If you have subscribed for background updates you must call the completion handler here.
//            // completionHandler()
//            completionHandler()
//        }
//
//        healthStore.execute(query)
//        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: HKUpdateFrequency.immediate){
//            success, error in
//            if error != nil {
//                // Perform Proper Error Handling Here...
//                print("*** An error occured while setting up the  observer. \(error!.localizedDescription) ***")
////                abort()
//            }
//
//            if success{
//                print("the background delivery was successfully enabled")
//            }
//        }
//    }
}

