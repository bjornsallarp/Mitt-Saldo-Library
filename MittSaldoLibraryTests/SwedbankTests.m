//
//  SwedbankTests.m
//  MittSaldoLibrary
//
//  Created by Björn Sållarp on 9/15/12.
//  Copyright (c) 2012 Björn Sållarp. All rights reserved.
//

#import "SwedbankTests.h"
#import "MSLSwedbankAccountParser.h"
#import "MSLParsedAccount.h"

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

@end
