//For America: selecting it makes for a much simplified EMV transaction, lot of stuff becomes optional
//and the data is sent as a normal encrypted magnetic card
#define KERNEL_AMERICA_CARD_EMULATION 0
//For America: selecting it creates normal EMV transaction, card tracks are available upon request
#define KERNEL_AMERICA 1
//For Europe: selecting it creates normal EMV transaction, card tracks are not available and the card data must be taken using encrypted tags
#define KERNEL_EUROPE 2

static int nRFCards=0;
static int nRFCardSuccess=0;


#import <CommonCrypto/CommonDigest.h>
#import "EMV2ViewController.h"
#import "EMVTags.h"
#import "EMVPrivateTags.h"
#import "EMVProcessorHelper.h"
#import "EMVTLV.h"
#import "dukpt.h"
#import "XMLParser.h"

@implementation EMV2ViewController

static NSData *stringToData(NSString *text)
{
    NSMutableData *d=[NSMutableData data];
    text=[text lowercaseString];
    int count=0;
    uint8_t b=0;
    for(int i=0;i<text.length;i++)
    {
        b<<=4;
        char c=[text characterAtIndex:i];
        if(c<'0' || (c>'9' && c<'a') || c>'f')
        {
            b=0;
            count=0;
            continue;
        }
        if(c>='0' && c<='9')
            b|=c-'0';
        else
            b|=c-'a'+10;
        count++;
        if(count==2)
        {
            [d appendBytes:&b length:1];
            b=0;
            count=0;
        }
    }
    return d;
}

-(void)displayAlert:(NSString *)title message:(NSString *)message
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
	[alert show];
}

#define RF_COMMAND(operation,c) {if(!c){[self displayAlert:@"Operatin failed!" message:[NSString stringWithFormat:@"%@ failed, error %@, code: %d",operation,error.localizedDescription,(int)error.code]]; return;} }

-(IBAction)clear:(id)sender
{
    [logView setText:@""];
}

-(void)updateDisplay
{
    if([dtdev getSupportedFeature:FEAT_PIN_ENTRY error:nil])
    {
        if(![dtdev uiStopAnimation:ANIM_ALL error:nil])
            return;
        if(![dtdev uiFillRectangle:0 topLeftY:0 width:0 height:0 color:[UIColor blackColor] error:nil])
            return;
        
        if(dtdev.uiDisplayHeight<64)
        {
            [dtdev uiDrawText:@"Use Smart, Magnetic\nor NFC card" topLeftX:0 topLeftY:0 font:FONT_6X8 error:nil];
        }else
        {
            [dtdev uiDrawText:@"\x01Use Smart,\nMagnetic or\nNFC card" topLeftX:25 topLeftY:3 font:FONT_6X8 error:nil];
            //magnetic card
            [dtdev uiStartAnimation:5 topLeftX:99 topLeftY:0 animated:TRUE error:nil];
            //smartcard
            [dtdev uiStartAnimation:4 topLeftX:0 topLeftY:0 animated:TRUE error:nil];
            [dtdev uiDisplayImage:38 topLeftY:30 image:[UIImage imageNamed:@"paypass_logo.bmp"] error:nil];
        }
    }
}

