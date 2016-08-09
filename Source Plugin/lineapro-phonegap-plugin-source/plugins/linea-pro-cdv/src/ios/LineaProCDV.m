//
//  LineaProCDV.h
//
//  Created by Aaron Thorp on 27.04.16.
//  http://aaronthorp.com
//

#import "LineaProCDV.h"

@interface LineaProCDV()

+ (NSString*) getPDF417ValueByCode: (NSArray*) codesArr code:(NSString*)code;

@end

@implementation LineaProCDV

-(void) scannerConect:(NSString*)num {

    NSString *jsStatement = [NSString stringWithFormat:@"reportConnectionStatus('%@');", num];
    [self.webViewEngine evaluateJavaScript:jsStatement completionHandler:nil];
    //[self.webView stringByEvaluatingJavaScriptFromString:jsStatement];

}

-(void) scannerBattery:(NSString*)num {

    int percent;
    float voltage;

	if([dtdev getBatteryCapacity:&percent voltage:&voltage error:nil])
    {
        NSString *status = [NSString stringWithFormat:@"Bat: %.2fv, %d%%",voltage,percent];

        // send to web view
        NSString *jsStatement = [NSString stringWithFormat:@"reportBatteryStatus('%@');", status];
        [self.webViewEngine evaluateJavaScript:jsStatement completionHandler:nil];
        //[self.webView stringByEvaluatingJavaScriptFromString:jsStatement];

    }
}

-(void) scanPaymentCard:(NSString*)num {

    NSString *jsStatement = [NSString stringWithFormat:@"onSuccessScanPaymentCard('%@');", num];
    [self.webViewEngine evaluateJavaScript:jsStatement completionHandler:nil];
    //[self.webView stringByEvaluatingJavaScriptFromString:jsStatement];
	  //[self.viewController dismissViewControllerAnimated:YES completion:nil];

}

