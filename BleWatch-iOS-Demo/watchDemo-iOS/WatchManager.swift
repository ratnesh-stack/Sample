//
//  WatchManager.swift
//  Runner
//
//  Created by RatneshShukla on 06/10/2565 BE.
//

import Foundation
import VeepooBleSDK
import UIKit

class WatchManager {
    
    typealias Completion =  ([AnyHashable: Any]) -> Void

    init() {
        VPBleCentralManage.sharedBleManager().isLogEnable = true
        VPBleCentralManage.sharedBleManager().peripheralManage = VPPeripheralManage.shareVPPeripheralManager()
        startScan()
    }
}

//MARK: SETUP
extension WatchManager {
    
    //MARK: STEP_1
    func startScan() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            VPBleCentralManage.sharedBleManager().veepooSDKStartScanDeviceAndReceiveScanningDevice { (peripheral) in
                if let peripheral = peripheral {
                    self.addPeripheralToDeviceArray(peripheralModel: peripheral)
                    self.startConnection(peripheral: peripheral)
                } else {
                    print("Peripheral data is nil")
                }
            }
        }
    }

    //MARK: STEP_2
    func addPeripheralToDeviceArray(peripheralModel: VPPeripheralModel) {
        var deviceArray: Array<VPPeripheralModel> = [VPPeripheralModel]()

        var isExist = false
        for i in (0..<deviceArray.count) {
            let p = deviceArray[i]
            if p.deviceAddress == peripheralModel.deviceAddress {
                isExist = true
                break
            }
        }
        if isExist == false {
            deviceArray.append(peripheralModel)
            deviceArray = deviceArray.sorted(by: { (p1, p2) -> Bool in
                return p1.rssi.intValue > p2.rssi.intValue
            })
        }
    }
    
    //MARK: STEP_3
    func startConnection(peripheral: VPPeripheralModel) {
        VPBleCentralManage.sharedBleManager().veepooSDKConnectDevice(peripheral) { (connectState) in
            self.handleConnectEvent(connectState: connectState)
        }
    }
    
    //MARK: STEP_4
    func handleConnectEvent(connectState: DeviceConnectState) {
        switch connectState {
        case .BlePoweredOff://蓝牙没有打开
            print("\n\n BlePoweredOff")
        case .BleConnecting://蓝牙连接中
            print("\n\n BleConnecting")
        case .BleConnectSuccess://蓝牙连接成功
            print("\n\n BleConnectSuccess")
            VPBleCentralManage.sharedBleManager().veepooSDKStopScanDevice()
        case .BleConnectFailed://蓝牙连接失败
            print("\n\nBleConnectFailed")
        case .BleVerifyPasswordSuccess://验证密码成功,返回上一级
            print("\n\n BleVerifyPasswordSuccess")
            self.deviceVerifyPasswordSuccessful()
        case .BleVerifyPasswordFailure://验证密码失败
            print("\n\n BleVerifyPasswordFailure")
            
        default:
            print("unknown")
        }
    }

    func deviceVerifyPasswordSuccessful() {//设备验证密码成功
        
        if VPBleCentralManage.sharedBleManager().vpBleDFUConnectStateChangeBlock != nil {//正在固件升级，自己也可以加判断条件
            print("deviceVerifyPassword Failed")
            return
        }
    }
}

extension WatchManager {
    
