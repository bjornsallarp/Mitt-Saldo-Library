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

@interface MSLTicketRikskortetTransaction : NSObject
@property (nonatomic, strong) NSString *transactionId;
@property (nonatomic, strong) NSString *cardAcceptor;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *amount;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *type;
@end
