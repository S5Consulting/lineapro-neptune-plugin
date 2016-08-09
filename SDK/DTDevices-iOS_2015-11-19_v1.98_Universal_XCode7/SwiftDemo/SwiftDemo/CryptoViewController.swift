import UIKit

class CryptoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DTDeviceDelegate {
    
    @IBOutlet weak var tvCrypto: UITableView!

    
    let lib=DTDevices.sharedDevice() as! DTDevices
    

    var tableObjects=[CryptoTemplate]()
    
    func connectionState(state: Int32) {
        var section = 0
        
        tableObjects=[]
        if state==CONN_STATES.CONNECTED.rawValue
        {
            if (lib.getSupportedFeature(FEATURES.FEAT_MSR, error: nil) & FEAT_MSRS.MSR_ENCRYPTED.rawValue) != 0 {
                tableObjects.append(CryptoEMSR(viewController: self, section: section++, headType:EMSR_REAL))
                if (lib.getSupportedFeature(FEATURES.FEAT_MSR, error: nil) & FEAT_MSRS.MSR_ENCRYPTED_EMUL.rawValue) != 0 {
                    tableObjects.append(CryptoEMSR(viewController: self, section: section++, headType:EMSR_EMULATED))
                }
                tableObjects.append(CryptoAlgorithm(viewController: self, section: section++))
            }
        }
        tvCrypto.reloadData()
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
        let cell=tvCrypto.dequeueReusableCellWithIdentifier("TableCell", forIndexPath: indexPath)
        
        tableObjects[indexPath.section].setCell(cell, row: indexPath.row)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell=tvCrypto.cellForRowAtIndexPath(indexPath)
        tableObjects[indexPath.section].execute(cell!, row: indexPath.row)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        lib.addDelegate(self)
        //force to update
        connectionState(lib.connstate)
        tvCrypto.delegate=self
        tvCrypto.dataSource=self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

