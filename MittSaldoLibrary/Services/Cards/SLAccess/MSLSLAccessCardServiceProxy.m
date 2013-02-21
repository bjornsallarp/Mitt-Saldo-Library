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

#import "MSLSLAccessCardServiceProxy.h"
#import "MSLNetworkingClient.h"
#import "MSLSLAccessLoginParser.h"

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@interface MSLSLAccessCardServiceProxy ()
@property (nonatomic, strong) MSLSLAccessLoginParser *loginParser;
@end

NSString * const kMSLSLAccessLoginURL = @"https://sl.se/sv/Resenar/Mitt-SL/Mitt-SL/?mobileView=true";
NSString * const kMSLSLAccessBalanceURL = @"";

@implementation MSLSLAccessCardServiceProxy
@synthesize loginParser = _loginParser;

+ (MSLSLAccessCardServiceProxy *)proxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MSLSLAccessCardServiceProxy *proxy = [[self alloc] init];
    proxy.username = username;
    proxy.password = password;
    
    return proxy;
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    NSURL *loginUrl = [self loginURL];
    
    [[MSLNetworkingClient sharedClient] getRequestWithURL:loginUrl cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {
            
            self.loginParser = [[MSLSLAccessLoginParser alloc] init];
            if (self.loginParser.ssnFieldName && self.loginParser.passwordFieldName) {
                [self loginStepTwoWithSuccessBlock:success failure:failure];
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

- (void)loginStepTwoWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.loginParser.hiddenFields];
    [params setValue:@"" forKey:@"__EVENTARGUMENT"];
    [params setValue:self.loginParser.ssnFieldName forKey:@"__EVENTTARGET"];
    [params setValue:self.username forKey:self.loginParser.ssnFieldName];
    [params setValue:self.password forKey:self.loginParser.passwordFieldName];

    NSURL *postUrl = [NSURL URLWithString:kMSLSLAccessLoginURL];
    [[MSLNetworkingClient sharedClient] postRequestWithURL:postUrl andParameters:params cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {
            
            if ([[requestOperation.response.URL absoluteString] hasPrefix:kMSLSLAccessLoginURL]) {
                [self callFailureBlock:failure withError:nil andMessage:@"BankLoginDeniedAlert"];
                return;
            }
            else {
                [self callSuccessBlock:success];
            }
        }
        else {
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
}

- (void)fetchAccountBalance:(void(^)(NSArray *accounts))success failure:(MSLServiceFailureBlock)failure
{   
    [[MSLNetworkingClient sharedClient] getRequestWithURL:[NSURL URLWithString:kMSLSLAccessBalanceURL] cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {

        if (requestOperation.hasAcceptableStatusCode) {
        
        }
        else {
            debug_NSLog(@"Response: %@", requestOperation.responseString);
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
}

@end
