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

#import "MSLCoopCardServiceProxy.h"
#import "MSNetworkingClient.h"
#import "MSLParsedAccount.h"
#import "JSONKit.h"

NSString * const kMSCoopCardLoginURL = @"https://www.coop.se/ExternalServices/UserService.svc/Authenticate";
NSString * const kMSCoopCardBalanceURL = @"https://www.coop.se/ExternalServices/FinancialService.svc/Accounts";
NSString * const kMSCoopCardRefundSummaryURL = @"https://www.coop.se/ExternalServices/RefundService.svc/RefundSummary";
NSString * const kMSCoopCardApplicationId = @"687D17CB-85C3-4547-9F8D-A346C7008EB1";

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@implementation MSLCoopCardServiceProxy


+ (MSLCoopCardServiceProxy *)proxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MSLCoopCardServiceProxy *login = [[self alloc] init];
    login.username = username;
    login.password = password;
    
    return login;
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{    
    NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
    [loginParams setValue:self.username forKey:@"username"];
    [loginParams setValue:self.password forKey:@"password"];
    [loginParams setValue:kMSCoopCardApplicationId forKey:@"applicationID"];
    
    [[MSLNetworkingClient sharedClient] postJSONRequestWithURL:[NSURL URLWithString:kMSCoopCardLoginURL] andParameters:loginParams cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        
        if (requestOperation.hasAcceptableStatusCode) {
            NSDictionary *loginResult = [requestOperation.responseString objectFromJSONString];
            debug_NSLog(@"%@", loginResult);
            
            NSDictionary *authResult = [loginResult valueForKey:@"AuthenticateResult"];
            self.authenticationToken = [authResult valueForKey:@"Token"];
            self.userId = [authResult valueForKey:@"UserID"];
            
            NSMutableDictionary *checkAccountsParam = [NSMutableDictionary dictionary]; 
            [checkAccountsParam setValue:self.authenticationToken forKey:@"token"];
            [checkAccountsParam setValue:self.userId forKey:@"userID"];
            [checkAccountsParam setValue:kMSCoopCardApplicationId forKey:@"applicationID"];
        
            [[MSLNetworkingClient sharedClient] postJSONRequestWithURL:[NSURL URLWithString:@"https://www.coop.se/ExternalServices/FinancialService.svc/HasFinancialAccounts"] andParameters:checkAccountsParam cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {

                if (requestOperation.response.statusCode == 200 && [[[requestOperation.responseString objectFromJSONString] valueForKey:@"HasFinancialAccountsResult"] boolValue] == YES) {
                    [self callSuccessBlock:success];
                }
                else {
                    [self callFailureBlock:failure withError:nil andMessage:@"CoopLoginNoAccounts"];
                }
            }];
        }
        else {
            [self callFailureBlock:failure withError:nil andMessage:@"BankLoginDeniedAlert"];
        }
    }];
}

- (void)fetchAccountBalance:(void(^)(NSArray *accounts))success failure:(MSLServiceFailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary]; 
    [params setValue:self.authenticationToken forKey:@"token"];
    [params setValue:self.userId forKey:@"userID"];
    [params setValue:kMSCoopCardApplicationId forKey:@"applicationID"];
    [params setValue:self.password forKey:@"password"];
    
    [[MSLNetworkingClient sharedClient] postJSONRequestWithURL:[NSURL URLWithString:kMSCoopCardBalanceURL] andParameters:params cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        
        if (requestOperation.hasAcceptableStatusCode) {
            NSDictionary *result = [requestOperation.responseString objectFromJSONString];
            
            NSMutableArray *parsedAccounts = [NSMutableArray array];
            for (NSDictionary *accountDict in [result valueForKey:@"AccountsResult"]) {
                MSLParsedAccount *account = [[MSLParsedAccount alloc] init];
                account.accountId = @((int)[parsedAccounts count]);
                account.accountName = [accountDict valueForKey:@"Name"];
                account.amount = [accountDict valueForKey:@"Balance"];
                
                [parsedAccounts addObject:account];
            }
            
            if (success) {
                success(parsedAccounts);
            }
        }
        else {
            [self callFailureBlock:failure withError:nil andMessage:@"Kunde inte läsa ut saldoinformationen"];
        }
    }];
}


- (void)fetchRefundSummary:(void (^)(NSDictionary *response))success failure:(MSLServiceFailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:self.authenticationToken forKey:@"token"];
    [params setValue:self.userId forKey:@"userID"];
    [params setValue:kMSCoopCardApplicationId forKey:@"applicationID"];
    
    [[MSLNetworkingClient sharedClient] postJSONRequestWithURL:[NSURL URLWithString:kMSCoopCardRefundSummaryURL] andParameters:params cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        
        if (requestOperation.hasAcceptableStatusCode) {
            if (success) {
                success([requestOperation.responseString objectFromJSONString][@"RefundSummaryResult"]);
            }
        }
        else {
            [self callFailureBlock:failure withError:nil andMessage:@"Kunde inte hämta information om kortet"];
        }
    }];
}

@end
