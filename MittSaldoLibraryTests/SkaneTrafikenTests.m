//
//  SkaneTrafikenTests.m
//  MittSaldoLibrary
//
//  Created by Björn Sållarp on 8/14/12.
//  Copyright (c) 2012 Björn Sållarp. All rights reserved.
//

#import "SkaneTrafikenTests.h"
#import "MSLSkanetrafikenServiceProxy.h"
#import "MSLParsedAccount.h"

@interface MSLSkanetrafikenServiceProxy(UnitTests)
- (NSString *)parseViewstateValueFromHTML:(NSString *)html;
- (NSArray *)parseAccountDropdownFromHTML:(NSString *)html;
- (NSDictionary *)parseAccountDataFromHTML:(NSString *)html;
@end

@implementation SkaneTrafikenTests

- (void)setUp
{
    [super setUp];
    
    [NSURLProtocol registerClass:[ILCannedURLProtocol class]];
    
	[ILCannedURLProtocol setDelegate:nil];
	
	[ILCannedURLProtocol setCannedStatusCode:200];
	[ILCannedURLProtocol setCannedHeaders:nil];
	[ILCannedURLProtocol setCannedResponseData:nil];
	[ILCannedURLProtocol setCannedError:nil];
	
	[ILCannedURLProtocol setSupportedMethods:nil];
	[ILCannedURLProtocol setSupportedSchemes:nil];
	[ILCannedURLProtocol setSupportedBaseURL:nil];
	
	[ILCannedURLProtocol setResponseDelay:0];
}

- (void)tearDown
{
    [NSURLProtocol unregisterClass:[ILCannedURLProtocol class]];
    
    [super tearDown];
}

- (void)testLogin
{
    [ILCannedURLProtocol setDelegate:self];
    
    MSLSkanetrafikenServiceProxy *proxy = [MSLSkanetrafikenServiceProxy proxyWithUsername:@"55456" andPassword:@"1111"];
    
    __block BOOL asynchIsDone = NO;
    __block BOOL didWork = NO;
    __block NSArray *parsedAccounts = nil;
    
    [proxy performLoginWithSuccessBlock:^{
        
        [proxy fetchAccountBalance:^(NSArray *accounts) {
            parsedAccounts = accounts;
            asynchIsDone = YES;
            didWork = YES;
        } failure:^(NSError *error, NSString *errorMessage) {
            asynchIsDone = YES;
        }];

    } failure:^(NSError *error, NSString *errorMessage) {
        asynchIsDone = YES;
    }];
    
    while (!asynchIsDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }

    STAssertTrue(didWork, @"Should work!");
    STAssertEquals([parsedAccounts count], 3U, @"There should be three accounts");
    
    MSLParsedAccount *account = [parsedAccounts lastObject];
    STAssertEqualObjects([account accountName], @"Tobbe Period", nil);
}

- (void)testCardDropdownRegex
{
    NSString *html = [[NSString alloc] initWithData:[self dataForFileWithName:@"SkanetrafikenCardInformation-2574533271"] encoding:NSUTF8StringEncoding];
    
    MSLSkanetrafikenServiceProxy *proxy = [MSLSkanetrafikenServiceProxy proxyWithUsername:@"" andPassword:@""];
    NSArray *accountIds = [proxy parseAccountDropdownFromHTML:html];
    
    STAssertEquals([accountIds count], 3U, @"There should be three cards in the dropdown");
    STAssertEqualObjects([accountIds lastObject], @"3084242189", @"Last item in dropdown should be 3084242189");
}

- (void)testCardBalanceRegex
{
    NSString *html = [[NSString alloc] initWithData:[self dataForFileWithName:@"SkanetrafikenCardInformation-2574533271"] encoding:NSUTF8StringEncoding];
    
    MSLSkanetrafikenServiceProxy *proxy = [MSLSkanetrafikenServiceProxy proxyWithUsername:@"" andPassword:@""];
    NSDictionary *accountInfo = [proxy parseAccountDataFromHTML:html];
    
    STAssertEqualObjects([accountInfo valueForKey:@"name"], @"Gammalt", nil);
    STAssertEqualObjects([accountInfo valueForKey:@"balance"], @"11,20 kr", nil);
    STAssertEqualObjects([accountInfo valueForKey:@"status"], @"Aktivt", nil);
    STAssertEqualObjects([accountInfo valueForKey:@"validPeriod"], @"2011-11-15 - 2011-12-14", nil);
    STAssertEqualObjects([accountInfo valueForKey:@"validzones"], @"235, 240, 241, 242, 243, 250", nil);
    STAssertEqualObjects([accountInfo valueForKey:@"accountid"], @"2574533271", nil);
}

