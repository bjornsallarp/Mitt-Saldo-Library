//
//  ICABankenTests.m
//  MittSaldoLibrary
//
//  Created by Björn Sållarp on 2/13/13.
//  Copyright (c) 2013 Björn Sållarp. All rights reserved.
//

#import "ICABankenTests.h"
#import "MSLICABankenLoginParser.h"

@implementation ICABankenTests

- (void)testICALoginParser
{
    MSLICABankenLoginParser *parser = [[MSLICABankenLoginParser alloc] init];
    
    NSError *error = nil;
    
    NSData *htmlData = [self dataForFileWithName:@"icabanken-login"];
    NSString *fixedMarkup = [[[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"&" withString:@""];
    
    [parser parseXMLData:[fixedMarkup dataUsingEncoding:NSUTF8StringEncoding] parseError:&error];
    
    STAssertEqualObjects(@"ctl00$MainRegion$CustomerId$txt", parser.ssnFieldName, @"");
    STAssertEqualObjects(@"ctl00$MainRegion$PinCode$txt", parser.passwordFieldName, @"");
}

- (NSData *)dataForFileWithName:(NSString *)file
{
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:@"html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
    return htmlData;
}

@end
