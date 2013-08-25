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
#import "MSLHiddenInputsParser.h"
#import "MSLLansforsakringarAccountParser.h"
#import "MSLNetworkingClient.h"

NSString * const kMSLansforsakringarLoginURL = @"https://secure246.lansforsakringar.se/im/login/privat";

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@interface MSLLansforsakringarServiceProxy()
@property (nonatomic, strong) NSURL *intTransferFundsUrl;
@property (nonatomic, strong) NSURL *intAccountListUrl;
@property (nonatomic, strong) NSString *authenticatedResponse;
@property (nonatomic, strong) NSURL *authenticatedUrl;
@end

@implementation MSLLansforsakringarServiceProxy
@synthesize intTransferFundsUrl = _intTransferFundsUrl;
@synthesize intAccountListUrl = _intAccountListUrl;
@synthesize authenticatedResponse = _authenticatedResponse;
@synthesize authenticatedUrl = _authenticatedUrl;

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
            MSLHiddenInputsParser *loginParser = [[MSLHiddenInputsParser alloc] init];

            if ([loginParser parseXMLData:requestOperation.responseData parseError:&error]) {

                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:loginParser.hiddenFields];
                [dict setValue:self.username forKey:@"inputPersonalNumber"];
                [dict setValue:self.password forKey:@"inputPinCode"];
                [dict setValue:@"PIN-kod" forKey:@"selMechanism"];
                [dict setValue:@"0" forKey:@"btnLogin.x"];
                [dict setValue:@"0" forKey:@"btnLogin.y"];
                
                // Add all the hidden fields we previously parsed from the login-page
                for (NSString *key in loginParser.hiddenFields) {
                    [dict setValue:[loginParser.hiddenFields valueForKey:key] forKey:key];
                }
                
                [self postLoginForm:requestOperation.response.URL form:dict successBlock:success failure:failure];
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

- (void)postLoginForm:(NSURL *)url form:(NSDictionary *)dictionary successBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    [[MSLNetworkingClient sharedClient] postRequestWithURL:url andParameters:dictionary cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        
        if ([[requestOperation.response.URL absoluteString] rangeOfString:@"/im/im/start.jsf"].location != NSNotFound) {
            
            NSString *token = [self parseNextRequestTokenFromHtml:requestOperation.responseString];
            
            self.intTransferFundsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure246.lansforsakringar.se/im/index_account.jsf?newUc=true&_token=%@", token]];
            
            self.intAccountListUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://secure246.lansforsakringar.se/im/index_account.jsf?newUc=true&_token=%@", token]];
            
            self.authenticatedResponse = requestOperation.responseString;
            self.authenticatedUrl = requestOperation.response.URL;
            
            [self callSuccessBlock:success];
        }
        else {
            [self callFailureBlock:failure withError:nil andMessage:@"BankLoginDeniedAlert"];
        }
    }];
}

- (void)fetchAccountBalance:(void(^)(NSArray *accounts))success failure:(MSLServiceFailureBlock)failure
{
    [[MSLNetworkingClient sharedClient] getRequestWithURL:[self accountsListURL] cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        
        if ([requestOperation hasAcceptableStatusCode]) {
            
            MSLHiddenInputsParser *parser = [[MSLHiddenInputsParser alloc] init];
            [parser parseXMLData:requestOperation.responseData parseError:&error];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:parser.hiddenFields];
            [dict setValue:@"Submit Query" forKey:@"dialog-account_viewAccountList"];
            [dict setValue:@"" forKey:@"loginForm:_idcl"];
            [dict setValue:@"" forKey:@"loginForm:_link_hidden_"];
            
            [[MSLNetworkingClient sharedClient] postRequestWithURL:[NSURL URLWithString:@"https://secure246.lansforsakringar.se/im/index_account.jsf"] andParameters:dict cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                
                MSLAccountsParserBase *parser = [self accountsParser];
                NSError *parseError = nil;
                [parser parseXMLData:requestOperation.responseData parseError:&parseError];
                if ([parser.parsedAccounts count] > 0) {
                    if (success) {
                        success(parser.parsedAccounts);
                    }
                }
                else if (failure) {
                    debug_NSLog(@"Balance response: %@\r\n\r\n", requestOperation.responseString);
                    debug_NSLog(@"Cookies: %@\r\n\r\n", self.cookieStorage);
                    
                    failure(nil, @"Kunde inte läsa ut saldoinformationen");
                }
            }];
        }
    }];
}
        
- (NSString *)parseNextRequestTokenFromHtml:(NSString *)html
{
    NSError *regexError = nil;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"token[\\d\\D]*?=[\\d\\D]*?'(.+)';"
                                                                           options:NSRegularExpressionCaseInsensitive error:&regexError];
    
    NSTextCheckingResult *result = [regex firstMatchInString:html options:0 range:NSMakeRange(0, [html length])];
    
    if ([result rangeAtIndex:1].location != NSNotFound) {
        NSString *token = [html substringWithRange:[result rangeAtIndex:1]];
        
        debug_NSLog(@"Token: %@", token);
        
        return token;
    }
    
    return nil;
}

- (void)loadLoginIntoBrowser:(UIWebView *)browser
{
    [browser loadHTMLString:self.authenticatedResponse baseURL:self.authenticatedUrl];
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
    return self.intTransferFundsUrl;
}

- (NSURL *)accountsListURL
{
    return self.intAccountListUrl;
}
     
@end