- (void)testViewstateRegex
{
    NSString *html = [[NSString alloc] initWithData:[self dataForFileWithName:@"SkanetrafikenLoginPage"] encoding:NSUTF8StringEncoding];
    
    MSLSkanetrafikenServiceProxy *proxy = [MSLSkanetrafikenServiceProxy proxyWithUsername:@"" andPassword:@""];
    NSString *viewState = [proxy parseViewstateValueFromHTML:html];
    
     STAssertEqualObjects(viewState, @"/wEPDwUJMTQyMTc4Njc2D2QWAmYPZBYCAgEPFgQeBGxhbmcFAnN2Hgh4bWw6bGFuZwUCc3YWAgIDD2QWBAIBDxYEHgRocmVmBQEvHgV0aXRsZQUZU2vDpW5ldHJhZmlrZW5zIHN0YXJ0c2lkYWQCBg9kFgoCAQ9kFgJmD2QWBAIDDw8WAh4JTWF4TGVuZ3RoApYBFgIeCW9ua2V5ZG93bgXKAWlmKGV2ZW50LndoaWNoIHx8IGV2ZW50LmtleUNvZGUpe2lmICgoZXZlbnQud2hpY2ggPT0gMTMpIHx8IChldmVudC5rZXlDb2RlID09IDEzKSkge2RvY3VtZW50LmdldEVsZW1lbnRCeUlkKCdjdGwwMCRmdWxsUmVnaW9uJHF1aWNrc2VhcmNoJFF1aWNrU2VhcmNoQnV0dG9uJykuY2xpY2soKTtyZXR1cm4gZmFsc2U7fX0gZWxzZSB7cmV0dXJuIHRydWV9OyBkAgUPDxYCHgRUZXh0BQRTw7ZrZGQCBQ9kFgYCAw8WAh4HVmlzaWJsZWhkAgUPZBYCZg9kFgJmDw8WAh8HaGRkAgcPZBYCZg9kFgICAQ9kFgZmD2QWDGYPFgIfB2hkAgEPFgIfB2hkAgUPD2QWAh8FBdkBaWYoZXZlbnQud2hpY2ggfHwgZXZlbnQua2V5Q29kZSl7aWYgKChldmVudC53aGljaCA9PSAxMykgfHwgKGV2ZW50LmtleUNvZGUgPT0gMTMpKSB7U2V0Rm9ybUFjdGlvbigpOyBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgnY3RsMDBfZnVsbFJlZ2lvbl9tZW51UmVnaW9uX0xvZ2luX0xvZ2luQnV0dG9uJykuY2xpY2soKTtyZXR1cm4gZmFsc2U7fX0gZWxzZSB7cmV0dXJuIHRydWV9O2QCBw8PZBYCHwUF2QFpZihldmVudC53aGljaCB8fCBldmVudC5rZXlDb2RlKXtpZiAoKGV2ZW50LndoaWNoID09IDEzKSB8fCAoZXZlbnQua2V5Q29kZSA9PSAxMykpIHtTZXRGb3JtQWN0aW9uKCk7IGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCdjdGwwMF9mdWxsUmVnaW9uX21lbnVSZWdpb25fTG9naW5fTG9naW5CdXR0b24nKS5jbGljaygpO3JldHVybiBmYWxzZTt9fSBlbHNlIHtyZXR1cm4gdHJ1ZX07ZAIIDw8WAh8GBQhMb2dnYSBpbhYEHwUF2QFpZihldmVudC53aGljaCB8fCBldmVudC5rZXlDb2RlKXtpZiAoKGV2ZW50LndoaWNoID09IDEzKSB8fCAoZXZlbnQua2V5Q29kZSA9PSAxMykpIHtTZXRGb3JtQWN0aW9uKCk7IGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCdjdGwwMF9mdWxsUmVnaW9uX21lbnVSZWdpb25fTG9naW5fTG9naW5CdXR0b24nKS5jbGljaygpO3JldHVybiBmYWxzZTt9fSBlbHNlIHtyZXR1cm4gdHJ1ZX07HgdvbmNsaWNrBQ9TZXRGb3JtQWN0aW9uKClkAgkPDxYCHwYFCExvZ2dhIGluZGQCAg8PFgIfB2hkFgICBQ8PFgIfBgUITG9nZ2EgdXRkZAIEDw8WAh8HZ2RkAgcPDxYKHghJbWFnZVVybAU4L3VwbG9hZC9CaWxkYmFuay9NZW55YmlsZGVyL0pvam8vbWVueWJpbGR2aXQwMzA1MDkxMy5qcGceCENzc0NsYXNzBQ9tZW51aW1hZ2Vib3R0b20eDUFsdGVybmF0ZVRleHQFMkxhZGRhIEpvam8gLSB0w6R2bGEgb20gZHViYmVsbGFkZG5pbmcgdGlsbCAyNSBtYXJzHgdUb29sVGlwBTJMYWRkYSBKb2pvIC0gdMOkdmxhIG9tIGR1YmJlbGxhZGRuaW5nIHRpbGwgMjUgbWFycx4EXyFTQgICZGQCCw8WBB4FY2xhc3MFHW1haW5hcmVhZGl2IG1haW5hcmVhZGl2Ym9yZGVyHgVzdHlsZQUTd2lkdGg6IDM4LjQ5OTk3NjllbRYCAgEPZBYCAgEPZBYCAgEPZBYCAgQPZBYCAgEPDxYEHgtfaXNFZGl0YWJsZWgeCV9sYXN0VHlwZQUHZGVmYXVsdGRkAg0PZBYCAgEPFgQfDgUMcmlnaHRtZW51ZGl2Hw8FE3dpZHRoOiAxMi4wMDAwMjMxZW0WAgIBD2QWAgIBD2QWAgIGDxYCHwdnZGRvMyHEtW83HGTv+AuQvRWhDGFcZA==", nil);
}