-(void)emv2OnTransactionFinished:(NSData *)data;
{
    [progressViewController.view removeFromSuperview];
    
    NSLog(@"emv2OnTransactionFinished: %@",data);
    
    //try to get some encrypted tags and decrypt them
    [self encryptedTagsDemo];
    
    [self performSelector:@selector(updateDisplay) withObject:nil afterDelay:1.5];
    if(!data)
    {
        [dtdev emv2Deinitialise:nil];
        [self displayAlert:@"Error" message:@"Transaction could not be completed!"];
        return;
    }
    
    if(kernelType==KERNEL_AMERICA_CARD_EMULATION)
    {
        //emv2OnTransactionFinished is used as a success/failure flag only in emulation mode
        //tags are present if you want to poke with them too, but the data has already
        //been sent as magnetic card encrypted data
    }else
    {
        //emv2OnTransactionFinished is used to get the final response from the transaction in non-emulation mode
        //data is extracted from the returned tags or manually asked for before calling emv2Deinitialise
        
        //parse data to display, send the rest to server
        
        //find and get Track1 masked and Track2 masked tags for display purposes
        NSString *t1Masked=nil;
        NSString *t2Masked=nil;
        
        NSArray *tags=[TLV decodeTags:data];
        logView.text=[NSString stringWithFormat:@"Final tags:\n%@",tags];
        
        TLV *t;
        
        NSMutableString *receipt=[NSMutableString string];
        NSLog(@"Tags: %@",tags);
        
        [receipt appendFormat:@"* Infinite Peripherals *\n"];
        [receipt appendFormat:@"\n"];
        
        
        [receipt appendFormat:@"Terminal ID: %@\n",[EMVProcessorHelper decodeNib:[TLV findLastTag:TAG_9F1C_TERMINAL_ID tags:tags].data]];
        [receipt appendFormat:@"\n"];
        
        [receipt appendFormat:@"Date: %@ %@\n",
         [EMVProcessorHelper decodeDateString:[TLV findLastTag:TAG_9A_TRANSACTION_DATE tags:tags].data],
         [EMVProcessorHelper decodeTimeString:[TLV findLastTag:TAG_9F21_TRANSACTION_TIME tags:tags].data]
         ];
        //    [receipt appendFormat:@"Transaction Sequence: %d\n",[EMVProcessorHelper decodeInt:[TLV findLastTag:TAG_9F41_TRANSACTION_SEQ_COUNTER tags:tags].data]];
        //    [receipt appendFormat:@"\n"];
        //
        //    if([cardInfo valueForKey:@"cardholderName"])
        //        [receipt appendFormat:@"Name: %@\n",[cardInfo valueForKey:@"cardholderName"]];
        //    if([cardInfo valueForKey:@"accountNumber"])
        //        [receipt appendFormat:@"PAN: %@\n",[cardInfo valueForKey:@"accountNumber"]];
        //    if([TLV findLastTag:TAG_5F34_PAN_SEQUENCE_NUMBER tags:tags])
        //    {
        //        [receipt appendFormat:@"PAN-SEQ: %@\n",[EMVProcessorHelper decodeNib:[TLV findLastTag:TAG_5F34_PAN_SEQUENCE_NUMBER tags:tags].data]];
        //    }
        //    [receipt appendFormat:@"AID: %@\n",[EMVProcessorHelper decodeHexString:[TLV findLastTag:TAG_84_DF_NAME tags:tags].data]];
        //    [receipt appendFormat:@"\n"];
        
        [receipt appendFormat:@"* Payment *\n"];
        
        
        int transactionResult=[EMVProcessorHelper decodeInt:[TLV findLastTag:TAG_C1_TRANSACTION_RESULT tags:tags].data];
        
        nRFCards++;
        NSString *transactionResultString=nil;
        switch (transactionResult)
        {
            case EMV_RESULT_APPROVED:
                transactionResultString=@"APPROVED";
                nRFCardSuccess++;
                break;
            case EMV_RESULT_DECLINED:
                nRFCardSuccess++;
                transactionResultString=@"DECLINED";
                break;
            case EMV_RESULT_TRY_ANOTHER_INTERFACE:
                transactionResultString=@"TRY ANOTHER INTERFACE";
                break;
            case EMV_RESULT_TRY_AGAIN:
                transactionResultString=@"TRY AGAIN";
                break;
            case EMV_RESULT_END_APPLICATION:
                transactionResultString=@"END APPLICATION";
                break;
        }
        [receipt appendFormat:@"Transaction Result:\n"];
        [receipt appendFormat:@"%@\n",transactionResultString];
        [receipt appendFormat:@"\n"];
        
        t=[TLV findLastTag:TAG_C3_TRANSACTION_INTERFACE tags:tags];
        if(t)
        {
            const uint8_t *bytes=t.data.bytes;
            switch (bytes[0]) {
                case EMV_INTERFACE_CONTACT:
                    [receipt appendString:@"Interface: contact\n"];
                    break;
                case EMV_INTERFACE_CONTACTLESS:
                    [receipt appendString:@"Interface: contactless\n"];
                    break;
                case EMV_INTERFACE_MAGNETIC:
                    [receipt appendString:@"Interface: magnetic\n"];
                    break;
                case EMV_INTERFACE_MAGNETIC_MANUAL:
                    [receipt appendString:@"Interface: manual entry\n"];
                    break;
            }
        }
        
        NSData *trackData=[dtdev emv2GetCardTracksEncryptedWithFormat:ALG_EH_AES256 keyID:KEY_EH_AES256_ENCRYPTION1 error:nil];
        if(trackData)
            [receipt appendFormat:@"Encrypted track data: %@\n",trackData];
        
        if(transactionResult==EMV_RESULT_APPROVED)
        {
            t=[TLV findLastTag:TAG_D3_TRACK1_MASKED tags:tags];
            if(t)
                t1Masked=[[NSString alloc] initWithData:t.data encoding:NSASCIIStringEncoding];
            t=[TLV findLastTag:TAG_D4_TRACK2_MASKED tags:tags];
            if(t)
                t2Masked=[[NSString alloc] initWithData:t.data encoding:NSASCIIStringEncoding];
            
            NSDictionary *card=[dtdev msProcessFinancialCard:t1Masked track2:t2Masked];
            if(card)
            {
                if([card valueForKey:@"cardholderName"])
                    [receipt appendFormat:@"Name: %@\n",[card valueForKey:@"cardholderName"]];
                if([card valueForKey:@"accountNumber"])
                    [receipt appendFormat:@"Number: %@\n",[card valueForKey:@"accountNumber"]];
                
                if([card valueForKey:@"expirationMonth"])
                    [receipt appendFormat:@"Expiration: %@/%@\n",[card valueForKey:@"expirationMonth"],[card valueForKey:@"expirationYear"]];
                [receipt appendString:@"\n"];
            }
            
            //try to get some encrypted tags and decrypt them
            [self encryptedTagsDemo];
        }
        
        //    [receipt appendFormat:@"TVR: %@\n",[EMVProcessorHelper decodeHexString:[TLV findLastTag:TAG_95_TVR tags:tags].data]];
        //    [receipt appendFormat:@"TSI: %@\n",[EMVProcessorHelper decodeHexString:[TLV findLastTag:TAG_9B_TSI tags:tags].data]];
        //    [receipt appendFormat:@"\n"];
        //
        //    NSString *issuerScriptResults=[EMVProcessorHelper decodeHexString:[TLV findLastTag:TAG_C8_ISSUER_SCRIPT_RESULTS tags:tags].data];
        //    if(issuerScriptResults)
        //        [receipt appendFormat:@"%@\n",issuerScriptResults];
        
        [dtdev emv2Deinitialise:nil];
        
        [receipt insertString:[NSString stringWithFormat:@"nEMVCards: %d, success: %d, failed: %d\n",nRFCards,nRFCardSuccess,nRFCards-nRFCardSuccess] atIndex:0];
        
        
        [self displayAlert:@"Transaction complete!" message:receipt];
    }
}
-(void)emv2OnApplicationSelection:(NSArray *)applications;
{
    //used on non-card emulation kernel if you want to present application list, on emulation this is never called
    if(kernelType!=KERNEL_AMERICA_CARD_EMULATION)
    {
    }
}
-(void)emv2OnOnlineProcessing:(NSData *)data;
{
    [self encryptedTagsDemo];
//    if(kernelType!=KERNEL_AMERICA_CARD_EMULATION)
    {
        //called when the kernel wants an approval online from the server, encapsulate the server response tags
        //in tag 0xE6 and set the server communication success or fail in tag C2
        
        //for the demo fake a successful server response (30 30)
        NSData *serverResponse=[TLV encodeTags:@[[TLV tlvWithHexString:@"30 30" tag:TAG_8A_AUTH_RESP_CODE]]];
        NSData *response=[TLV encodeTags:@[[TLV tlvWithHexString:@"01" tag:0xC2],[TLV tlvWithData:serverResponse tag:0xE6]]];
        [dtdev emv2SetOnlineResult:response error:nil];
    }
}

