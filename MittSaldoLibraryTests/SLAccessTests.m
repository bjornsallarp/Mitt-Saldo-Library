//
//  SLAccessTests.m
//  MittSaldoLibrary
//
//  Created by Björn Sållarp on 2/17/13.
//  Copyright (c) 2013 Björn Sållarp. All rights reserved.
//

#import "SLAccessTests.h"
#import "MSLHiddenInputsParser.h"

@implementation SLAccessTests

- (void)testLoginParser
{
    MSLHiddenInputsParser *parser = [[MSLHiddenInputsParser alloc] init];
      
    NSData *htmlData = [self dataForFileWithName:@"slaccess-login"];

    NSError *error;
    [parser parseXMLData:htmlData parseError:&error];
    
    STAssertNil(error, @"Parsing should not trigger errors");
    
    STAssertEquals(3U, [parser.hiddenFields count], nil);
    STAssertEqualObjects([parser.hiddenFields valueForKey:@"__EVENTVALIDATION"], @"/wEWBALO7/S1BwKH7OmICALPwdD+AQLs/IyWBQa9GlnQfO8MbBmgkSZ/2XKtcPP9", nil);
    STAssertEqualObjects([parser.hiddenFields valueForKey:@"__VIEWSTATE"], @"/wEPDwUJMzA4NjM4MjQ3ZGS6FKdxhpnl3HIrv3v8bYWYSJrKFw==", nil);
    STAssertEqualObjects([parser.hiddenFields valueForKey:@"viewmode"], @"mobile", nil);
}

- (NSData *)dataForFileWithName:(NSString *)file
{
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:@"html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
    return htmlData;
}

@end
