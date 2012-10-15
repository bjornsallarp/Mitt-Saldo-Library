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

#import "MSLSEBServiceProxy.h"
#import "MSLSEBAccountParser.h"
#import "MSNetworkingClient.h"

NSString * const kMSSEBLoginURL = @"https://m.seb.se/cgi-bin/pts3/mps/1000/mps1001bm.aspx";
NSString * const kMSSEBTransferFundsURL = @"https://m.seb.se/cgi-bin/pts3/mps/1100/mps1104.aspx?P1=E";
NSString * const kMSSEBAccountListURL = @"https://m.seb.se/cgi-bin/pts3/mps/1100/mps1101.aspx?X1=passWord";

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@implementation MSLSEBServiceProxy

+ (id)proxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MSLSEBServiceProxy *login = [[self alloc] init];
    login.username = username;
    login.password = password;
    
    return login;
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@"4" forKey:@"A3"]; // 4 = password
    [dict setValue:self.username forKey:@"A1"];
    [dict setValue:self.password forKey:@"A2"];
    
    
    [[MSLNetworkingClient sharedClient] postRequestWithURL:[self loginURL] andParameters:dict cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {
            
            if ([requestOperation.responseString  rangeOfString:@"passwordLoginOK"].location != NSNotFound || 
                [requestOperation.responseString  rangeOfString:@"redirect"].location != NSNotFound) {
                [self callSuccessBlock:success];
            }
            else {
                [self callFailureBlock:failure withError:nil andMessage:@"BankLoginDeniedAlert"];
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
    return [[MSLSEBAccountParser alloc] init];
}

- (NSURL *)loginURL
{
    return [NSURL URLWithString:kMSSEBLoginURL];
}

- (NSURL *)transferFundsURL
{
    return [NSURL URLWithString:kMSSEBTransferFundsURL];
}

- (NSURL *)accountsListURL
{
    return [NSURL URLWithString:kMSSEBAccountListURL];
}

@end