-(void)encryptedTagsDemo
{
    NSError *error;
    
    uint8_t tagList[]={
    0x56, //track1
    0x57, //track2
    0x5A, //pan
    0x5F, //expiry
    0x24, //expiry
    0x5F, //name
    0x20, //name
    };
    
    //get the tags encrypted with 3DES CBC and key loaded at positon 2
    NSData *packetData=[dtdev emv2GetTagsEncrypted:[NSData dataWithBytes:tagList length:sizeof(tagList)] format:TAGS_FORMAT_DATECS keyType:KEY_TYPE_3DES_CBC keyIndex:2 packetID:0x12345678 error:&error];
    if(!packetData)
        return; //no data
    const uint8_t *packet=packetData.bytes;
    
    int index=2;
    int format = (packet[index + 0] << 24) | (packet[index + 1] << 16) | (packet[index + 2] << 8) | (packet[index + 3]);
    if(format!=TAGS_FORMAT_DATECS)
        return; //wrong format
    index += 4;
    
    //try to decrypt the packet
    NSData *encrypted=[NSData dataWithBytes:&packet[index] length:packetData.length-index];
    
    uint8_t tridesKey[16]={0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31};
    
    uint8_t decrypted[1024];
    trides_crypto(kCCDecrypt,0,encrypted.bytes,encrypted.length,decrypted,tridesKey);

    
    //parse and verify the data
    index = 0;
    
    format = (decrypted[index + 0] << 24) | (decrypted[index + 1] << 16) | (decrypted[index + 2] << 8) | (decrypted[index + 3]);
    index += 4;
    
    int dataLen = (decrypted[index + 0] << 8) | (decrypted[index + 1]) - 4 - 4 - 16;
    if(dataLen<0 || dataLen>encrypted.length)
        return; //invalid length
    index += 2;
    int hashStart = index;
    
    int packetID = (decrypted[index + 0] << 24) | (decrypted[index + 1] << 16) | (decrypted[index + 2] << 8) | (decrypted[index + 3]);
    index += 4;
    
    index += 4;
    
    NSData *sn=[NSData dataWithBytes:&decrypted[index] length:16];
    index += sn.length;
    
    NSData *tags=[NSData dataWithBytes:&decrypted[index] length:dataLen];
    index += tags.length;
    int hashEnd = index;
  
    NSData *hashPacket=[NSData dataWithBytes:&decrypted[index] length:32];
    index += hashPacket.length;
    
    uint8_t hash[32];
    CC_SHA256(&decrypted[hashStart],hashEnd-hashStart,hash);
    index+=CC_SHA256_DIGEST_LENGTH;
    
    NSData *hashComputed=[NSData dataWithBytes:hash length:sizeof(hash)];
    
    if(![hashPacket isEqualToData:hashComputed])
        return; //invalid packet checksum
    
    //everything is valid, parse the tags now
    NSArray *t=[TLV decodeTags:tags];
    NSLog(@"Tags: %@",t);
}

