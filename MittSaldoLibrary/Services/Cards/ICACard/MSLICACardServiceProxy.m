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

#import "MSLICACardServiceProxy.h"
#import "MSLNetworkingClient.h"
#import "JSONKit.h"
#import "MSLParsedAccount.h"

NSString * const kMSIcaCardLoginURL = @"https://www.ica.se/ClientApplicationInterface/Handlers/LoginHandler.ashx";
NSString * const kMSIcaCardBalanceURL = @"https://www.ica.se/ClientApplicationInterface/Handlers/BalanceHandler.ashx";

@implementation MSLICACardServiceProxy


+ (MSLICACardServiceProxy *)proxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MSLICACardServiceProxy *proxy = [[self alloc] init];
    proxy.username = username;
    proxy.password = password;
    
    return proxy;
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{    
    NSMutableDictionary *loginParams = [NSMutableDictionary dictionaryWithObject:@NO forKey:@"RememberMe"];
    [loginParams setValue:self.username forKey:@"CivicNumber"];
    [loginParams setValue:self.password forKey:@"Passw"];
    
    NSDictionary *params = @{@"JSON": [loginParams JSONString]};
    
    [[MSLNetworkingClient sharedClient] postRequestWithURL:[NSURL URLWithString:kMSIcaCardLoginURL] andParameters:params cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                
        NSDictionary *result = [requestOperation.responseString objectFromJSONString];
        if ([[result valueForKey:@"LoggedIn"] boolValue]) {
            if (success) {
               success();
            }
        }
        else if (failure) {
            failure(error, @"BankLoginDeniedAlert");
        }
    }];
}

- (void)fetchAccountBalance:(void(^)(NSArray *accounts))success failure:(MSLServiceFailureBlock)failure
{
    NSDictionary *params = @{@"JSON": @"{}"};
    
    [[MSLNetworkingClient sharedClient] postRequestWithURL:[NSURL URLWithString:kMSIcaCardBalanceURL] andParameters:params cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {

        NSDictionary *result = [requestOperation.responseString objectFromJSONString];
        
        if ([[result valueForKey:@"LoggedIn"] boolValue]) {
            self.balanceJsonResponse = result;
            
            NSMutableArray *parsedAccounts = [NSMutableArray array];
            NSDictionary *accountData = [result valueForKey:@"ClientAccountData"];
            
            if (accountData != nil && ![accountData isKindOfClass:[NSNull class]] && [accountData valueForKey:@"Balance"] != nil) {
                MSLParsedAccount *account = [[MSLParsedAccount alloc] init];
                account.accountId = @0;
                account.accountName = @"ICA konto";
                account.amount = @0;
                account.amount = [accountData valueForKey:@"Balance"];
                account.availableAmount = [accountData valueForKey:@"Available"];
                
                [parsedAccounts addObject:account];
            }

            if (success) {
                success(parsedAccounts);
            }
        }
        else {
            if (failure) {
                failure(nil, @"Kunde inte läsa ut saldoinformationen");
            }   
        }

    }];
}

@end
