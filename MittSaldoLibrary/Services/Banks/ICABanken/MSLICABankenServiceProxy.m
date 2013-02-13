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

#import "MSLICABankenServiceProxy.h"
#import "MSLICABankenLoginParser.h"
#import "MSLICABankenAccountParser.h"
#import "MSLNetworkingClient.h"

NSString * const kMSICABankenLoginURL = @"https://mobil.icabanken.se/logga-in/";
NSString * const kMSICABankenTransferFundsURL = @"https://mobil.icabanken.se/overfor/";
NSString * const kMSICABankenAccountListURL = @"https://mobil.icabanken.se/konton/";

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@interface MSLICABankenServiceProxy ()
@property (nonatomic, assign) BOOL authenticationRetry;
@property (nonatomic, strong) MSLICABankenLoginParser *loginParser;
@end

@implementation MSLICABankenServiceProxy

- (id)init 
{
    if ((self = [super init])) {
        self.isIPAD = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    }
    
    return self;
}

+ (id)proxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MSLICABankenServiceProxy *login = [[self alloc] init];
    login.username = username;
    login.password = password;
    
    return login;
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    if ([self.username length] != 12) {
        failure(nil, @"Ditt personnummer innehåller inte 12 siffror. Nya krav från ICA! Uppdatera personnummer under 'Inställningar'");
        return;
    }
    
    NSURL *loginUrl = [self loginURL];
    
    // ICA wants to warn iPad users that the site might not be working as expected. This will bypass that warning
    if (self.isIPAD) {
        NSMutableDictionary *cookieDict = [NSMutableDictionary dictionaryWithCapacity:5];
        [cookieDict setValue:@"ICA Banken Temporary" forKey:NSHTTPCookieName];
        [cookieDict setValue:[NSDate dateWithTimeIntervalSinceNow:86400] forKey:NSHTTPCookieExpires];
        [cookieDict setValue:@"1=1&4=0" forKey:NSHTTPCookieValue];
        [cookieDict setValue:@"/" forKey:NSHTTPCookiePath];
        [cookieDict setValue:[loginUrl host] forKey:NSHTTPCookieDomain];       
        [self.cookieStorage addObject:[NSHTTPCookie cookieWithProperties:cookieDict]];
    }
    
    [[MSLNetworkingClient sharedClient] getRequestWithURL:loginUrl cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {
            
            // The response is HTML, not XHTML. In order for the parser not to choke we simply remove the &-characters
            NSString *fixedMarkup = [requestOperation.responseString stringByReplacingOccurrencesOfString:@"&" withString:@""];
            
            NSError *error = nil;
            self.loginParser = [[MSLICABankenLoginParser alloc] init];
            if ([self.loginParser parseXMLData:[fixedMarkup dataUsingEncoding:NSUTF8StringEncoding] parseError:&error] &&
                self.loginParser.ssnFieldName && self.loginParser.passwordFieldName) {
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
    [params setValue:self.username forKey:self.loginParser.ssnFieldName];
    [params setValue:self.password forKey:self.loginParser.passwordFieldName];
    // Do we support javascript? Of course we do!
    [params setValue:@"1" forKey:@"JSEnabled"];
    
    NSURL *postUrl = [NSURL URLWithString:kMSICABankenLoginURL];
    [[MSLNetworkingClient sharedClient] postRequestWithURL:postUrl andParameters:params cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {
            
            // ICA Banken moves the user to a new page if login succeded, if we are still on the login
            // page after posting successfully the login failed
            if ([[requestOperation.response.URL absoluteString] isEqualToString:[postUrl absoluteString]]) {
                if ([requestOperation.responseString rangeOfString:@"två aktiva sessioner"].location != NSNotFound && !self.authenticationRetry) {
                    /* 
                     if we got the error message about two active sessions the login actually worked but a session was 
                     already active, so we were instead logged out. This can happen if you're logged in with your PC but
                     is most likely to happen if you use the app, close it (cookies cleared), open it and authenticate.
                     We know the authentication was actually correct when we get this message, so we rewind and authenticate agan.
                     The flag is there to make sure we don't end up in a crazy loop. The chance is slim but better safe than sorry, right? 
                     */
                    self.authenticationRetry = YES;
                    self.cookieStorage = [NSMutableArray array];
                    
                    [self performLoginWithSuccessBlock:success failure:failure];
                }
                else {
                    [self callFailureBlock:failure withError:nil andMessage:@"BankLoginDeniedAlert"];
                }
            }
            else if ([requestOperation.responseString rangeOfString:@"Något har blivit fel"].location != NSNotFound) {
                [self callFailureBlock:failure withError:nil andMessage:@"Ett fel har uppstått i ICA Bankens tjänst. Försök igen senare och om det inte löser sig så kontakta ICA Banken och be dem felsöka problemet."];
            }
            else if ([requestOperation.responseString rangeOfString:@"Logga in"].location != NSNotFound) {
                [self callFailureBlock:failure withError:nil andMessage:@"BankLoginDeniedAlert"];
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

#pragma mark - Accessors

- (id)accountsParser
{
    return [[MSLICABankenAccountParser alloc] init];
}

- (NSURL *)loginURL
{
    return [NSURL URLWithString:kMSICABankenLoginURL];
}

- (NSURL *)transferFundsURL
{
    return [NSURL URLWithString:kMSICABankenTransferFundsURL];
}

- (NSURL *)accountsListURL
{
    return [NSURL URLWithString:kMSICABankenAccountListURL];
}

@end
