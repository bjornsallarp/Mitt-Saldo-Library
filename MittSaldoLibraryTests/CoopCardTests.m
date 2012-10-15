//
//  CoopCardTests.m
//  MittSaldoLibrary
//
//  Created by Björn Sållarp on 8/14/12.
//  Copyright (c) 2012 Björn Sållarp. All rights reserved.
//

#import "CoopCardTests.h"
#import "MSLCoopCardServiceProxy.h"
#import "MSLParsedAccount.h"

@implementation CoopCardTests

- (void)setUp
{
    [super setUp];
    
    [NSURLProtocol registerClass:[ILCannedURLProtocol class]];
    
	[ILCannedURLProtocol setDelegate:self];
	
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

- (void)testCoopServiceProxy
{
    __block BOOL asynchIsDone = NO;
    __block BOOL didWork = NO;
    __block NSArray *parsedAccounts = nil;
    
    MSLCoopCardServiceProxy *proxy = [MSLCoopCardServiceProxy proxyWithUsername:@"8209250000" andPassword:@"1111"];
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
    STAssertEquals([parsedAccounts count], 1U, @"There should be 1 account");
    
    MSLParsedAccount *account = [parsedAccounts lastObject];
    STAssertEqualObjects(account.accountName, @"MedMera Konto", @"Account name should be 'MedMera Konto'");
    STAssertEqualObjects(account.amount, [NSNumber numberWithDouble:2736.59], @"Account balance should be 2736.59");
    
}

- (NSData *)responseDataForClient:(id<NSURLProtocolClient>)client request:(NSURLRequest*)request
{
    if ([request.URL.absoluteString isEqual:@"https://www.coop.se/ExternalServices/UserService.svc/Authenticate"]) {
        return [@"{\"AuthenticateResult\":{\"Token\":\"0ff4d2a7-4a54-43e0-90ca-111111111\",\"UserID\":11111}}" dataUsingEncoding:NSUTF8StringEncoding];
    }
    else if ([request.URL.absoluteString isEqual:@"https://www.coop.se/ExternalServices/FinancialService.svc/HasFinancialAccounts"]) {
        return [@"{\"HasFinancialAccountsResult\":true}" dataUsingEncoding:NSUTF8StringEncoding];
    }
    else if ([request.URL.absoluteString isEqual:@"https://www.coop.se/ExternalServices/FinancialService.svc/Accounts"]) {
        return [@"{\"AccountsResult\":[{\"Balance\":2736.59,\"Name\":\"MedMera Konto\"}]}" dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

@end