-(void)emv2OnUserInterfaceCode:(int)code status:(int)status holdTime:(NSTimeInterval)holdTime;
{
    NSString *ui=@"";
    NSString *uistatus=@"not provided";
    switch (code)
    {
        case EMV_UI_NOT_WORKING:
            ui = @"Not working";
            break;
        case EMV_UI_APPROVED:
            ui = @"Approved";
            break;
        case EMV_UI_DECLINED:
            ui = @"Declined";
            break;
        case EMV_UI_PLEASE_ENTER_PIN:
            ui = @"Please enter PIN";
            break;
        case EMV_UI_ERROR_PROCESSING:
            ui = @"Error processing";
            break;
        case EMV_UI_REMOVE_CARD:
            ui = @"Please remove card";
            break;
        case EMV_UI_IDLE:
            ui = @"Idle";
            break;
        case EMV_UI_PRESENT_CARD:
            ui = @"Please present card";
            break;
        case EMV_UI_PROCESSING:
            ui = @"Processing...";
            break;
        case EMV_UI_CARD_READ_OK_REMOVE:
            ui = @"It is okay to remove card";
            break;
        case EMV_UI_TRY_OTHER_INTERFACE:
            ui = @"Try another interface";
            break;
        case EMV_UI_CARD_COLLISION:
            ui = @"Card collision";
            break;
        case EMV_UI_SIGN_APPROVED:
            ui = @"Signature approved";
            break;
        case EMV_UI_ONLINE_AUTHORISATION:
            ui = @"Online authorization";
            break;
        case EMV_UI_TRY_OTHER_CARD:
            ui = @"Try another card";
            break;
        case EMV_UI_INSERT_CARD:
            ui = @"Please insert card";
            break;
        case EMV_UI_CLEAR_DISPLAY:
            ui = @"Clear display";
            break;
        case EMV_UI_SEE_PHONE:
            ui = @"See phone";
            break;
        case EMV_UI_PRESENT_CARD_AGAIN:
            ui = @"Please present card again";
            break;
        case EMV_UI_SELECT_APPLICAITON:
            ui = @"Select application on device";
            break;
        case EMV_UI_MANUAL_ENTRY:
            ui = @"Enter card on device";
            break;
        case EMV_UI_NA:
            ui = @"N/A";
            break;
    }
    switch (status)
    {
        case EMV_UI_STATUS_NOT_READY:
            uistatus = @"Status Not Ready";
            break;
        case EMV_UI_STATUS_IDLE:
            uistatus = @"Status Idle";
            break;
        case EMV_UI_STATUS_READY_TO_READ:
            uistatus = @"Status Ready To Read";
            break;
        case EMV_UI_STATUS_PROCESSING:
            uistatus = @"Status Processing";
            break;
        case EMV_UI_STATUS_CARD_READ_SUCCESS:
            uistatus = @"Status Card Read Success";
            break;
        case EMV_UI_STATUS_ERROR_PROCESSING:
            uistatus = @"Status Processing";
            break;
    }
    [progressViewController updateText:ui];
}

