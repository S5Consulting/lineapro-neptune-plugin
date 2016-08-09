#import "MainTabBarController.h"
#import "NSDataCrypto.h"

@implementation MainTabBarController

-(void)enableCharging {
    [dtdev setCharging:[[NSUserDefaults standardUserDefaults] boolForKey:@"AutoCharging"] error:nil];
}

-(void)addController:(id)viewController
{
    NSMutableArray *controllers=[self.viewControllers mutableCopy];
    for(int i=0;i<controllers.count;i++)
        if([controllers objectAtIndex:i]==viewController)
            return;
    [controllers addObject:viewController];
    self.viewControllers=controllers;
}

-(void)removeController:(id)viewController
{
    NSMutableArray *controllers=[self.viewControllers mutableCopy];
    for(int i=0;i<controllers.count;i++)
        if([controllers objectAtIndex:i]==viewController)
        {
            [controllers removeObjectAtIndex:i];
            self.viewControllers=controllers;
            return;
        }
}

-(void)deviceFeatureSupported:(int)feature value:(int)value
{
#if !TARGET_IPHONE_SIMULATOR
    if(feature==FEAT_RF_READER)
    {
        if(value==FEAT_SUPPORTED)
        {
            [self addController:rfViewController];
        }else
        {
            [self removeController:rfViewController];
        }
    }
    if(feature==FEAT_MSR)
    {
        if(value&MSR_ENCRYPTED || value&MSR_ENCRYPTED_EMUL || value&MSR_VOLTAGE)
            [self addController:emsrCryptoViewController];
        else
            [self removeController:emsrCryptoViewController];
        
        //show the old crypto interface only when there is no encrypted head present
        if(value&MSR_PLAIN_WITH_ENCRYPTION && !(value&MSR_ENCRYPTED))
        {
            [self addController:cryptoViewController];
        }
        else
        {
            [self removeController:cryptoViewController];
        }
    }
    if(feature==FEAT_PRINTING)
    {
        if(value&PRINT_PROTOCOL_ESCPOS)
        {
            [self addController:printViewController];
            
            DTDeviceInfo *prninfo=[dtdev getConnectedDeviceInfo:DEVICE_TYPE_PRINTER error:nil];
            NSString *connection=@"";
            if(prninfo.connectionType==CONNECTION_BLUETOOTH)
                connection=@"BT ";
            if(prninfo.connectionType==CONNECTION_TCPIP)
                connection=@"WIFI ";
//            [dtdev prnPrintText:[NSString stringWithFormat:@"{=C}{+B}%@PRINTER CONNECTED",connection] error:nil];
            //update main view
            [scannerViewController viewWillAppear:false];
        }else
        {
            if(value&PRINT_PROTOCOL_ZPL)
            {
                [self addController:printZPLViewController];
            }else
            {
                [self removeController:printViewController];
                [self removeController:printZPLViewController];
            }
        }
        if(value==FEAT_UNSUPPORTED)
        {
            //update main view
            [scannerViewController viewWillAppear:false];
        }
    }
    if(feature==FEAT_EMVL2_KERNEL)
    {
        if(value==FEAT_UNSUPPORTED)
        {
            [self removeController:emv2ViewController];
        }else
        {
            if(value&(EMV_KERNEL_DATECS|EMV_KERNEL_UNIVERSAL))
                [self addController:emv2ViewController];
        }
    }
    if(feature==FEAT_PIN_ENTRY)
    {
        if(value==FEAT_SUPPORTED)
        {
            [self addController:ppadViewController];
            //update main view
            [scannerViewController viewWillAppear:false];
        }else
        {
            [self removeController:ppadViewController];
            //update main view
            [scannerViewController viewWillAppear:false];
        }
    }
#endif
}

-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

