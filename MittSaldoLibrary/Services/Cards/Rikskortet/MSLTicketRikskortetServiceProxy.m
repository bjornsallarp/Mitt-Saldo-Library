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

#import "MSLTicketRikskortetServiceProxy.h"
#import "MSNetworkingClient.h"
#import "MSLParsedAccount.h"
#import "MSLTicketRikskortetLoginParser.h"
#import "MSLParsedAccount.h"

NSString * const kMSTicketRikskortetLoginURL = @"https://www.edenred.se/MobileWS/MobileWS.asmx";

@interface MSLTicketRikskortetServiceProxy ()
@property (nonatomic, strong) NSData *soapResponseData;
@end

@implementation MSLTicketRikskortetServiceProxy


+ (MSLTicketRikskortetServiceProxy *)proxyWithUsername:(NSString *)username andPassword:(NSString *)password;
{
    MSLTicketRikskortetServiceProxy *login = [[self alloc] init];
    login.username = username;
    login.password = password;

    return login;
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{   
    NSString *soapRequest = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?><soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns=\"http://edenred.se/\"><soap:Body><GetAccountDetails><login>%@</login><password>%@</password></GetAccountDetails></soap:Body></soap:Envelope>", self.username, self.password];
    
    [[MSLNetworkingClient sharedClient] postSoapRequestWithURL:[NSURL URLWithString:kMSTicketRikskortetLoginURL] andSoapAction:@"http://edenred.se/GetAccountDetails" soapBody:soapRequest cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        
        self.soapResponseData = requestOperation.responseData;
        NSString *soapResponse = requestOperation.responseString;
        
        if ([soapResponse rangeOfString:@"<ErrorCode>1</ErrorCode>"].location != NSNotFound) {
            if (success) {
                success();
            }
        }
        else if (failure) {
            failure(nil, @"BankLoginDeniedAlert");
        }
    }];
}

- (void)fetchAccountBalance:(void(^)(NSArray *accounts))success failure:(MSLServiceFailureBlock)failure
{
    MSLTicketRikskortetLoginParser *parser = [[MSLTicketRikskortetLoginParser alloc] init];
    
    NSError *parseError = nil;
    [parser parseXMLData:self.soapResponseData parseError:&parseError];
    
    if (!parseError) {
        self.transactions = parser.transactions;
        
        MSLParsedAccount *account = [[MSLParsedAccount alloc] init];
        account.accountName = @"Rikskortet";
        account.amount = @(parser.balance);
        account.accountId = @0;
        
        if (success) {
            success(@[account]);
        }        
    }
    else if (failure) {
        failure(nil, @"Kunde inte läsa ut saldoinformationen");
    }
}

@end