-(NSData *)parseXMLTag:(NSDictionary *)config
{
    id subtags=[config objectForKey:@"TAG"];
    NSString *tag=[config objectForKey:@"Tag"];
    NSString *tagdata=[config objectForKey:@"Value"];
    
    NSMutableData *data=[NSMutableData data];
    if(subtags!=nil)
    {
        if([subtags isKindOfClass:[NSArray class]])
        {
            for(NSDictionary *subtag in subtags)
            {
                NSData *tagValue=[self parseXMLTag:subtag];
                [data appendData:tagValue];
            }
        }else
        {
            NSData *tagValue=[self parseXMLTag:subtags];
            [data appendData:tagValue];
        }
    }else
    {
        [data appendData:stringToData(tagdata)];
    }
    TLV *tlv=[TLV tlvWithData:data tag:(int)strtoull(tag.UTF8String, NULL, 16)];
    return [TLV encodeTags:@[tlv]];
}

-(NSData *)parseXMLConfiguration:(NSDictionary *)config
{
    NSMutableData *data=[NSMutableData data];
    NSDictionary *root=[config objectForKey:@"TLVConfiguration"];
    
    for(NSDictionary *tags in [root objectForKey:@"TAG"])
    {
        NSData *tag=[self parseXMLTag:tags];
        [data appendData:tag];
    }
    return data;
}

int getConfigurationVesrsion(NSData *configuration)
{
    NSArray *arr=[TLV decodeTags:configuration];
    if(!arr)
        return 0;
    for (TLV *tag in arr)
    {
        if(tag.tag==0xE4)
        {
            TLV *cfgtag=[TLV findLastTag:0xC1 tags:[TLV decodeTags:tag.data]];
            
            const uint8_t *data=cfgtag.data.bytes;
            int ver=(data[0]<<24)|(data[1]<<16)|(data[2]<<8)|(data[3]<<0);
            return ver;
        }
    }
    return 0;
}

