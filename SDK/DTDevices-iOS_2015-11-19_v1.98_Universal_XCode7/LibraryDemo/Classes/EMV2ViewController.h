#import <Foundation/Foundation.h>
#import "DTDevices.h"
#import "ProgressViewController.h"

@interface EMV2ViewController : UIViewController
{
	IBOutlet UITextView *logView;
	IBOutlet ProgressViewController *progressViewController;
    IBOutlet UISegmentedControl *segKernelType;
    
	DTDevices *dtdev;
    int kernelType;
}

-(IBAction)onEMVTransaction:(id)sender;

@end
