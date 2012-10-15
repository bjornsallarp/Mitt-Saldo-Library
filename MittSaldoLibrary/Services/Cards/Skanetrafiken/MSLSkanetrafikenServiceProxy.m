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

#import "MSLSkanetrafikenServiceProxy.h"
#import "MSLNetworkingClient.h"
#import "MSLParsedAccount.h"

NSString * const kMSSkanetrafikenLoginURL = @"https://www.skanetrafiken.se/templates/MSRootPage.aspx?id=2935&epslanguage=SV";
NSString * const kMSSkanetrafikenBalanceURL = @"https://www.skanetrafiken.se/templates/CardInformation.aspx?id=26957&epslanguage=SV";

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@implementation MSLSkanetrafikenServiceProxy


+ (MSLSkanetrafikenServiceProxy *)proxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MSLSkanetrafikenServiceProxy *login = [[self alloc] init];
    login.username = username;
    login.password = password;
    
    return login;
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    [[MSLNetworkingClient sharedClient] getRequestWithURL:[NSURL URLWithString:kMSSkanetrafikenLoginURL] cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        
        if (requestOperation.hasAcceptableStatusCode) {
            
            NSString *viewState = [self parseViewstateValueFromHTML:requestOperation.responseString];
            
            NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
            [loginParams setValue:self.username forKey:@"ctl00$fullRegion$menuRegion$Login$UsernameTextBox"];
            [loginParams setValue:self.password forKey:@"ctl00$fullRegion$menuRegion$Login$PasswordTextBox"];
            [loginParams setValue:@"Logga in" forKey:@"ctl00$fullRegion$menuRegion$Login$LoginButton"];
            [loginParams setValue:@"" forKey:@"ctl00$fullRegion$quicksearch$SearchText"];
            [loginParams setValue:@"" forKey:@"__EVENTARGUMENT"];
            [loginParams setValue:@"" forKey:@"__EVENTTARGET"];
            [loginParams setValue:viewState forKey:@"__VIEWSTATE"];
            
            [[MSLNetworkingClient sharedClient] postRequestWithURL:[NSURL URLWithString:kMSSkanetrafikenLoginURL] andParameters:loginParams cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                
                if (![requestOperation.response.URL isEqual:[NSURL URLWithString:kMSSkanetrafikenLoginURL]]) {
                    [self callSuccessBlock:success];
                }
                else if (failure) {
                    debug_NSLog(@"%@", requestOperation.responseString);
                    [self callFailureBlock:failure withError:nil andMessage:@"BankLoginDeniedAlert"];
                }
            }];
        }
        else if (failure) {
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
    
}

- (void)fetchAccountBalance:(void(^)(NSArray *accounts))success failure:(MSLServiceFailureBlock)failure
{
    [[MSLNetworkingClient sharedClient] getRequestWithURL:[NSURL URLWithString:kMSSkanetrafikenBalanceURL] cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        
        if (!requestOperation.hasAcceptableStatusCode) {
            debug_NSLog(@"Response: %@", requestOperation.responseString);
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
            return;
        }
                    
        if ([requestOperation.responseString rangeOfString:@"ctl00$fullRegion$mainRegion$CardInformation1$mRepeaterMyCards$ctl01$LinkButton1"].location == NSNotFound) {
            failure(nil, @"Du har inga jojo-kort registrerade under 'Mina Jojo-kort' på skanetrafiken.se");
            return;
        }
                    
        NSString *viewState = [self parseViewstateValueFromHTML:requestOperation.responseString];
        NSMutableDictionary *postDict = [NSMutableDictionary dictionary];
        [postDict setValue:viewState forKey:@"__VIEWSTATE"];
        [postDict setValue:@"" forKey:@"ctl00$fullRegion$quicksearch$SearchText"];
        [postDict setValue:@"ctl00$fullRegion$mainRegion$CardInformation1$mRepeaterMyCards$ctl01$LinkButton1" forKey:@"__EVENTTARGET"];
            
        [[MSLNetworkingClient sharedClient] postRequestWithURL:requestOperation.response.URL andParameters:postDict cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
            
            if (!requestOperation.hasAcceptableStatusCode) {
                debug_NSLog(@"Response: %@", requestOperation.responseString);
                [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
                return;
            }
            
            
            if ([requestOperation.responseString rangeOfString:@"ctl00$fullRegion$mainRegion$CardInformation1$mDropDownChooseCard"].location == NSNotFound) {
                failure(nil, @"Det gick tyvärr inte att läsa ut kortinformationen");
                return;
            }
            
            NSMutableArray *accountDetailDictionaries = [NSMutableArray array];
            self.accountDetailDictionaries = accountDetailDictionaries;
            
            NSDictionary *firstAcccountDict = [self parseAccountDataFromHTML:requestOperation.responseString];
            [accountDetailDictionaries addObject:firstAcccountDict];
            
            MSLParsedAccount *firstAccount = [self parsedAccountFromDictionary:firstAcccountDict];
            NSMutableArray *parsedAccounts = [NSMutableArray arrayWithObject:firstAccount];
            NSArray *accountIds = [self parseAccountDropdownFromHTML:requestOperation.responseString];
            
            if ([accountIds count] == 1U) {
                if (success) {
                    success(parsedAccounts);
                }
                
                return;
            }

            for (NSString *accountId in accountIds) {
                
                // No need to fetch the account we already got with the first request.
                if ([accountId isEqualToString:[firstAcccountDict valueForKey:@"accountid"]])
                    continue;
                
                NSMutableDictionary *nextAccountParams = [NSMutableDictionary dictionary];
                [nextAccountParams setValue:[self parseViewstateValueFromHTML:requestOperation.responseString] forKey:@"__VIEWSTATE"];
                [nextAccountParams setValue:@"" forKey:@"__EVENTARGUMENT"];
                [nextAccountParams setValue:@"" forKey:@"__EVENTTARGET"];
                [nextAccountParams setValue:@"" forKey:@"ctl00$fullRegion$quicksearch$SearchText"];
                [nextAccountParams setValue:@"Välj" forKey:@"ctl00$fullRegion$mainRegion$CardInformation1$mButtonChooseCard"];
                [nextAccountParams setValue:accountId forKey:@"ctl00$fullRegion$mainRegion$CardInformation1$mDropDownChooseCard"];
                
                [[MSLNetworkingClient sharedClient] postRequestWithURL:requestOperation.response.URL andParameters:nextAccountParams cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                    
                    if (!requestOperation.hasAcceptableStatusCode) {
                        debug_NSLog(@"Response: %@", requestOperation.responseString);
                        [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
                        return;
                    }
                    
                    NSDictionary *accountInfoDict = [self parseAccountDataFromHTML:requestOperation.responseString];
                    [accountDetailDictionaries addObject:accountInfoDict];
                    
                    MSLParsedAccount *account = [self parsedAccountFromDictionary:accountInfoDict];
                    [parsedAccounts addObject:account];
                    
                    if ([parsedAccounts count] == [accountIds count] && success) {
                        success(parsedAccounts);
                    }
                }];
            }
        }];
    }];
}


