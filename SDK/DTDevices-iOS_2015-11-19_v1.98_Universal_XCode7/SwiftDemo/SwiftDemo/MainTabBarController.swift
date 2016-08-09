import Foundation

class MainTabBarController: UITabBarController {
    
    @IBOutlet weak var printViewController: UIViewController?
    
    let lib=DTDevices.sharedDevice() as! DTDevices
    var cachedViewControllers = Dictionary<String, UIViewController>()
    
    func getViewController(name: String) -> UIViewController
    {
        var vc=cachedViewControllers[name]
        if vc == nil
        {
            vc = self.storyboard?.instantiateViewControllerWithIdentifier(name)
            cachedViewControllers[name]=vc
        }
        return vc!
    }
    
    func connectionState(state: Int32) {
        var tabs: [UIViewController] = []
       
        tabs.append(getViewController("Scan"))
        tabs.append(getViewController("Settings"))
        if state==CONN_STATES.CONNECTED.rawValue
        {
            if lib.getSupportedFeature(FEATURES.FEAT_PRINTING, error: nil) != FEAT_UNSUPPORTED {
                tabs.append(getViewController("Print"))
            }
            if lib.getSupportedFeature(FEATURES.FEAT_MSR, error: nil) != FEAT_UNSUPPORTED || lib.getSupportedFeature(FEATURES.FEAT_PIN_ENTRY, error: nil) != FEAT_UNSUPPORTED {
                tabs.append(getViewController("Crypto"))
            }
        }
        
        setViewControllers(tabs, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.viewControllers = [UIViewController]()
        lib.addDelegate(self)
        lib.connect()
    }
    
}