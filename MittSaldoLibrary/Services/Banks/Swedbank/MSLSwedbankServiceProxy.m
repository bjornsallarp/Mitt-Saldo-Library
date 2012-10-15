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

#import "MSLSwedbankServiceProxy.h"
#import "MSLSwedbankLoginParser.h"
#import "MSLSwedbankAccountParser.h"
#import "MSLNetworkingClient.h"

NSString * const kMSSwedbankLoginURL = @"https://mobilbank.swedbank.se/banking/swedbank/login.html";
NSString * const kMSSwedbankTransferFundsURL = @"https://mobilbank.swedbank.se/banking/swedbank/newTransfer.html";
NSString * const kMSSwedbankAccountListURL = @"https://mobilbank.swedbank.se/banking/swedbank/accounts.html";

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@interface MSLSwedbankServiceProxy ()
@property (nonatomic, strong) MSLSwedbankLoginParser *loginParser;
@end

@implementation MSLSwedbankServiceProxy


+ (id)proxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MSLSwedbankServiceProxy *login = [[self alloc] init];
    login.username = username;
    login.password = password;
    
    return login;
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    self.loginParser = [[MSLSwedbankLoginParser alloc] init];
    [self loginStepOneWithSuccessBlock:success failure:failure];
}

- (void)loginStepOneWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    [[MSLNetworkingClient sharedClient] getRequestWithURL:[self loginURL] cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {
            
            [self.loginParser parseXMLData:requestOperation.responseData parseError:nil];
            
            if (self.loginParser.csrf_token == nil || [self.loginParser.csrf_token isEqualToString:@""]) {
                [self callFailureBlock:failure withError:nil andMessage:@"Kunde inte avkoda inloggningsformuläret"];
            }
            else {
                [self loginStepTwoWithSuccessBlock:success failure:failure];
            }
        }
        else {
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
}

- (void)loginStepTwoWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
   [self postLoginWithCompletionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
       if ([requestOperation hasAcceptableStatusCode]) {
           [self.loginParser parseXMLData:requestOperation.responseData parseError:nil];
           
           if (self.loginParser.passwordField) {
               [self loginStepThreeWithSuccessBlock:success failure:failure];
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

- (void)loginStepThreeWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    [self postLoginWithCompletionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {
            
            if ([requestOperation.responseString rangeOfString:@"Automatisk utloggning"].length > 0) {
                // Restart the authentication
                [self loginStepOneWithSuccessBlock:success failure:failure];
            }
            else if ([requestOperation.responseString rangeOfString:@"_csrf_token"].length > 0) {
                debug_NSLog(@"Swedbank. Login failure 3: %@", requestOperation.responseString);
                [self callFailureBlock:failure withError:nil andMessage:@"BankLoginDeniedAlert"];
            }
            else if ([requestOperation.responseString rangeOfString:@"<h1>Fel</h1>"].location != NSNotFound) {
                [self callFailureBlock:failure withError:nil andMessage:@"Swedbank har för tillfället problem med sin mobilbank, försök igen lite senare."];
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

- (void)postLoginWithCompletionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:self.username forKey:self.loginParser.usernameField];
    [params setValue:self.loginParser.csrf_token forKey:@"_csrf_token"];
    [params setValue:@"code" forKey:@"auth-method"];
    
    if (self.loginParser.passwordField) {
        [params setValue:self.password forKey:self.loginParser.passwordField];
    }
    
    NSURL *postUrl = [NSURL URLWithString:self.loginParser.nextLoginStepUrl relativeToURL:[NSURL URLWithString:kMSSwedbankLoginURL]];
    [[MSLNetworkingClient sharedClient] postRequestWithURL:postUrl andParameters:params cookieStorage:self.cookieStorage completionBlock:block];
}

#pragma mark - Accessors

- (id)accountsParser
{
    return [[MSLSwedbankAccountParser alloc] init];
}

- (NSURL *)loginURL
{
    return [NSURL URLWithString:kMSSwedbankLoginURL];
}

- (NSURL *)transferFundsURL
{
    return [NSURL URLWithString:kMSSwedbankTransferFundsURL];
}

- (NSURL *)accountsListURL
{
    return [NSURL URLWithString:kMSSwedbankAccountListURL];
}

@end