    func getPedometer(date:String, completion: @escaping Completion) {
        if VPBleCentralManage.sharedBleManager().isConnected == false { completion(["Error": "Watch is not connected"]); return }
        VPDataBaseOperation.veepooSDKGetStepData(withDate: date, andTableID: VPBleCentralManage.sharedBleManager().peripheralModel.deviceAddress, changeUserStature: VPBleCentralManage.sharedBleManager().peripheralModel.deviceStature) { (stepDataBaseDict) in
            guard let stepDict:[String: String] = stepDataBaseDict as? [String : String] else {
                return
            }
            completion(["Steps": stepDict["Step"] ?? 0, "Distance": stepDict["Dis"] ?? 0])
        }
    }
    
//FIXME: SLEEP DATA NOT WORKING
    func getSleep(date:String, completion: @escaping Completion) {
        if VPBleCentralManage.sharedBleManager().isConnected == false { completion(["Error": "Watch is not connected"]); return }
        
        var sleepTestArray: Array<Any>?
        
        var sleepType = 0;
        
        //FIXME: Check 1
        VPBleCentralManage.sharedBleManager().peripheralManage.veepooSDK_readSleepData(withDayNumber: 1) { (sleepArray) in
            guard  let sleepArray = sleepArray  else {
                return
            }
            sleepTestArray = sleepArray
        }
        
        //FIXME: Check 2
        if VPBleCentralManage.sharedBleManager()?.peripheralModel.sleepType == 1 { sleepType = 1 }
        if sleepType == 1 {//精准睡眠
            sleepTestArray = VPDataBaseOperation.veepooSDKGetAccurateSleepData(withDate: date, andTableID: VPBleCentralManage.sharedBleManager().peripheralModel.deviceAddress)
        } else {
            sleepTestArray = VPDataBaseOperation.veepooSDKGetSleepData(withDate: date, andTableID: VPBleCentralManage.sharedBleManager().peripheralModel.deviceAddress)
        }
        
        //FIXME: Check 3
        VPPeripheralManage.shareVPPeripheralManager().veepooSDK_readSleepData(withDayNumber: 1) { (sleepArray) in
            guard  let sleepArray = sleepArray  else {
                return
            }
            sleepTestArray = sleepArray
        }
        
        //FIXME: Check 4
        sleepTestArray = VPDataBaseOperation.veepooSDKGetSleepData(withDate: date, andTableID: VPBleCentralManage.sharedBleManager().peripheralModel.deviceAddress)
        
        //FIXME: Check 5
        sleepTestArray = VPDataBaseOperation.veepooSDKGetAccurateSleepData(withDate: date, andTableID: VPBleCentralManage.sharedBleManager().peripheralModel.deviceAddress)
                
        print("sleepTestArray - \(sleepTestArray)")
        
        if sleepType == 1, let sleepModel = sleepTestArray?.first as? VPAccurateSleepModel  {
            completion(["SLEEP_TIME" : sleepModel.sleepTime,
                        "WAKE_TIME" : sleepModel.getUpTimes,
                        "DEEP_HOUR" : sleepModel.deepDuration,
                        "LIGHT_HOUR" : sleepModel.lightDuration,
                        "WakeUpTime" : sleepModel.wakeTime,
                        "SLE_LINE" : sleepModel.sleepLine
                       ])
        }
        else if let sleepModel = sleepTestArray?.first as? [String : String] {
            completion(["SLEEP_TIME" : "\(sleepModel["SLEEP_TIME"] ?? "")",
                        "WAKE_TIME" : "\(sleepModel["WAKE_TIME"] ?? "")",
                        "DEEP_HOUR" : "\(sleepModel["DEEP_HOUR"] ?? "")",
                        "LIGHT_HOUR" : "\(sleepModel["LIGHT_HOUR"] ?? "")",
                        "WakeUpTime" : "\(sleepModel["WakeUpTime"] ?? "")",
                        "SLE_LINE" : "\(sleepModel["SLE_LINE"] ?? "")"
                       ])
        }
        else {
            completion(["SLEEP" : "Failed to read Sleep Data, Please check if sleep data is available"])
        }
    }
    
    func getHeartRate(date:String, completion: @escaping Completion) {
        if VPBleCentralManage.sharedBleManager().isConnected == false { completion(["Error": "Watch is not connected"]); return }

        VPBleCentralManage.sharedBleManager().peripheralManage.veepooSDKTestHeartStart(true) { (testHeartState, heartValue) in
            switch testHeartState {
            case .testing: //正在检测心率，已经测出心率值
                completion(["HEART_RATE": heartValue])
            default:
                print(["HEART_RATE": "Checking"])
            }
        }
    }
    
    func getBloodPressure(date:String, completion: @escaping Completion) {
        if VPBleCentralManage.sharedBleManager().isConnected == false { completion(["Error": "Watch is not connected"]); return }
        
        let bloodDataBaseArray = VPDataBaseOperation.veepooSDKGetBloodData(withDate: date, andTableID: VPBleCentralManage.sharedBleManager().peripheralModel.deviceAddress)
        
        if let bloodDataArray = bloodDataBaseArray, let firstData = bloodDataArray.first as?[String: Any] , let systolic = firstData["systolic"], let diastolic = firstData["diastolic"] {
            completion(["Systolic_Pressure": systolic, "diastolicPressure": diastolic])
        }
        
        else {
            VPBleCentralManage.sharedBleManager().peripheralManage.veepooSDKTestBloodStart(true, testMode: 0) { (testBloodState, progress, systolic, diastolic) in
                if progress == 100 {
                    completion(["Systolic_Pressure": systolic, "diastolicPressure": diastolic])
                }
            }
        }
    }
}
