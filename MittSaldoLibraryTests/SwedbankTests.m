//
//  SwedbankTests.m
//  MittSaldoLibrary
//
//  Created by Björn Sållarp on 9/15/12.
//  Copyright (c) 2012 Björn Sållarp. All rights reserved.
//

#import "SwedbankTests.h"
#import "MSLSwedbankAccountParser.h"
#import "MSLSwedbankLoginParser.h"
#import "MSLSwedbankServiceProxy.h"
#import "MSLParsedAccount.h"
#import "NSString+MSLHtmlStripScriptTag.h"

@implementation SwedbankTests

- (void)testAccountParser
{
    MSLSwedbankAccountParser *parser = [[MSLSwedbankAccountParser alloc] init];
    
    NSData *accountDetailsData = [self dataForFileWithName:@"swedbank-account-list"];
    
    NSError *error = nil;
    [parser parseXMLData:accountDetailsData parseError:&error];

    STAssertTrue([parser.parsedAccounts count] > 0, @"At least one account should have been parsed!");
    
    for (MSLParsedAccount *account in parser.parsedAccounts) {
        STAssertNotNil(account.accountId, @"Account id cannot be nil");
        STAssertNotNil(account.accountName, @"Account name cannot be nil");
        STAssertNotNil(account.amount, @"Amount cannot be nil");
    }
}

- (NSData *)dataForFileWithName:(NSString *)file
{
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:file ofType:@"html"];
    NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
    return htmlData;
}

- (void)testCSRParser
{
    MSLSwedbankLoginParser *loginParser = [[MSLSwedbankLoginParser alloc] init];
    
    NSData *loginPageData = [self dataForFileWithName:@"swedbank-login-step1"];
    NSString *html = [[NSString alloc] initWithData:loginPageData encoding:NSUTF8StringEncoding];
    
    NSData *cleanLoginPageData = [html cleanStringFromJavascriptWithEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    [loginParser parseXMLData:cleanLoginPageData parseError:&error];
    
    STAssertEqualObjects(loginParser.csrf_token, @"Rhl51Wejy9n3cJjtp3Q-F1dzPQiL8doMU76cKzKZX-I", @"CSRF token is invalid");
    
    STAssertNil(error, @"There should be no errors");
}

@end