- (MSLParsedAccount *)parsedAccountFromDictionary:(NSDictionary *)accountData
{
    long long accountId = [[accountData valueForKey:@"accountid"] longLongValue];
    
    // the ids can be rather large, this *should* be safe. The chance of two
    // accounts colliding is incredible small, but still possible.
    while (accountId > INT_MAX)
        accountId /= 2;
    
    MSLParsedAccount *account = [[MSLParsedAccount alloc] init];  
    account.accountName = [accountData valueForKey:@"name"];
    account.accountId = @((int)accountId);
    [account setAmountWithString:[accountData valueForKey:@"balance"]];
    
    return account;
}

- (NSString *)parseViewstateValueFromHTML:(NSString *)html
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"__VIEWSTATE\"\\s+value=\"([^\"]+)\""
                                  options:0
                                  error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:html options:0 range:NSMakeRange(0, [html length])];
    NSString *result = [html substringWithRange:[match rangeAtIndex:1]];
    
    return result;
}

- (NSArray *)parseAccountDropdownFromHTML:(NSString *)html
{
    NSError  *error  = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"<option.+value=\"([^\"]+)\">(.+)</option>"
                                  options:0
                                  error:&error];
    
    NSArray *matches = [regex matchesInString:html options:0 range:NSMakeRange(0, [html length])];
    
    NSMutableArray *accountIds = [NSMutableArray array];
    for (NSTextCheckingResult *match in matches) {
        NSString *accountId = [html substringWithRange:[match rangeAtIndex:1]];
        [accountIds addObject:accountId];
    }
    
    return accountIds;
}

- (NSDictionary *)parseAccountDataFromHTML:(NSString *)html
{
    NSError *error = NULL;
    NSMutableDictionary *details = [NSMutableDictionary dictionary];

    NSDictionary *regexDict = @{@"balance": @"labelsaldoinfo\">(.+)</span>",
                               @"name": @"labelCardName\".+>(.+)</span>",
                               @"accountid": @"labelcardnumberinfo\">(.+)</span>",
                               @"status": @"labelstatusinfo\">(.+)</span>",
                               @"validPeriod": @"labelvalidperiodinfo\">(.+)</span>",
                               @"validzones": @"labelzoneareainfozones\">(.+)</span>"};
    
    for (NSString *regexKey in regexDict) {
        
        NSRegularExpression *regex = [NSRegularExpression
                                      regularExpressionWithPattern:[regexDict valueForKey:regexKey]
                                      options:0
                                      error:&error];
        NSTextCheckingResult *match = [regex firstMatchInString:html options:0 range:NSMakeRange(0, [html length])];
        
        NSString *regexValue = [html substringWithRange:[match rangeAtIndex:1]];
        [details setValue:regexValue forKey:regexKey];
    }
        
    return details;
}

@end
