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

#import <Foundation/Foundation.h>

@class MSLAccountsParserBase;

typedef void (^MSLServiceSimpleBlock)();
typedef void (^MSLServiceFailureBlock)(NSError *error, NSString *errorMessage);

@interface MSLServiceProxyBase : NSObject
@property (nonatomic, strong) NSMutableArray *cookieStorage;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

@property (weak, nonatomic, readonly) NSURL *loginURL;
@property (weak, nonatomic, readonly) NSURL *transferFundsURL;
@property (weak, nonatomic, readonly) NSURL *accountsListURL;
@property (weak, nonatomic, readonly) MSLAccountsParserBase *accountsParser;

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure;
- (void)fetchAccountBalance:(void(^)(NSArray *accounts))success failure:(MSLServiceFailureBlock)failure;
- (NSData *)cleanStringFromJavascript:(NSString *)html;

@end
