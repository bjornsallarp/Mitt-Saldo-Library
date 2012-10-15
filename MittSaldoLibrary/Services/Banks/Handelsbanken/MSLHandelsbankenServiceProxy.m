//
//  Created by Björn Sållarp
//  NO Copyright. NO rights reserved.
//
//  Use this code any way you like. If you do like it, please
//  link to my blog and/or write a friendly comment. Thank you!
//
//  Read my blog @ http://blog.sallarp.com
//  Follow me @bjornsallarp
//  Fork me @ http://github.com/bjornsallarp
//


#import "MSLHandelsbankenServiceProxy.h"
#import "MSLHandelsbankenMenuParser.h"
#import "MSLHandelsbankenAccountParser.h"
#import "MSLNetworkingClient.h"

NSString * const kMSHandelsbankenLoginURL = @"https://m.handelsbanken.se/";

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@interface MSLHandelsbankenServiceProxy ()
@property (nonatomic, strong) MSLHandelsbankenMenuParser *menuParser;
@end

@implementation MSLHandelsbankenServiceProxy


+ (id)proxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MSLHandelsbankenServiceProxy *login = [[self alloc] init];
    login.username = username;
    login.password = password;
    
    return login;
}

- (NSURL *)urlFromRelativeString:(NSString *)relativeURLString
{
    return [NSURL URLWithString:relativeURLString relativeToURL:[NSURL URLWithString:kMSHandelsbankenLoginURL]];
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure 
{
    
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
    NSURL *loginUrl = [NSURL URLWithString:kMSHandelsbankenLoginURL];
    [[MSLNetworkingClient sharedClient] getRequestWithURL:loginUrl cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {

            NSError *error = nil;
            self.menuParser = [[MSLHandelsbankenMenuParser alloc] init];
            if ([self.menuParser parseXMLData:requestOperation.responseData parseError:&error] && [self.menuParser.menuLinks count] > 0) {
                
                // This is super weird but on 3G the user can already be authenticated
                // without posting any cookies etc with the first GET. Doesn't happen on WiFi!?
                if ([requestOperation.responseString rangeOfString:@"Logga ut"].location != NSNotFound) {
                    [self callSuccessBlock:success];
                    return;
                }
                
                NSURL *nextStepUrl = [self urlFromRelativeString:(self.menuParser.menuLinks)[0]];
                [self loginStepTwo:nextStepUrl successBlock:success failure:failure];
            }
            else {
                [self callFailureBlock:failure withError:nil andMessage:@"BankLoginFailureAlert"];
            }
        }
        else {
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
}

- (void)loginStepTwo:(NSURL *)postUrl successBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setValue:self.username forKey:@"username"];
	[params setValue:self.password forKey:@"pin"];
	[params setValue:@"true" forKey:@"execute"];
    
    [[MSLNetworkingClient sharedClient] postRequestWithURL:postUrl andParameters:params cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {

            NSError *error = nil;
            self.menuParser = [[MSLHandelsbankenMenuParser alloc] init];
            if ([self.menuParser parseXMLData:requestOperation.responseData parseError:&error] && [self.menuParser.menuLinks count] >= 2) {
                [self callSuccessBlock:success];
            }
            else {
                [self callFailureBlock:failure withError:nil andMessage:@"BankLoginFailureAlert"];
            }
        } 
        else {
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];	
}

#pragma mark - Accessors

- (id)accountsParser
{
    return [[MSLHandelsbankenAccountParser alloc] init];
}

- (NSURL *)loginURL
{
    return [NSURL URLWithString:kMSHandelsbankenLoginURL];
}

- (NSURL *)transferFundsURL
{
    return [self urlFromRelativeString:(self.menuParser.menuLinks)[1]];
}

- (NSURL *)accountsListURL
{
    return [self urlFromRelativeString:(self.menuParser.menuLinks)[0]];
}

@end
