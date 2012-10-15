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

#import "MSLIkanoBankServiceProxy.h"
#import "MSLNetworkingClient.h"
#import "MSLIkanoBankLoginParser.h"
#import "MSLIkanoBankAccountParser.h"

NSString * const kMSIkanoLoginURL = @"https://secure.ikanobank.se/MobPubStart";
NSString * const kMSIkanoTransferFundsURL = @"https://secure.ikanobank.se/MobSecSaveTransfer";
NSString * const kMSIkanoAccountListURL = @"https://secure.ikanobank.se/MobSecOverview";

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@interface MSLIkanoBankServiceProxy()
@property (nonatomic, strong) NSString *loginResponse;
@end

@implementation MSLIkanoBankServiceProxy


+ (id)proxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MSLIkanoBankServiceProxy *login = [[self alloc] init];
    login.username = username;
    login.password = password;
    
    return login;
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{   
    [[MSLNetworkingClient sharedClient] getRequestWithURL:[self loginURL] cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {
            
            MSLIkanoBankLoginParser *loginParser = [[MSLIkanoBankLoginParser alloc] init];
            NSError *error = nil;
            
            if ([loginParser parseXMLData:requestOperation.responseData parseError:&error] &&
                loginParser.ssnFieldName && loginParser.passwordFieldName) {
                // Add all the hidden fields we parsed from the login-page
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:loginParser.hiddenFields];
                [dict setValue:self.username forKey:loginParser.ssnFieldName];
                [dict setValue:self.password forKey:loginParser.passwordFieldName];
                
                [[MSLNetworkingClient sharedClient] postRequestWithURL:[self loginURL] andParameters:dict cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                    if ([requestOperation.responseString rangeOfString:@"Logout"].location != NSNotFound || 
                        [requestOperation.responseString rangeOfString:@"Logga ut"].location != NSNotFound) {
                        self.loginResponse = requestOperation.responseString;
                        [self callSuccessBlock:success];
                    }
                    else {
                        [self callFailureBlock:failure withError:nil andMessage:@"BankLoginDeniedAlert"];
                    }
                }];
            }
            else {
                if ([requestOperation.responseString rangeOfString:@"Banken är stängd"].location != NSNotFound) {
                    [self callFailureBlock:failure withError:nil andMessage:@"Tyvärr, Ikanobanken är stängd för tillfället. Försök igen senare."];
                }
                else {
                    [self callFailureBlock:failure withError:nil andMessage:@"BankLoginFailureAlert"];
                }
            }
        }
        else {
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
}

- (NSData *)manipulateAccountBalanceResponse:(NSData *)html
{
    NSMutableString *htmlString = [[NSMutableString alloc] initWithData:html encoding:NSUTF8StringEncoding];
    [htmlString replaceOccurrencesOfString:@"<span>Dina sparkonton</span>" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [htmlString length])];
    return [htmlString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
}

- (void)fetchAccountBalance:(void (^)(NSArray *))success failure:(MSLServiceFailureBlock)failure
{
    NSString *fixedHtml = [self.loginResponse stringByReplacingOccurrencesOfString:@"<span>Dina sparkonton</span>" withString:@""];
    NSData *htmlData = [fixedHtml dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
            
    MSLAccountsParserBase *parser = [self accountsParser];
    NSError *parseError = nil;
    [parser parseXMLData:htmlData parseError:&parseError];
    if ([parser.parsedAccounts count] > 0) {
        if (success) {
            success(parser.parsedAccounts);
        }
    }
    else {
        debug_NSLog(@"Login response: %@\r\n\r\n", self.loginResponse);
        [self callFailureBlock:failure withError:nil andMessage:@"Kunde inte läsa ut saldoinformationen"];
    }
}


#pragma mark - Accessors

- (id)accountsParser
{
    return [[MSLIkanoBankAccountParser alloc] init];
}

- (NSURL *)loginURL
{
    return [NSURL URLWithString:kMSIkanoLoginURL];
}

- (NSURL *)transferFundsURL
{
    return [NSURL URLWithString:kMSIkanoTransferFundsURL];
}

- (NSURL *)accountsListURL
{
    return [NSURL URLWithString:kMSIkanoAccountListURL];
}

@end
