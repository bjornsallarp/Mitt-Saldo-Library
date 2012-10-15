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

#import "MSLVasttrafikCardServiceProxy.h"
#import "MSLNetworkingClient.h"
#import "MSLParsedAccount.h"
#import "JSONKit.h"

NSString * const kMSVasttrafikCardLoginURL = @"https://www.vasttrafik.se/CustomerServices/EPiServerWs/SecureService.svc/Login";
NSString * const kMSVasttrafikCardBalanceURL = @"https://www.vasttrafik.se/CustomerServices/EPiServerWs/SecureService.svc/GetVtkCardsWithPaging";
NSString * const kMSVasttrafikCardUserAgent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:13.0) Gecko/20100101 Firefox/13.0.1";

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@implementation MSLVasttrafikCardServiceProxy


+ (MSLVasttrafikCardServiceProxy *)proxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MSLVasttrafikCardServiceProxy *login = [[self alloc] init];
    login.username = username;
    login.password = password;
    
    return login;
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
    [loginParams setValue:@"sv-SE" forKey:@"RDC_Language"];
    [loginParams setValue:self.username forKey:@"Username"];
    [loginParams setValue:self.password forKey:@"Password"];
    [loginParams setValue:@NO forKey:@"IsPersistent"];
    NSDictionary *requestDictionary = @{@"request": loginParams};
    
    [[MSLNetworkingClient sharedClient] postJSONRequestWithURL:[NSURL URLWithString:kMSVasttrafikCardLoginURL] userAgent:kMSVasttrafikCardUserAgent parameters:requestDictionary cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        
        if (requestOperation.hasAcceptableStatusCode) {
            NSDictionary *loginResult = [[requestOperation.responseString objectFromJSONString] valueForKey:@"d"];
            
            if ([[loginResult valueForKey:@"IsLoggedIn"] boolValue] == YES) {
                [self callSuccessBlock:success];
            }
            else {
                debug_NSLog(@"Response: %@", requestOperation.responseString);
                [self callFailureBlock:failure withError:nil andMessage:@"BankLoginDeniedAlert"];
            }
        }
        else {
            debug_NSLog(@"Response: %@", requestOperation.responseString);
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
}

- (void)fetchAccountBalance:(void (^)(NSArray *))success failure:(MSLServiceFailureBlock)failure
{
    NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
    [loginParams setValue:@"sv-SE" forKey:@"RDC_Language"];
    [loginParams setValue:@100 forKey:@"PageSize"];
    [loginParams setValue:@1 forKey:@"PageIndex"];
    [loginParams setValue:@5 forKey:@"SortOrder"];
    [loginParams setValue:@YES forKey:@"IncludeBasketCheck"];
    
    NSDictionary *requestDictionary = @{@"request": loginParams};
    
    [[MSLNetworkingClient sharedClient] postJSONRequestWithURL:[NSURL URLWithString:kMSVasttrafikCardBalanceURL] userAgent:kMSVasttrafikCardUserAgent parameters:requestDictionary cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        
        if (requestOperation.hasAcceptableStatusCode) {
            self.balanceResponseString = requestOperation.responseString;
            NSDictionary *result = [[requestOperation.responseString objectFromJSONString] valueForKey:@"d"];
            
            if ([[result valueForKey:@"RDC_Successful"] intValue] == 0) {
                debug_NSLog(@"%@", result);
                [self callFailureBlock:failure withError:nil andMessage:@"Kunde inte hämta information om kortet"];
            }
            else {
                NSArray *cards = [result valueForKey:@"Cards"];
                NSMutableArray *accounts = [NSMutableArray array];
                
                for (NSDictionary *cardDict in cards) {
                    MSLParsedAccount *account = [[MSLParsedAccount alloc] init];
                    account.accountName = [cardDict valueForKey:@"Name"];
                    account.accountId = [cardDict valueForKey:@"Id"];
                    
                    NSDictionary *charge = [[cardDict valueForKey:@"Charges"] firstObject];
                    double amount = [[charge valueForKey:@"Amount"] doubleValue] / 100.0; // Seriously weird.....
                    account.amount = @(amount);
                    
                    [accounts addObject:account];
                }
                
                if (success) {
                    success(accounts);
                }
            }
        }
        else {
            debug_NSLog(@"Response: %@", requestOperation.responseString);
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
}

@end