- (void)initDT:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    if (!dtdev) {
        dtdev = [DTDevices sharedDevice];
        [dtdev addDelegate:self];
        [dtdev connect];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getConnectionStatus:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:[dtdev connstate]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)startBarcode:(CDVInvokedUrlCommand *)command
{
    [dtdev barcodeStartScan:nil];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:[dtdev connstate]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setPassThroughSync:(CDVInvokedUrlCommand *)command
{
    NSError *error=nil;

    BOOL dtResult = [dtdev setPassThroughSync:true error:&error];
    NSLog(@"setPassThroughSync: %d", dtResult);

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:1];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)unsetPassThroughSync:(CDVInvokedUrlCommand *)command
{
    NSError *error=nil;

    if (![dtdev setPassThroughSync:false error:&error])
        NSLog(@"unsetPassThroughSync: %i %@", 0, error.description);
    else
        NSLog(@"unsetPassThroughSync: %i", 1);

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:0];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)discoverDevices:(CDVInvokedUrlCommand *)command
{
    NSError *error=nil;
    NSError *error2=nil;

    NSLog(@"btDiscoverDevices");

    NSArray* btDevices = [dtdev btDiscoverDevices:10 maxTime:8 codTypes:0 error:&error];


    if (error) {
        NSLog(@"discoverDevices Error: %@", error.description);
        NSString* retStr = [ NSString stringWithFormat:@"LineaProCDV.onBluetoothDiscoverComplete(%i, [], '%@');", false, error.description];
        [webView evaluateJavaScript:retStr completionHandler:nil];
        //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];
    } else {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:btDevices options:NSJSONWritingPrettyPrinted error:&error2];
        NSString *jsonString;
        if (!jsonData) {
          NSLog(@"Got an error: %@", error2);
          jsonString = @"[]";
        } else {
          jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }

        NSString* retStr = [ NSString stringWithFormat:@"LineaProCDV.onBluetoothDiscoverComplete(%i, %@, null);", true, jsonString];
        [self.webViewEngine evaluateJavaScript:retStr completionHandler:nil];
        //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];


    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:true];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)btConnect:(CDVInvokedUrlCommand *)command
{;
    NSError *error=nil;

    NSString* address = [command.arguments objectAtIndex:0];
    NSLog(@"btConnect: %@", address);
    BOOL status;

    [dtdev btConnectSupportedDevice:address pin:nil error:&error];

    if (error) {
        status = false;
        NSLog(@"btConnect Error: %@", error.description);

        NSString* retStr = [ NSString stringWithFormat:@"LineaProCDV.onBluetoothDeviceConnected(null, '%@');", error.description];
        [self.webViewEngine evaluateJavaScript:retStr completionHandler:nil];
        //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];
    } else {
        status = true;
        NSLog(@"btConnect Success!");
    }

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:status];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)btDisconnect:(CDVInvokedUrlCommand *)command
{;
    NSError *error=nil;

    NSString* address = [command.arguments objectAtIndex:0];
    NSLog(@"btDisconnect: %@", address);
    BOOL status;

    [dtdev btDisconnect:address error:&error];

    if (error) {
        status = false;
        NSLog(@"btDisconnect Error: %@", error.description);
    } else {
        status = true;
        NSLog(@"btDisconnect Success!");
    }

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:status];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)btGetDeviceName:(CDVInvokedUrlCommand *)command
{;
    NSError *error=nil;

    NSString* address = [command.arguments objectAtIndex:0];
    NSLog(@"btGetDeviceName: %@", address);
    BOOL status;

    NSString* name = [dtdev btGetDeviceName:address error:&error];

    if (error) {
        status = false;
        NSLog(@"btGetDeviceName Error: %@", error.description);
    } else {
        status = true;
        NSLog(@"btGetDeviceName Success! %@", name);

        NSString* retStr = [ NSString stringWithFormat:@"LineaProCDV.onBluetoothGetDeviceName('%@', '%@');", address, name];
        [self.webViewEngine evaluateJavaScript:retStr completionHandler:nil];
        //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];
    }

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:status];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)btWrite:(CDVInvokedUrlCommand *)command
{;
    NSError *error=nil;

    NSString* data = [command.arguments objectAtIndex:0];
    NSLog(@"btWrite: %@", data);
    BOOL status;

    [dtdev btWrite:data error:&error];

    if (error) {
        status = false;
        NSLog(@"btWrite Error: %@", error.description);
    } else {
        status = true;
        NSLog(@"btWrite Success!");
    }

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:status];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)prnPrintText:(CDVInvokedUrlCommand *)command
{;
    NSError *error=nil;

    NSString* data = [command.arguments objectAtIndex:0];
    NSLog(@"prnPrintText: %@", data);
    BOOL status;

    [dtdev prnPrintText:data error:&error];

    if (error) {
        status = false;
        NSLog(@"prnPrintText Error: %@", error.description);
    } else {
        status = true;
        NSLog(@"prnPrintText Success!");
    }

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:status];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)prnPrintZPL:(CDVInvokedUrlCommand *)command
{;
    NSError *error=nil;

    NSString* str = [command.arguments objectAtIndex:0];
    NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];

    NSLog(@"prnPrintZPL: %@", str);
    BOOL status;

    [dtdev prnWriteDataToChannel:50 data:data error:&error];

    if (error) {
        status = false;
        NSLog(@"prnPrintZPL Error: %@", error.description);
    } else {
        status = true;
        NSLog(@"prnPrintZPL Success!");
    }

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:status];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stopBarcode:(CDVInvokedUrlCommand *)command
{
    [dtdev barcodeStopScan:nil];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:[dtdev connstate]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)connectionState: (int)state {
    NSLog(@"connectionState: %d", state);

    switch (state) {
		case CONN_DISCONNECTED:
		case CONN_CONNECTING:
                break;
		case CONN_CONNECTED:
		{
			NSLog(@"PPad connected!\nSDK version: %d.%d\nHardware revision: %@\nFirmware revision: %@\nSerial number: %@", dtdev.sdkVersion/100,dtdev.sdkVersion%100,dtdev.hardwareRevision,dtdev.firmwareRevision,dtdev.serialNumber);
			break;
		}
	}

    NSString* retStr = [ NSString stringWithFormat:@"LineaProCDV.connectionChanged(%d);", state];
    [self.webViewEngine evaluateJavaScript:retStr completionHandler:nil];
    //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];
}