-(IBAction)onEMVTransaction:(id)sender
{
    //load the configuration out of xml file directly
//    NSString *xml=[NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"xmlTest.xml"] encoding:NSASCIIStringEncoding error:nil];
//    NSDictionary *config=[XMLParser dictionaryForXMLString:xml error:nil];
//    NSData *cfg=[self parseXMLConfiguration:config];
    
    kernelType=(int)segKernelType.selectedSegmentIndex;
    
    NSError *error=nil;
    
    RF_COMMAND(@"EMV Initialize",[dtdev emv2Initialise:&error]);
    
    if(kernelType==KERNEL_AMERICA_CARD_EMULATION)
    {
//        RF_COMMAND(@"EMV Set card emulation",[dtdev emv2SetCardEmulationMode:true encryption:ALG_EH_AES256 keyID:KEY_EH_AES256_ENCRYPTION1 error:&error]);
        RF_COMMAND(@"EMV Set card emulation",[dtdev emv2SetCardEmulationMode:true encryption:ALG_EH_IDTECH keyID:0 error:&error]);

        //configure what masked data should show, the card emulation kernel uses the emulated encrypted head to prepare
        //the masked data
        [dtdev emsrSetActiveHead:EMSR_EMULATED error:nil];
        [dtdev emsrConfigMaskedDataShowExpiration:TRUE unmaskedDigitsAtStart:6 unmaskedDigitsAtEnd:2 error:nil];
    }else
    {
        RF_COMMAND(@"EMV Set card emulation",[dtdev emv2SetCardEmulationMode:false encryption:0 keyID:0 error:&error]);
    }
    
    //try loading configuration, if it is not there already
    DTEMV2Info *info=[dtdev emv2GetInfo:&error];
    if(info)
    {
        //load contactless configuration
        NSData *configContactless=stringToData(@"E406C10400000007E0139F3501215F3601029F3303A020009F1A020840E56EC12FD1D29F029F039F26829F365F349F7C9F6E9F109F1A955F2A9A9C9F375F349F669F39DF029F339F275F245F2A5A5657C23BD1D256579F6BD3D49F1C9F219F41849BDFDC9F029F039F26829F365F349F7C9F6E9F109F1A959A9C9F375F349F669F39DF029F339F275F245F2A5AE155DF810C01049F0606A000000025019F09020001DF8121050000000000DF8120050000000000DF81220500000000009F1E0836303233333231329F160F111213141516171819202122232425DFC3120101DFC3090100E11A9F0607B0000003241010DF810C010F9F3303602800DFC3090100E11B9F0608A000000324101001DF810C010F9F3303602800DFC3090100E11A9F0607A0000003241010DF810C010F9F3303602800DFC3090100E18200899F3303A020009F0607A0000000041010DF8130010DDF81312800080000080020000004000004002000000100000100200000020000020020000000000000000700DF811A039F6A04DF810C01029F6D020001DF811E0110DF812C0100DF812406000000030000DF8125060000000500009F350114DF8126060000000200009F7E009F1C00DFC3090100E18200899F3303A020009F0607A0000000043060DF8130010DDF81312800080000080020000004000004002000000100000100200000020000020020000000000000000700DF811A039F6A04DF810C01029F6D020001DF811E0110DF812C0100DF812406000000030000DF8125060000000500009F350114DF8126060000000300009F7E009F1C00DFC3090100E1349F400560000050019F1B04000027109F0607A0000000031010DF810C01039F33032008C8DFDE01079F660480000000DFC3090100E1349F400560000050019F1B04000027109F0607A0000000999090DF810C01039F33032008C8DFDE01079F660480000000DFC3090100E1339F400560000050019F1B04000027109F0606A00000999901DF810C01039F33032008C8DFDE01079F660480000000DFC3090100");
        
        if(info.contactlessConfigurationVersion!=getConfigurationVesrsion(configContactless))
            RF_COMMAND(@"EMV Load Contactless Configuration",[dtdev emv2LoadContactlessConfiguration:configContactless error:&error]);
        
        if([dtdev getSupportedFeature:FEAT_EMVL2_KERNEL error:nil]&EMV_KERNEL_UNIVERSAL)
        {
            //in case of universal kernel supporting contact/contactless and magnetic payments load contact configuration too
            NSData *configContact=stringToData(@"E406C10400000002E01C9F3501229F3303E0B8C89F4005F000F0A0015F2A0208269F1A020826E1439F0607A00000000310109F3303E0B8C89F09020096DFC001050010000000DFC00205DC4004F800DFC00305FFFFFFFFFFDFC006039F37049F1B0400000001DFC0040101E1439F0607A00000000320109F3303E0B8C89F09020096DFC001050010000000DFC00205DC4004F800DFC00305FFFFFFFFFFDFC006039F37049F1B0400000001DFC0040101E1439F0607A00000000320209F3303E0B8C89F09020096DFC001050010000000DFC00205DC4004F800DFC00305FFFFFFFFFFDFC006039F37049F1B0400000001DFC0040101E1419F0607A00000000410109F09020002DFC001050400000000DFC00205F850ACF800DFC00305FFFFFFFFFFDFC006039F37049F1B04000000019F530152DFC0040101E1419F0607A00000000430609F09020002DFC001050400000000DFC00205F850ACF800DFC00305FFFFFFFFFFDFC006039F37049F1B04000000019F530152DFC0040101E1409F0606A000000065109F09020001DFC001050400000000DFC00205F850ACF800DFC00305FFFFFFFFFFDFC006039F37049F1B04000000019F530152DFC0040101E1429F0606A000000025019F3303E0B8C89F09020001DFC001050000000000DFC00205FFFFFFFFFFDFC00305FFFFFFFFFFDFC006039F37049F1B0400000001DFC0040101");
            
            if(info.contactConfigurationVersion!=getConfigurationVesrsion(configContact))
                RF_COMMAND(@"EMV Load Contact Configuration",[dtdev emv2LoadContactConfiguration:configContact error:&error]);
            
            NSData *capkContact=stringToData(@"E406C10400000001E28200B5DFC31605A0000000039F220199DFC317820080AB79FCC9520896967E776E64444E5DCDD6E13611874F3985722520425295EEA4BD0C2781DE7F31CD3D041F565F747306EED62954B17EDABA3A6C5B85A1DE1BEB9A34141AF38FCF8279C9DEA0D5A6710D08DB4124F041945587E20359BAB47B7575AD94262D4B25F264AF33DEDCF28E09615E937DE32EDC03C54445FE7E382777DFC3180103DFC3190101DFC31A144ABFFD6B1C51212D05552E431C5B17007D2F5E6DE28200C5DFC31605A0000000039F220195DFC317820090BE9E1FA5E9A803852999C4AB432DB28600DCD9DAB76DFAAA47355A0FE37B1508AC6BF38860D3C6C2E5B12A3CAAF2A7005A7241EBAA7771112C74CF9A0634652FBCA0E5980C54A64761EA101A114E0F0B5572ADD57D010B7C9C887E104CA4EE1272DA66D997B9A90B5A6D624AB6C57E73C8F919000EB5F684898EF8C3DBEFB330C62660BED88EA78E909AFF05F6DA627BDFC3180103DFC3190101DFC31A14EE1511CEC71020A9B90443B37B1D5F6E703030F6E28200E5DFC31605A0000000039F220192DFC3178200B0996AF56F569187D09293C14810450ED8EE3357397B18A2458EFAA92DA3B6DF6514EC060195318FD43BE9B8F0CC669E3F844057CBDDF8BDA191BB64473BC8DC9A730DB8F6B4EDE3924186FFD9B8C7735789C23A36BA0B8AF65372EB57EA5D89E7D14E9C7B6B557460F10885DA16AC923F15AF3758F0F03EBD3C5C2C949CBA306DB44E6A2C076C5F67E281D7EF56785DC4D75945E491F01918800A9E2DC66F60080566CE0DAF8D17EAD46AD8E30A247C9FDFC3180103DFC3190101DFC31A14429C954A3859CEF91295F663C963E582ED6EB253E2820132DFC31605A0000000039F220194DFC3178200F8ACD2B12302EE644F3F835ABD1FC7A6F62CCE48FFEC622AA8EF062BEF6FB8BA8BC68BBF6AB5870EED579BC3973E121303D34841A796D6DCBC41DBF9E52C4609795C0CCF7EE86FA1D5CB041071ED2C51D2202F63F1156C58A92D38BC60BDF424E1776E2BC9648078A03B36FB554375FC53D57C73F5160EA59F3AFC5398EC7B67758D65C9BFF7828B6B82D4BE124A416AB7301914311EA462C19F771F31B3B57336000DFF732D3B83DE07052D730354D297BEC72871DCCF0E193F171ABA27EE464C6A97690943D59BDABB2A27EB71CEEBDAFA1176046478FD62FEC452D5CA393296530AA3F41927ADFE434A2DF2AE3054F8840657A26E0FC617DFC3180103DFC3190101DFC1050101DFC31A14C4A3C43CCF87327D136B804160E47D43B60E6E0F");
            
            if(info.contactCAPKVersion!=getConfigurationVesrsion(capkContact))
                RF_COMMAND(@"EMV Load Contact CAPK",[dtdev emv2LoadContactCAPK:capkContact error:&error]);
            
            //change some messages in the config
//            NSMutableArray *uiTags=[NSMutableArray array];
//            [uiTags addObject:[self emvMakeUITag:EMV_UI_PRESENT_CARD message:@"Present Card" font:FONT_8X16]];
//            TLV *tagE6=[TLV tlvWithData:[TLV encodeTags:uiTags] tag:0xE6];
//            NSData *uiConfig=[TLV encodeTags:@[tagE6]];
//            RF_COMMAND(@"EMV Load Generic Config",[dtdev emv2LoadGenericConfiguration:uiConfig error:&error]);
        }
        //process with transaction
        
        //overwrite terminal capabilities flag depending on the connected device
        NSData *initData=nil;
        TLV *tag9f33=nil;
        if([dtdev getSupportedFeature:FEAT_PIN_ENTRY error:nil]==FEAT_SUPPORTED)
        {//pinpad
            tag9f33=[TLV tlvWithHexString:@"60 60 C8" tag:TAG_9F33_TERMINAL_CAPABILITIES];
        }else
        {//linea
            tag9f33=[TLV tlvWithHexString:@"40 28 C8" tag:TAG_9F33_TERMINAL_CAPABILITIES];
        }
        
        //enable cvv on manual card entry
        TLV *tagCVVEnabled=[TLV tlvWithHexString:@"01" tag:TAG_C1_CVV_ENABLED];

        //change decimal separator to .
        TLV *tagDecimalSeparator=[TLV tlvWithString:@" " tag:TAG_C2_DECIMAL_SEPARATOR];
        
        initData=[TLV encodeTags:@[tag9f33, tagCVVEnabled, tagDecimalSeparator]];
        
        //amount: $1.00, currency code: USD(840), according to ISO 4217
        RF_COMMAND(@"EMV Init",[dtdev emv2SetTransactionType:0x00 amount:1500 currencyCode:840 error:&error]);
        //start the transaction, transaction steps will be notified via emv2On... delegate methods
        RF_COMMAND(@"EMV Start Transaction",[dtdev emv2StartTransactionOnInterface:EMV_INTERFACE_CONTACT|EMV_INTERFACE_CONTACTLESS|EMV_INTERFACE_MAGNETIC|EMV_INTERFACE_MAGNETIC_MANUAL flags:0 initData:initData timeout:10 error:&error]);
    }
    
    if(error)
    {
        [dtdev emv2Deinitialise:&error];
    }else
    {
        [progressViewController viewWillAppear:FALSE];
        [self.view addSubview:progressViewController.view];
        [progressViewController updateText:@"Tap NFC Card to execute transaction"];
    }
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dtdev=[DTDevices sharedDevice];
    [dtdev addDelegate:self];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [dtdev removeDelegate:self];
    [dtdev emv2CancelTransaction:nil];
    [dtdev emv2Deinitialise:nil];
    [progressViewController.view removeFromSuperview];
    
    [[NSUserDefaults standardUserDefaults] setInteger:segKernelType.selectedSegmentIndex forKey:@"emv2KernelType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)viewDidLoad
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSInteger kernel=[prefs integerForKey:@"emv2KernelType"];
    
    segKernelType.selectedSegmentIndex=kernel;
    
    [super viewDidLoad];
}


@end
