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

#import "MSLServiceProxyBase.h"
#import "MSLAccountsParserBase.h"
#import "MSLNetworkingClient.h"

@implementation MSLServiceProxyBase
@dynamic loginURL;
@dynamic transferFundsURL;
@dynamic accountsListURL;
@dynamic accountsParser;

- (id)init
{
    if ((self = [super init])) {
        self.cookieStorage = [NSMutableArray array];
    }
    
    return self;
}

- (void)fetchAccountBalance:(void(^)(NSArray *accounts))success failure:(MSLServiceFailureBlock)failure
{
    [[MSLNetworkingClient sharedClient] getRequestWithURL:[self accountsListURL] cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        
        if ([requestOperation hasAcceptableStatusCode]) {
            
            NSData *responseData = requestOperation.responseData;
            if ([self respondsToSelector:@selector(manipulateAccountBalanceResponse:)]) {
                responseData = [self performSelector:@selector(manipulateAccountBalanceResponse:) withObject:responseData];
            }
            
            MSLAccountsParserBase *parser = [self accountsParser];
            NSError *parseError = nil;
            [parser parseXMLData:responseData parseError:&parseError];
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
        }
        else if (failure) {
            failure(error, nil);
        }
    }];
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    NSLog(@"%@ needs to implement performLoginWithSuccessBlock:", self);
    exit(-1);
}

- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message
{
    if (failureBlock) {
        failureBlock(error, message);
    }
}

- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock
{
    if (successBlock) {
        successBlock();
    }
}

@end
