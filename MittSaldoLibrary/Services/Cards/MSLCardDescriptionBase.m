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

#import "MSLCardDescriptionBase.h"

@implementation MSLCardDescriptionBase

- (NSString *)serviceIdentifier
{
    NSLog(@"Not implemented metod: serviceIdentifier");
    exit(1);
}

- (NSString *)serviceName
{
    return [self serviceIdentifier];
}

- (BOOL)isBank
{
    return NO;
}

- (BOOL)isCard
{
    return YES;
}

- (BOOL)isNumericOnlyUsername
{
    return NO;
}

- (NSString *)usernameCaption
{
    return @"Anv.namn";
}

- (NSString *)passwordCaption
{
    return @"Lösen";
}

@end
