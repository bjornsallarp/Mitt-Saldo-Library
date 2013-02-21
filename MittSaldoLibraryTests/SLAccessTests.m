//
//  SLAccessTests.m
//  MittSaldoLibrary
//
//  Created by Björn Sållarp on 2/17/13.
//  Copyright (c) 2013 Björn Sållarp. All rights reserved.
//

#import "SLAccessTests.h"
#import "MSLSLAccessLoginParser.h"

@implementation SLAccessTests

- (void)testLoginParser
{
    MSLSLAccessLoginParser *parser = [[MSLSLAccessLoginParser alloc] init];
      
    NSData *htmlData = [self dataForFileWithName:@"slaccess-login"];
    NSString *htmlMarkup = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];

    [parser parseHtmlString:htmlMarkup];
    
    STAssertEquals(3U, [parser.hiddenFields count], nil);
    STAssertEqualObjects([parser.hiddenFields valueForKey:@"__EVENTVALIDATION"], @"/wEWBALO7/S1BwKH7OmICALPwdD+AQLs/IyWBQa9GlnQfO8MbBmgkSZ/2XKtcPP9", nil);
    STAssertEqualObjects([parser.hiddenFields valueForKey:@"__VIEWSTATE"], @"/wEPDwUJMzA4NjM4MjQ3ZGS6FKdxhpnl3HIrv3v8bYWYSJrKFw==", nil);
    STAssertEqualObjects([parser.hiddenFields valueForKey:@"viewmode"], @"mobile", nil);
    
    STAssertEqualObjects(parser.ssnFieldName, @"ctl00$MainPlaceHolder$ctl00$UsernameTextBox", nil);
    STAssertEqualObjects(parser.passwordFieldName, @"ctl00$MainPlaceHolder$ctl00$PasswordTextBox", nil);
}

- (NSData *)dataForFileWithName:(NSString *)file
{
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:@"html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
    return htmlData;
}

@end