- (NSData *)dataForFileWithName:(NSString *)file
{
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:@"html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
    return htmlData;
}

- (NSURL *)redirectForClient:(id<NSURLProtocolClient>)client request:(NSURLRequest *)request
{
    if ([request.HTTPMethod isEqualToString:@"POST"] && [[request.URL absoluteString] isEqualToString:@"https://www.skanetrafiken.se/templates/MSRootPage.aspx?id=2935&epslanguage=SV"]) {
        return [NSURL URLWithString:@"https://www.skanetrafiken.se/templates/MSStartPage.aspx?id=2289&epslanguage=SV"];
    }
    
    return nil;
}

- (NSData *)responseDataForClient:(id<NSURLProtocolClient>)client request:(NSURLRequest*)request
{
	NSData *requestData = nil;
    
	if ([request.URL.absoluteString isEqual:@"https://www.skanetrafiken.se/templates/MSRootPage.aspx?id=2935&epslanguage=SV"] &&
        [request.HTTPMethod isEqualToString:@"GET"]) {
		requestData = [self dataForFileWithName:@"SkanetrafikenLoginPage"];
	}
    else if ([request.URL.absoluteString isEqual:@"https://www.skanetrafiken.se/templates/CardInformation.aspx?id=26957&epslanguage=SV"]) {
		if ([[request.HTTPMethod uppercaseString] isEqualToString:@"GET"]) {
            requestData = [self dataForFileWithName:@"SkanetrafikenCardInformation"];
        }
        else if ([[request.HTTPMethod uppercaseString] isEqualToString:@"POST"]) {
            
            NSString *postString = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
            
            if ([postString rangeOfString:@"__EVENTTARGET=ctl00%24fullRegion%24mainRegion%24CardInformation1%24mRepeaterMyCards%24ctl01%24LinkButton1"].location != NSNotFound) {
                requestData = [self dataForFileWithName:@"SkanetrafikenCardInformation-2574533271"];
            }
            else if ([postString rangeOfString:@"ctl00%24fullRegion%24mainRegion%24CardInformation1%24mDropDownChooseCard=1728728941"].location != NSNotFound) {
                requestData = [self dataForFileWithName:@"SkanetrafikenCardInformation-1728728941"];	
            }
            else if ([postString rangeOfString:@"ctl00%24fullRegion%24mainRegion%24CardInformation1%24mDropDownChooseCard=3084242189"].location != NSNotFound) {
                requestData = [self dataForFileWithName:@"SkanetrafikenCardInformation-3084242189"];
            }
        }
	}

	return requestData;
}

@end
