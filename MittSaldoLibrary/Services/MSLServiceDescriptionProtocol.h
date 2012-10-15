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

@class MSLServiceProxyBase;

@protocol MSLServiceDescriptionProtocol <NSObject>
@required
- (NSString *)serviceIdentifier;
- (NSString *)serviceName;
- (MSLServiceProxyBase *)serviceProxyWithUsername:(NSString *)username andPassword:(NSString *)password;
- (BOOL)isBank;
- (BOOL)isCard;
- (BOOL)isNumericOnlyUsername;
- (BOOL)isValidUsernameForService:(NSString *)username validationMessage:(NSString **)message;
- (BOOL)isValidPasswordForService:(NSString *)password validationMessage:(NSString **)message;
- (NSString *)usernameCaption;
- (NSString *)passwordCaption;
@end
