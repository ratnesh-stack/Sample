//
//  ViewController.swift
//  watchDemo-iOS
//
//  Created by RatneshShukla on 19/11/22.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var detailLabel: UILabel!
    let watchManager = WatchManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func getData(_ sender: Any) {
        getSleep(date: "2022-11-29")
    }
    
    private func getPedometer(date: String) {
        watchManager.getPedometer(date: date) { data in
            self.detailLabel.text = data.debugDescription
        }
    }
    
    private func getSleep(date: String) {
        watchManager.getSleep(date: date) { data in
            self.detailLabel.text = data.debugDescription
        }
    }
    
    private func getHeartRate(date: String) {
        watchManager.getHeartRate(date: date) { data in
            self.detailLabel.text = data.debugDescription
        }
    }
    
    private func getBloodPressure(date: String) {
        watchManager.getBloodPressure(date: date) { data in
            self.detailLabel.text = data.debugDescription
        }
    }
}

