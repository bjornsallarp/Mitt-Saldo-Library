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
#import "MSLHiddenInputsParser.h"
#import "JSONKit.h"
#import "MSLParsedAccount.h"

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@interface MSLSLAccessCardServiceProxy()
@property (nonatomic, strong) NSString *ownerRef;
@end

NSString * const kMSLSLAccessLoginURL = @"https://sl.se/sv/Resenar/Mitt-SL/Mitt-SL/?mobileView=true";
NSString * const kMSLSLAccessAuthURL = @"https://sl.se/ext/mittsl/api/authenticate.json";
NSString * const kMSLSLAccessBalanceURL = @"https://sl.se/ext/mittsl/api/travel_card.json?queryproperty=owner.ref&value=";

@implementation MSLSLAccessCardServiceProxy
@synthesize ownerRef = _ownerRef;

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
            [self postLoginFormWithSuccess:success failure:failure];
        }
        else {
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
}

- (void)postLoginFormWithSuccess:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@"Authenticate" forKey:@"form_name"];
    
    NSDictionary *authDict = [NSDictionary dictionaryWithObjectsAndKeys:self.username, @"username", self.password, @"password", nil];
    
    NSDictionary *redirectDict = [NSDictionary dictionaryWithObject:@"/sv/Resenar/Mitt-SL/MittSL-Oversikt/" forKey:@"200"];
    
    NSDictionary *extDict = [NSDictionary dictionaryWithObject:@"/sv/Resenar/Mitt-SL/Personuppgifter/Andra-losenord-kravs/" forKey:@"change_password_url"];
    
    [params setValue:authDict forKey:@"post_data"];
    [params setValue:redirectDict forKey:@"redirect"];
    [params setValue:extDict forKey:@"ext"];
    
    NSURL *postUrl = [NSURL URLWithString:kMSLSLAccessAuthURL];
    
    [[MSLNetworkingClient sharedClient] postJSONRequestWithURL:postUrl andParameters:params cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {
            NSDictionary *result = [requestOperation.responseString objectFromJSONString];
            self.ownerRef = [[[[result valueForKey:@"result_data"] valueForKey:@"authentication_session"] valueForKey:@"party_ref"] valueForKey:@"ref"];
            
            [self callSuccessBlock:success];
        }
        else {
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
}

- (void)fetchAccountBalance:(void(^)(NSArray *accounts))success failure:(MSLServiceFailureBlock)failure
{
    NSString *balanceUrl = [NSString stringWithFormat:@"%@%@", kMSLSLAccessBalanceURL, self.ownerRef];
    
    [[MSLNetworkingClient sharedClient] getRequestWithURL:[NSURL URLWithString:balanceUrl] cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {

        if (requestOperation.hasAcceptableStatusCode) {
            
            NSMutableArray *parsedAccounts = [NSMutableArray array];
            
            NSDictionary *result = [requestOperation.responseString objectFromJSONString];
            
            for (NSDictionary *card in [[result valueForKey:@"result_data"] valueForKey:@"travel_card_list"])
            {
                NSDictionary *travelCard = [card valueForKey:@"travel_card"];
                
                MSLParsedAccount *account = [[MSLParsedAccount alloc] init];
                account.accountId = [NSNumber numberWithInt:[parsedAccounts count]];
                account.accountName = [travelCard valueForKey:@"name"];
                account.amount = [[travelCard valueForKey:@"detail"] valueForKey:@"purse_value"];
                
                [parsedAccounts addObject:account];
            }
            
            success(parsedAccounts);
        }
        else {
            debug_NSLog(@"Response: %@", requestOperation.responseString);
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
}

- (NSURL *)transferFundsURL
{
    return [NSURL URLWithString:@"https://sl.se/sv/Resenar/Mitt-SL/SL-Accesskort/"];
}

#pragma mark - Accessors

- (NSURL *)loginURL
{
    return [NSURL URLWithString:kMSLSLAccessLoginURL];
}

@end
