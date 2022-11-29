# Sample App

# ViewController.Swift
  This Class calls Watch Manager
  
      @IBAction func getData(_ sender: Any) {
        getSleep(date: "2022-11-29")
      }   

  
# WatchManager.Swift
  This class is divided into 3 Section

  a) Initilization
  
  b) Setup / Connection to device
  
  c) FetchData
  
    1.getSleep
    
    2.getPedoMeter
    
    3.getBloodPressure
    
    4.getHeartRate
