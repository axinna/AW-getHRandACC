//
//  ViewController.swift
//  MyTest
//
//  Created by 沈文 on 2018/11/20.
//  Copyright © 2018 沈文. All rights reserved.
//

import UIKit
import HealthKit
import WatchConnectivity

class ViewController:  UIViewController,WCSessionDelegate{

    

    


    var healthStore = HKHealthStore()
    let heartRateUnit:HKUnit = HKUnit(from: "count/min")
    var myAnchor: HKQueryAnchor? = nil
    
    let session : WCSession!
    // MARK: Init
    required init?(coder aDecoder: NSCoder) {
        self.session = WCSession.default
        super.init(coder: aDecoder)
    }
    
    @IBOutlet weak var loglabel: UILabel!
    
    @IBAction func testButton(_ sender: Any) {
        print()
        self.loglabel.text = "press button"
//        self.testHKAnchorObjectQueue()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("hahaha")
        self.loglabel.numberOfLines = 0
        
        // Do any additional setup after loading the view, typically from a nib.
        self.activateHealthKit()
        //WCSession
        if (WCSession.isSupported()) {
            session.delegate = self
            session.activate()
        }

    }
    
    // MARK: WCSessionDelegate
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
//        print(message.description)
        let nameString = message["heart rate"] as! Double
        DispatchQueue.main.async {
            self.loglabel.text = String(message["heart rate"] as! Double)+String(message["accX"] as! Double)+String(message["accY"] as! Double)+String(message["accZ"] as! Double)
        }
        
        }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else {
            self.loglabel.text = "WCSession is not activated."
            return
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
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

        }
    }
    
    
    
    
    
    
//    func retrieveValues()  {
//        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
//        let heartRateVariabilityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
//        let stepCountType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
//
//        let sortDesc = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
//        // Get all samples from the last 24 hours
//        let endDate = Date()
//        let startDate = endDate.addingTimeInterval(-1.0 * 60.0 * 5.0)
//        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
//
//        let query = HKSampleQuery(sampleType: heartRateVariabilityType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDesc])
//        {
//            (query, samplesOrNil, error) in
//            if let samples = samplesOrNil {
//                print("样本数据长度为：  \(samples.count)")
//                for i in stride(from: 0, to: samples.count, by: 1)
//                {
//                    guard let currData:HKQuantitySample = samples[i] as? HKQuantitySample else { return }
//
//                    let hearhRate: Double = (currData.quantity.doubleValue(for: self.heartRateVariabilityUnit))
//                    let tempStringForHR:String = String(format:"%.1f", hearhRate)
//
//                    print(tempStringForHR)
//                }
//                DispatchQueue.main.async{
//
//                }
//
//            } else {
//                print("No heart rate samples available.")
//            }
//        }
//        self.healthStore.execute(query)
//    }
    
}

