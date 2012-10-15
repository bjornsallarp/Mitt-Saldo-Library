//
//  MittSaldoLibraryTests.m
//  MittSaldoLibraryTests
//
//  Created by Björn Sållarp on 8/13/12.
//  Copyright (c) 2012 Björn Sållarp. All rights reserved.
//

#import "HandelsbankenTests.h"
#import "MSLHandelsbankenMenuParser.h"
#import "MSLHandelsbankenAccountParser.h"
#import "MSLParsedAccount.h"
#import "MSLHandelsbankenServiceProxy.h"
#import "MSLHandelsbankenServiceDescription.h"

@implementation HandelsbankenTests

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

- (void)testValidationMethods
{
    MSLHandelsbankenServiceDescription *description = [[MSLHandelsbankenServiceDescription alloc] init];
    
    NSString *validationMessage = nil;
    STAssertTrue([description isValidUsernameForService:@"1111111111" validationMessage:&validationMessage], @"Username should be valid");
    STAssertTrue([description isValidPasswordForService:@"1111" validationMessage:&validationMessage], @"Password should be valid");
                  
}

- (void)testSHBLoginMenuParser
{
    NSData *responseData = [self dataForFileWithName:@"SHBLoginMenu"];
    
    MSLHandelsbankenMenuParser *menuParser = [[MSLHandelsbankenMenuParser alloc] init];
    NSError *error = nil;
    BOOL parseSuccess = [menuParser parseXMLData:responseData parseError:&error];
    
    STAssertTrue(parseSuccess, @"Parsing failed: %@", [error localizedDescription]);
    STAssertEquals([menuParser.menuLinks count], 6U, @"There should be 6 links in the menu");
    STAssertEqualObjects([menuParser.menuLinks objectAtIndex:0], @"/primary/_-iseufea5", @"The login url should be /primary/_-iseufea5");
    
}


- (void)testSHBAuthenticatedMenuParser
{
    NSData *responseData = [self dataForFileWithName:@"SHBAuthenticatedMenu"];
    
    MSLHandelsbankenMenuParser *menuParser = [[MSLHandelsbankenMenuParser alloc] init];
    NSError *error = nil;
    BOOL parseSuccess = [menuParser parseXMLData:responseData parseError:&error];
    
    STAssertTrue(parseSuccess, @"Parsing failed: %@", [error localizedDescription]);
    STAssertEquals([menuParser.menuLinks count], 8U, @"There should be 8 links in the menu");
    STAssertEqualObjects([menuParser.menuLinks objectAtIndex:0], @"/primary/_-iMjgXb6lMTBv", @"The accounts list url should be /primary/_-iMjgXb6lMTBv");
    STAssertEqualObjects([menuParser.menuLinks objectAtIndex:1], @"/primary/_-iNjgXbn0JKzn", @"The transfer funds url should be /primary/_-iNjgXbn0JKzn");
    
}

- (void)testSHBAccountsParser
{
    NSData *responseData = [self dataForFileWithName:@"SHBAccountsList"];
    
    MSLHandelsbankenAccountParser *accountsParser = [[MSLHandelsbankenAccountParser alloc] init];
    NSError *error = nil;
    BOOL parseSuccess = [accountsParser parseXMLData:responseData parseError:&error];
    
    STAssertTrue(parseSuccess, @"Parsing failed: %@", [error localizedDescription]);
    STAssertEquals([accountsParser.parsedAccounts count], 3U, @"There should be 3 accounts");
    
    MSLParsedAccount *account1 = [accountsParser.parsedAccounts objectAtIndex:0];
    MSLParsedAccount *account2 = [accountsParser.parsedAccounts objectAtIndex:1];
    MSLParsedAccount *account3 = [accountsParser.parsedAccounts objectAtIndex:2];
    
    STAssertEqualObjects(account1.accountName, @"Allkonto", @"Accountname should be Allkonto");
    STAssertEqualObjects(account1.amount, [NSNumber numberWithDouble:1784.48], @"Account should have a balance of 1784.48");

    STAssertEqualObjects(@"Allkonto", account2.accountName, @"Accountname should be Allkonto");
    STAssertEqualObjects(account2.amount, [NSNumber numberWithDouble:5158.32], @"Account should have a balance of 5158.32");
    
    STAssertEqualObjects(@"Sparkonto", account3.accountName, @"Accountname should be Sparkonto");
    STAssertEqualObjects(account3.amount, [NSNumber numberWithDouble:169503.00], @"Account should have a balance of 169503");
    
}

- (void)testSHBServiceProxy
{
    __block BOOL asynchIsDone = NO;
    __block BOOL didWork = NO;
    __block NSArray *parsedAccounts = nil;
    
    [ILCannedURLProtocol setDelegate:self];
    MSLHandelsbankenServiceProxy *proxy = [MSLHandelsbankenServiceProxy proxyWithUsername:@"8209250000" andPassword:@"1111"];
    [proxy performLoginWithSuccessBlock:^{
        [proxy fetchAccountBalance:^(NSArray *accounts) {
            parsedAccounts = accounts;
            asynchIsDone = didWork = YES;
        } failure:^(NSError *error, NSString *errorMessage) {
            
            asynchIsDone = YES;
        }];
    } failure:^(NSError *error, NSString *errorMessage) {
        asynchIsDone = YES;
    }];
    
    while (!asynchIsDone) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    STAssertTrue(didWork, @"Fetching accounts should work!");
    STAssertEquals([parsedAccounts count], 3U, @"There should be 3 accounts");
}

- (NSData *)dataForFileWithName:(NSString *)file
{
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:@"html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
    return htmlData;
}

#pragma mark - ILCannedURLProtocolDelegate

- (NSData *)responseDataForClient:(id<NSURLProtocolClient>)client request:(NSURLRequest*)request
{    
	NSData *requestData = nil;
    
	if ([request.URL.absoluteString isEqual:@"https://m.handelsbanken.se/"]) {
		requestData = [self dataForFileWithName:@"SHBLoginMenu"];
	}
    
    if ([request.URL.absoluteString isEqual:@"https://m.handelsbanken.se/primary/_-iseufea5"]) {
		requestData = [self dataForFileWithName:@"SHBAuthenticatedMenu"];
	}
    
	if ([request.URL.absoluteString isEqual:@"https://m.handelsbanken.se/primary/_-iMjgXb6lMTBv"]) {
		requestData = [self dataForFileWithName:@"SHBAccountsList"];
	}
    
	return requestData;
}

@end
