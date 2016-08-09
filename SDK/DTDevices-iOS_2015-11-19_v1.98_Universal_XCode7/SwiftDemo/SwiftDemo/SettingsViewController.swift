import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DTDeviceDelegate {

    @IBOutlet weak var tvSettings: UITableView!
    
    
    let lib=DTDevices.sharedDevice() as! DTDevices
    
    var tableObjects=[SettingsTemplate]()
    
    func connectionState(state: Int32) {
        var section = 0
        
        tableObjects=[]
        if state==CONN_STATES.CONNECTED.rawValue
        {
            //analyze the connected device features and build proper list
            tableObjects.append(SettingsGeneral(viewController: self, section: section++))
            
            if (lib.getSupportedFeature(FEATURES.FEAT_BLUETOOTH, error: nil) & FEAT_BLUETOOTH_TYPES.BLUETOOTH_CLIENT.rawValue) != 0
            {
                tableObjects.append(SettingsBT(viewController: self, section: section++))
            }
            if lib.getSupportedFeature(FEATURES.FEAT_BARCODE, error: nil) != FEAT_UNSUPPORTED
            {
                tableObjects.append(SettingsBarcode(viewController: self, section: section++))
                tableObjects.append(SettingsBarcodeMode(viewController: self, section: section++))
            }
        }else
        {
            //let only manual tcp/ip connect
            tableObjects.append(SettingsTCPIP(viewController: self, section: section++))
        }
        tvSettings.reloadData()
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableObjects[section].getSectionName()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableObjects.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableObjects[section].getNumberOfRows()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell=tvSettings.dequeueReusableCellWithIdentifier("TableCell", forIndexPath: indexPath) 
        
        tableObjects[indexPath.section].setCell(cell, row: indexPath.row)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell=tvSettings.cellForRowAtIndexPath(indexPath)
        tableObjects[indexPath.section].execute(cell!, row: indexPath.row)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        lib.addDelegate(self)
        //force to update
        connectionState(lib.connstate)
        tvSettings.delegate=self
        tvSettings.dataSource=self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