- (void) deviceButtonPressed: (int) which {
    NSLog(@"deviceButtonPressed: %d", which);
}

- (void) deviceButtonReleased: (int) which {
    NSLog(@"deviceButtonReleased: %d", which);
}

- (void) deviceFeatureSupported: (int) feature value:(int) value {
    NSLog(@"deviceFeatureSupported: feature - %d, value - %d", feature, value);
}

- (void) firmwareUpdateProgress: (int) phase percent:(int) percent {
    NSLog(@"firmwareUpdateProgress: phase - %d, percent - %d", phase, percent);
}

- (void) magneticCardData: (NSString *) track1 track2:(NSString *) track2 track3:(NSString *) track3 {
    NSLog(@"magneticCardData: track1 - %@, track2 - %@, track3 - %@", track1, track2, track3);
    NSDictionary *card = [dtdev msProcessFinancialCard:track1 track2:track2];
    if(card && [card objectForKey:@"accountNumber"]!=nil && [[card objectForKey:@"expirationYear"] intValue]!=0)
    {
        NSLog(@"magneticCardData (full info): accountNumber - %@, cardholderName - %@, expirationYear - %@, expirationMonth - %@, serviceCode - %@, discretionaryData - %@, firstName - %@, lastName - %@", [card objectForKey:@"accountNumber"], [card objectForKey:@"cardholderName"], [card objectForKey:@"expirationYear"], [card objectForKey:@"expirationMonth"], [card objectForKey:@"serviceCode"], [card objectForKey:@"discretionaryData"], [card objectForKey:@"firstName"], [card objectForKey:@"lastName"]);
    }
    NSString* retStr = [ NSString stringWithFormat:@"LineaProCDV.onMagneticCardData('%@', '%@', '%@');", track1, track2, track3];
    [self.webViewEngine evaluateJavaScript:retStr completionHandler:nil];
    //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];
}

- (void) magneticCardEncryptedData: (int) encryption tracks:(int) tracks data:(NSData *) data {
    NSLog(@"magneticCardEncryptedData: encryption - %d, tracks - %d, data - %@", encryption, tracks, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void) magneticCardEncryptedData: (int) encryption tracks:(int) tracks data:(NSData *) data track1masked:(NSString *) track1masked track2masked:(NSString *) track2masked track3:(NSString *) track3 {
    NSLog(@"magneticCardEncryptedData: encryption - %d, tracks - %d, track3 - %@, track1masked - %@, track2masked - %@, track3 - %@", encryption, tracks, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], track1masked, track2masked, track3);
}

