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

@interface MSLParsedAccount : NSObject
@property (nonatomic, strong) NSNumber *accountId;
@property (nonatomic, strong) NSNumber *amount;
@property (nonatomic, strong) NSNumber *availableAmount;
@property (nonatomic, strong) NSString *accountName;

- (void)setAmountWithString:(NSString *)stringValue;
- (void)setAvailableAmountWithString:(NSString *)stringValue;
@end
