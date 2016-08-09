import UIKit

class MainViewController: UIViewController, DTDeviceDelegate {
    
    @IBOutlet weak var tvInfo: UITextView?
    @IBOutlet weak var btScan: UIButton?
    @IBOutlet weak var btBattery: UIButton?
    
    let lib=DTDevices.sharedDevice() as! DTDevices
    
    var scanActive = false
    
//MARK: Controls
    
    @IBAction func onScanDown()
    {
        do
        {
            var scanMode = SCAN_MODES.MODE_SINGLE_SCAN
            try lib.barcodeGetScanMode(&scanMode)
            
            if scanMode==SCAN_MODES.MODE_MOTION_DETECT {
                scanActive = !scanActive
                if scanActive {
                    try lib.barcodeStartScan()
                }else {
                    try lib.barcodeStopScan()
                }
            }else
            {
                try lib.barcodeStartScan()
            }
        }catch let error as NSError {
            tvInfo?.text="Operation failed with: \(error.localizedDescription)"
        }
    }

    @IBAction func onScanUp()
    {
        do
        {
            try lib.barcodeStopScan()
        }catch let error as NSError {
            tvInfo?.text="Operation failed with: \(error.localizedDescription)"
        }
    }
    
    @IBAction func onBattery()
    {
        updateBattery()
    }
    
    func updateBattery()
    {
        do
        {
            let info = try lib.getBatteryInfo()
            
            let v = info.voltage.format(".1")
            btBattery?.setTitle("\(info.capacity)%,\(v)v(\(info.charging)))", forState: UIControlState.Normal)
            if info.capacity<10
            {
                btBattery?.setBackgroundImage(UIImage(named: "0.png"), forState: UIControlState.Normal)
            }else
            {
                if info.capacity<40
                {
                    btBattery?.setBackgroundImage(UIImage(named: "25.png"), forState: UIControlState.Normal)
                }else
                {
                    if info.capacity<60
                    {
                        btBattery?.setBackgroundImage(UIImage(named: "50.png"), forState: UIControlState.Normal)
                    }else
                    {
                        if info.capacity<10
                        {
                            btBattery?.setBackgroundImage(UIImage(named: "75.png"), forState: UIControlState.Normal)
                        }else
                        {
                            btBattery?.setBackgroundImage(UIImage(named: "100.png"), forState: UIControlState.Normal)
                        }
                    }
                }
            }

            var s = ""
            s+="Voltage: "+info.voltage.format(".3")+"v\n"
            s+="Capacity: \(info.capacity)%\n"
            s+="Maximum capacity: \(info.maximumCapacity)mA/h\n"
            if info.health>0
            {
                s+="Health: \(info.health)%\n"
            }
            s+="Charging: \(info.charging)\n"
            if info.extendedInfo != nil
            {
                s+="Extended info: \(info.extendedInfo)\n"
            }
            tvInfo?.text=s
        }catch let error as NSError {
            btBattery!.hidden=true
            tvInfo?.text="Operation failed with: \(error.localizedDescription)"
        }
    }
    
//MARK: DTDevices notifications
    
    //sent when supported device connects or disconnects. always wait for this message or check connstate before attempting communication. calling connect function does not mean that the device will be connected on the next line
    func connectionState(state: Int32) {
        var info="SDK: ver \(lib.sdkVersion/100).\(lib.sdkVersion%100) \(NSDateFormatter.localizedStringFromDate(lib.sdkBuildDate, dateStyle: NSDateFormatterStyle.MediumStyle, timeStyle: NSDateFormatterStyle.NoStyle))\n"
        
        do
        {
            
            if state==CONN_STATES.CONNECTED.rawValue
            {
                let connected = try lib.getConnectedDevicesInfo()
                for device in connected
                {
                    info+="\(device.name) \(device.model) connected\nFW Rev: \(device.firmwareRevision) HW Rev: \(device.hardwareRevision)\nSerial: \(device.serialNumberString)\n"
                }
                
                if lib.getSupportedFeature(FEATURES.FEAT_BARCODE, error: nil) != FEAT_UNSUPPORTED
                {
                    btScan?.hidden=false
                }
                
                updateBattery()
            }else {
                btScan?.hidden=true;
            }
        }catch {}
        tvInfo?.text=info
    }
    
    //plain magnetic card data
    func magneticCardData(track1: String!, track2: String!, track3: String!) {
        let card = lib.msExtractFinancialCard(track1, track2: track2)
        var status = ""
        if card != nil
        {
            if !card.cardholderName.isEmpty {
                status += "Name: \(card.cardholderName)\n"
            }
            status += "PAN: \(card.cardholderName.masked(4, end: 4))\n"
            status += "Expires: \(card.expirationMonth)/\(card.expirationYear)\n"
            if !card.serviceCode.isEmpty {
                status += "Service Code: \(card.serviceCode)\n"
            }
            if !card.discretionaryData.isEmpty {
                status += "Discretionary: \(card.discretionaryData)\n"
            }
        }
        
        if !track1.isEmpty {
            status += "Track1: \(track1)\n"
        }
        if !track2.isEmpty {
            status += "Track2: \(track2)\n"
        }
        if !track3.isEmpty {
            status += "Track3: \(track3)\n"
        }
        
        do {
            let sound: [Int32] = [2730,150,0,30,2730,150];
            try lib.playSound(100, beepData: sound, length: Int32(sound.count*4))
        } catch {
        }
    }
    
//MARK: ViewController stuff
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        lib.addDelegate(self)
        lib.connect()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