- (void) magneticCardEncryptedRawData: (int) encryption data:(NSData *) data {
    NSLog(@"magneticCardEncryptedRawData: encryption - %d, data - %@", encryption, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void) magneticCardRawData: (NSData *) tracks {
    NSLog(@"magneticCardRawData: data - %@", [[NSString alloc] initWithData:tracks encoding:NSUTF8StringEncoding]);
}

- (void) magneticJISCardData: (NSString *) data {
    NSLog(@"magneticJISCardData: data - %@", data);
}

- (void) paperStatus: (BOOL) present {
    NSLog(@"paperStatus: present - %d", present);
}

- (void) PINEntryCompleteWithError: (NSError *) error {
    NSLog(@"PINEntryCompleteWithError: error - %@", [error localizedDescription]);
}

- (void) rfCardDetected: (int) cardIndex info:(DTRFCardInfo *) info {
    NSLog(@"rfCardDetected (debug): cardIndex - %d, info - %@", cardIndex, [info description]);
    NSLog(@"rfCardDetected (debug): cardIndex - %d, info - %@", cardIndex, [info debugDescription]);
}

- (void) rfCardRemoved: (int) cardIndex {
    NSLog(@"rfCardRemoved: cardIndex - %d", cardIndex);
}

- (void) sdkDebug: (NSString *) logText source:(int) source {
    NSLog(@"sdkDebug: logText - %@, source - %d", logText, source);
}

- (void) smartCardInserted: (SC_SLOTS) slot {
    NSLog(@"smartCardInserted: slot - %d", slot);
}

- (void) smartCardRemoved: (SC_SLOTS) slot {
    NSLog(@"smartCardRemoved: slot - %d", slot);
}

- (void) barcodeData: (NSString *) barcode type:(int) type {
    NSLog(@"barcodeData: barcode - %@, type - %@", barcode, [dtdev barcodeType2Text:type]);
    NSString* retStr = [ NSString stringWithFormat:@"LineaProCDV.onBarcodeData('%@', '%@');", barcode, [dtdev barcodeType2Text:type]];
    [self.webViewEngine evaluateJavaScript:retStr completionHandler:nil];
    //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];
}

- (void) barcodeNSData: (NSData *) barcode isotype:(NSString *) isotype {
    NSLog(@"barcodeNSData: barcode - %@, type - %@", [[NSString alloc] initWithData:barcode encoding:NSUTF8StringEncoding], isotype);
    NSString* retStr = [ NSString stringWithFormat:@"LineaProCDV.onBarcodeData('%@', '%@');", [[NSString alloc] initWithData:barcode encoding:NSUTF8StringEncoding], isotype];
    [self.webViewEngine evaluateJavaScript:retStr completionHandler:nil];
    //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];
}

+ (NSString*) getPDF417ValueByCode: (NSArray*) codesArr code:(NSString*)code {
    for (NSString* currStr in codesArr) {
        // do something with object
        NSRange range = [currStr rangeOfString:code];
        if (range.length == 0) continue;
        NSString *substring = [[currStr substringFromIndex:NSMaxRange(range)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        return substring;
    }
    return NULL;
}

+ (NSString*) generateStringForArrayEvaluationInJS: (NSArray*) stringsArray {
    NSString* arrayJSString = [NSString stringWithFormat:@"["];
    BOOL isFirst = TRUE;
    for (int i = 0; i < stringsArray.count; ++i) {
        NSString* currString = [stringsArray objectAtIndex:i];
        if (currString.length <= 1) continue;
        arrayJSString = [NSString stringWithFormat:@"%@%@\"%@\"", arrayJSString, isFirst ? @"" : @",", currString];
        isFirst = FALSE;
    }
    arrayJSString = [NSString stringWithFormat:@"%@]", arrayJSString];
    return arrayJSString;
}

- (void) barcodeNSData: (NSData *) barcode type:(int) type {
    NSLog(@"barcodeNSData: barcode - %@, type - %@", [[NSString alloc] initWithData:barcode encoding:NSUTF8StringEncoding], [dtdev barcodeType2Text:type]);
    NSArray *codesArr = [[[NSString alloc] initWithData:barcode encoding:NSUTF8StringEncoding] componentsSeparatedByCharactersInSet:
                        [NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];
    NSString* substrDateBirth = @"DBB";
    NSString* dateBirth = [LineaProCDV getPDF417ValueByCode:codesArr code: substrDateBirth];
    NSString* substrName = @"DAC";
    NSString* name = [LineaProCDV getPDF417ValueByCode:codesArr code: substrName];
    NSString* substrLastName = @"DCS";
    NSString* lastName = [LineaProCDV getPDF417ValueByCode:codesArr code: substrLastName];
    NSString* substrEye = @"DAY";
    NSString* eye = [LineaProCDV getPDF417ValueByCode:codesArr code: substrEye];
    NSString* substrState = @"DAJ";
    NSString* state = [LineaProCDV getPDF417ValueByCode:codesArr code: substrState];
    NSString* substrCity = @"DAI";
    NSString* city = [LineaProCDV getPDF417ValueByCode:codesArr code: substrCity];
    NSString* substrHeight = @"DAU";
    NSString* height = [LineaProCDV getPDF417ValueByCode:codesArr code: substrHeight];
    NSString* substrWeight = @"DAW";
    NSString* weight = [LineaProCDV getPDF417ValueByCode:codesArr code: substrWeight];
    NSString* substrGender = @"DBC";
    NSString* gender = [LineaProCDV getPDF417ValueByCode:codesArr code: substrGender];
    NSString* substrHair = @"DAZ";
    NSString* hair = [LineaProCDV getPDF417ValueByCode:codesArr code: substrHair];
    NSString* substrExpires = @"DBA";
    NSString* expires = [LineaProCDV getPDF417ValueByCode:codesArr code: substrExpires];
    NSString* substrLicense = @"DAQ";
    NSString* license = [LineaProCDV getPDF417ValueByCode:codesArr code: substrLicense];
    NSLog(@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@", dateBirth, name, lastName, eye, state, city, height, weight, gender, hair, expires, license);

    NSString* rawCodesArrJSString = [LineaProCDV generateStringForArrayEvaluationInJS:codesArr];
    //LineaProCDV.onBarcodeData(scanId, dob, state, city, expires, gender, height, weight, hair, eye)
    NSString* retStr = [ NSString stringWithFormat:@"var rawCodesArr = %@; LineaProCDV.onBarcodeData(rawCodesArr, '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@');", rawCodesArrJSString, license, dateBirth, state, city, expires, gender, height, weight, hair, eye, name, lastName];
    [self.webViewEngine evaluateJavaScript:retStr completionHandler:nil];
    //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];
}

- (void) bluetoothDeviceConnected: (NSString *) address {
    NSLog(@"bluetoothDeviceConnected: address - %@", address);
    NSString* retStr = [ NSString stringWithFormat:@"LineaProCDV.onBluetoothDeviceConnected('%@');", address];
    [self.webViewEngine evaluateJavaScript:retStr completionHandler:nil];
    //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];
}

- (void) bluetoothDeviceDisconnected: (NSString *) address {
    NSLog(@"bluetoothDeviceDisconnected: address - %@", address);
    NSString* retStr = [ NSString stringWithFormat:@"LineaProCDV.onBluetoothDeviceDisconnected('%@');", address];
    [self.webViewEngine evaluateJavaScript:retStr completionHandler:nil];
    //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];
}

- (void) bluetoothDeviceDiscovered: (NSString *) address name:(NSString *) name {
    NSLog(@"bluetoothDeviceDiscovered: address - %@, name - @name", name);
    NSString* retStr = [ NSString stringWithFormat:@"LineaProCDV.onBluetoothDeviceDiscovered('%@', '%@');", address, name];
    [self.webViewEngine evaluateJavaScript:retStr completionHandler:nil];
    //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];
}
- (NSString *) bluetoothDevicePINCodeRequired: (NSString *) address name:(NSString *) name {
    NSLog(@"bluetoothDevicePINCodeRequired: address - %@, name - @name", name);
    return address;
}

- (BOOL) bluetoothDeviceRequestedConnection: (NSString *) address name:(NSString *) name {
    NSLog(@"bluetoothDeviceRequestedConnection: address - %@, name - @name", name);
    return TRUE;
}

- (void) bluetoothDiscoverComplete: (BOOL) success {
    NSLog(@"bluetoothDiscoverComplete: success - %d", success);
    NSString* retStr = [ NSString stringWithFormat:@"LineaProCDV.onBluetoothDiscoverComplete('%i');", success];
    [self.webViewEngine evaluateJavaScript:retStr completionHandler:nil];
    //[[super webView] stringByEvaluatingJavaScriptFromString:retStr];
}

@end
