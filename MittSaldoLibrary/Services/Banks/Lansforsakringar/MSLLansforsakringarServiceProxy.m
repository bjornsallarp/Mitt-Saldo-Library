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

#import "MSLLansforsakringarServiceProxy.h"
#import "MSLLansforsakringarLoginParser.h"
#import "MSLLansforsakringarAccountParser.h"
#import "MSNetworkingClient.h"

NSString * const kMSLansforsakringarLoginURL = @"https://mobil.lansforsakringar.se/lf-mobile/pages/login.faces?pnr=null";
NSString * const kMSLansforsakringarTransferFundsURL = @"https://mobil.lansforsakringar.se/lf-mobile/pages/overview.faces";
NSString * const kMSLansforsakringarAccountListURL = @"https://mobil.lansforsakringar.se/lf-mobile/pages/overview.faces";

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@implementation MSLLansforsakringarServiceProxy


+ (id)proxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MSLLansforsakringarServiceProxy *login = [[self alloc] init];
    login.username = username;
    login.password = password;
    
    return login;
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{    
    [[MSLNetworkingClient sharedClient] getRequestWithURL:[self loginURL] cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {
            
            NSError *error = nil;
            MSLLansforsakringarLoginParser *loginParser = [[MSLLansforsakringarLoginParser alloc] init];

            if ([loginParser parseXMLData:requestOperation.responseData parseError:&error]) {

                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:loginParser.hiddenFields];
                [dict setValue:self.username forKey:@"login:userId"];
                [dict setValue:self.password forKey:@"login:pin"];
                [dict setValue:@"loginButton" forKey:@"login:loginButton"];
                
                
                // Add all the hidden fields we previously parsed from the login-page
                for (NSString *key in loginParser.hiddenFields) {
                    [dict setValue:[loginParser.hiddenFields valueForKey:key] forKey:key];
                }
                
                [self postLoginForm:dict successBlock:success failure:failure];
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

- (void)postLoginForm:(NSDictionary *)dictionary successBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    [[MSLNetworkingClient sharedClient] postRequestWithURL:[self loginURL] andParameters:dictionary cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation.responseString rangeOfString:@"logout"].location != NSNotFound) {
            
            self.authenticatedResponse = requestOperation.responseData;
            self.authenticatedURL = requestOperation.request.URL;
            
            [self callSuccessBlock:success];
        }
        else {
            [self callFailureBlock:failure withError:nil andMessage:@"BankLoginDeniedAlert"];
        }
    }];
}

- (void)fetchAccountBalance:(void (^)(NSArray *))success failure:(MSLServiceFailureBlock)failure
{
    MSLAccountsParserBase *parser = [self accountsParser];
    NSError *parseError = nil;
    [parser parseXMLData:self.authenticatedResponse parseError:&parseError];
    if ([parser.parsedAccounts count] > 0) {
        if (success) {
            success(parser.parsedAccounts);
        }
    }
    else {
        [self callFailureBlock:failure withError:nil andMessage:@"Kunde inte läsa ut saldoinformationen"];
    }
}

- (void)loadLoginIntoBrowser:(UIWebView *)browser
{
    NSString *html = [[NSString alloc] initWithData:self.authenticatedResponse encoding:NSUTF8StringEncoding];
    [browser loadHTMLString:html baseURL:self.authenticatedURL];
}

#pragma mark - Accessors
     
- (id)accountsParser
{
    return [[MSLLansforsakringarAccountParser alloc] init];
}

- (NSURL *)loginURL
{
    return [NSURL URLWithString:kMSLansforsakringarLoginURL];
}

- (NSURL *)transferFundsURL
{
    return [NSURL URLWithString:kMSLansforsakringarTransferFundsURL];
}

- (NSURL *)accountsListURL
{
    return [NSURL URLWithString:kMSLansforsakringarAccountListURL];
}
     
@end