-(void)initDevice
{
    NSError *error=nil;
    
    //setting various opticon barcode engine parameters
    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_OPTICON)
    {
//        [dtdev barcodeOpticonSetInitString:@"OG" error:&error];
        //                [dtdev barcodeOpticonSetInitString:@"6P" error:&error]; //transmit UPC-E as UPC-A
        //                [dtdev barcodeOpticonSetInitString:@"JXJYDR" error:&error];
        //                [dtdev barcodeOpticonSetInitString:@"VE" error:&error];
        //                [dtdev barcodeOpticonSetInitString:@"B6" error:&error];
        //                [dtdev barcodeOpticonSetInitString:@"OF" error:&error];
        //                [dtdev barcodeOpticonSetInitString:@"V4[D01[DM2[D00" error:&error];
        //                [dtdev barcodeOpticonSetInitString:@"[DM2[D00YQ[BCDE6" error:&error];
    }
    
    //setting various intermec barcode engine parameters
    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_INTERMEC)
    {
        const uint8_t intermecInit[]=
        {
            0x41, //start
            0x7B,0x46,7, //set the illumination to 7%, do not go over 40%
            0x4f,0x40,1, //enable gs1 databar omnidirection
            0x4f,0x41,1, //enable gs1 databar limited
            0x4f,0x42,1, //enable gs1 databar extended
            0x4c,0x42,1, //enable micro pdf417
            0x55,0x40,1, //enable qr code
            0x53,0x40,1, //enable aztec code
            0x4b,0x43,0, //disable ean-13
        };

        [dtdev barcodeIntermecSetInitData:[NSData dataWithBytes:intermecInit length:sizeof(intermecInit)] error:&error];
    }
    
    
    //setting various code barcode engine parameters
    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_CODE)
    {
        //                [dtdev barcodeCodeSetParam:0x39 value:3 error:&error]; //enable PDF-417
    }
    
    //setting various newland barcode engine parameters
    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_NEWLAND)
    {
        //                [dtdev barcodeNewlandSetInitString:@"NLS0400030=11;NLS0400040=25;" error:&error]; //set min code128 length to 15, max to 25
        //                [dtdev barcodeNewlandSetInitString:@"NLS0402040;NLS0402010;" error:&error];
        //                [dtdev barcodeNewlandSetInitString:@"NLS0402040;NLS0402010;" error:&error];
    }
    
    //setting various motorola barcode engine parameters
    if([dtdev getSupportedFeature:FEAT_BARCODE error:nil]==BARCODE_MOTOROLA)
    {
//        const uint8_t motorolaInit[]=
//        {
//            0xC6, 0x00, 0xFF, //start
//            0xF1,0xA8,0x01, //enable OCR-A
//            0x03,0x00, //enable ean-13
//        };
//        [dtdev barcodeMotorolaSetInitData:[NSData dataWithBytes:motorolaInit length:sizeof(motorolaInit)] error:&error];
    }
    
    //encrypted head, you can check supported algorithms and select the one you want
    if([dtdev getSupportedFeature:FEAT_MSR error:nil]&MSR_ENCRYPTED)
    {
        //set the active algorithm
        [emsrCryptoViewController updateEMSRAlgorithm:nil];
        //configure masked data
        [dtdev emsrConfigMaskedDataShowExpiration:TRUE showServiceCode:TRUE showTrack3:TRUE unmaskedDigitsAtStart:6 unmaskedDigitsAtEnd:2 unmaskedDigitsAfter:7 error:nil];
    }

    if([dtdev getSupportedFeature:FEAT_SMARTCARD error:nil]==FEAT_SUPPORTED)
    {
        [dtdev scInit:SLOT_MAIN error:nil];
    }
    /*
     //change the sound made by the engine when it reads barcode
     int beep2[]={2730,150,65000,20,2730,150};
     [dtdev barcodeSetScanBeep:true volume:100 beepData:beep2 length:sizeof(beep2) error:nil];
     */
    
    
    //            [dtdev voltageSetPublicParameters:nil version:0 error:nil];
    
    //            [self performSelector:@selector(setIntermec) withObject:nil afterDelay:2.0];
//    if(![dtdev setAutoOffWhenIdle:30 whenDisconnected:30 error:&error])
    
    
    //calling this function last, after all notifications has been called in all registered deleegates,
    //because enabling/disabling charge in firmware versions <2.34 will force disconnect and reconnect
    if([dtdev getSupportedFeature:FEAT_BATTERY_CHARGING error:nil]==FEAT_SUPPORTED)
    {
//        [self performSelectorOnMainThread:@selector(enableCharging) withObject:nil waitUntilDone:NO];
    }
//    [dtdev msSetCardDataMode:MS_PROCESSED_TRACK2_DATA error:nil];
    
    //if firmware is >= 5.45, cpu crypto functions are supported in any case, not only when magnetic card is present, so add the view
//    if(dtdev.firmwareRevisionNumber>=545)
//        [self addController:cryptoViewController];
}

-(void)connectionState:(int)state {
    //hack: if an ipod is inserted into linea tab device, then shrink the controller a bit so tab bar is actually useable
    if(state==CONN_CONNECTED && UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone && [dtdev.deviceName hasPrefix:@"LINEAPad"])
    {
        self.tabBar.frame = CGRectMake(tabRect.origin.x, mainRect.size.height-80, tabRect.size.width, 65);
    }else
    {
        self.tabBar.frame = tabRect;
    }
    
	switch (state) {
		case CONN_DISCONNECTED:
            break;
		case CONN_CONNECTING:
#if TARGET_IPHONE_SIMULATOR
			[self setViewControllers:[NSArray arrayWithObjects:scannerViewController,
                                      settingsViewController,
                                      rfViewController,
                                      emsrCryptoViewController,
                                      printViewController,
                                      nil] animated:TRUE];
#else
            NSLog(@"setViewControllers");
			[self setViewControllers:[NSArray arrayWithObjects:scannerViewController,settingsViewController,nil] animated:FALSE];
#endif
			break;
		case CONN_CONNECTED:
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self initDevice];
            });
            break;
	}
}

-(void)viewDidLoad
{
    mainRect=self.view.frame;
    tabRect=self.tabBar.frame;
    
	//init dtdev class and connect it
	dtdev=[DTDevices sharedDevice];
	[dtdev addDelegate:self];
	[dtdev connect];

    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)
        if(interfaceOrientation==UIInterfaceOrientationPortraitUpsideDown || interfaceOrientation==UIInterfaceOrientationPortrait)
            return YES;
    
    return NO;
}

@end
