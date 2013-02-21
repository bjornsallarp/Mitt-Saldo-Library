//
//  VasttrafikTests.m
//  MittSaldoLibrary
//
//  Created by Björn Sållarp on 10/16/12.
//  Copyright (c) 2012 Björn Sållarp. All rights reserved.
//

#import "VasttrafikTests.h"
#import "MSLVasttrafikCardServiceProxy.h"

@implementation VasttrafikTests

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
    MSLVasttrafikCardServiceProxy *proxy = [MSLVasttrafikCardServiceProxy proxyWithUsername:@"foo" andPassword:@"bar"];
    
    [proxy performLoginWithSuccessBlock:^{
        
    } failure:^(NSError *error, NSString *errorMessage) {
        STFail(@"Login to Vasttrafik should work!");
    }];
    
}

- (NSData *)dataForFileWithName:(NSString *)file
{
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:@"json"];
    NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
    return htmlData;
}


- (NSData *)responseDataForClient:(id<NSURLProtocolClient>)client request:(NSURLRequest *)request
{
	NSData *requestData = nil;
    NSString *url = request.URL.absoluteString;
    
	if ([url isEqual:@"https://www.vasttrafik.se/CustomerServices/EPiServerWs/SecureService.svc/Login"]) {
		requestData = [self dataForFileWithName:@"login-response"];
	}
    else if ([url isEqual:@"https://www.vasttrafik.se/CustomerServices/EPiServerWs/SecureService.svc/GetVtkCardsWithPaging"]) {
		requestData = [self dataForFileWithName:@"cards-response"];
	}
    
	return requestData;
}


@end
