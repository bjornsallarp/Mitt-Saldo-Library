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

#import "MSLHandelsbankenAccountParser.h"
#import "MSLParsedAccount.h"

@interface MSLHandelsbankenAccountParser()
@property (nonatomic, strong) MSLParsedAccount *currentAccount;
@property (nonatomic, strong) NSMutableString *elementInnerContent;
@end

@implementation MSLHandelsbankenAccountParser
@dynamic elementInnerContent;
@dynamic currentAccount;

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
	attributes:(NSDictionary *)attributeDict
{
	if (qName) {
        elementName = qName;
    }
	
	
	// These are the elements we read information from.
	if ([elementName isEqualToString:@"ul"]) {
		if ([[attributeDict valueForKey:@"class"] isEqualToString:@"link-list"]) {
			isParsingAccounts = YES;
		}	
	}
	else if (isParsingAccounts == YES && [elementName isEqualToString:@"a"]) {
		isParsingAccount = YES;
        self.currentAccount = [[MSLParsedAccount alloc] init];
        self.currentAccount.accountId = @((int)[self.parsedAccounts count]);
		
		self.elementInnerContent = [NSMutableString string];
	}
	else if (isParsingAccount && [elementName isEqualToString:@"span"] && [attributeDict valueForKey:@"class"] == nil) {
		isParsingName = YES;
		self.elementInnerContent = [NSMutableString string];
	}
	else if (isParsingAccount && [elementName isEqualToString:@"span"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"link-list-right"]) {
		isParsingAmount = YES;
		self.elementInnerContent = [NSMutableString string];
	}
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
    
	
	if ([elementName isEqualToString:@"ul"] && isParsingAccounts) {
		isParsingAccounts = NO;
	}
	else if([elementName isEqualToString:@"a"] && isParsingAccount) {
		isParsingAccount = NO;
		isParsingAmount = NO;
		isParsingName = NO;
		
		debug_NSLog(@"%@. %@ -> %@ kr", self.currentAccount.accountId, self.currentAccount.accountName, self.currentAccount.amount);
		
        [self.parsedAccounts addObject:self.currentAccount];
        self.currentAccount = nil;
	}
	else if ([elementName isEqualToString:@"span"] && isParsingAmount) {
		// Replace SEK
		NSString *amountString = [self.elementInnerContent stringByReplacingOccurrencesOfString:@"SEK" withString:@""];

		// Trim all crap characters..
		amountString = [amountString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t\n "]];
		
		NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		[f setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"sv_SE"]];
		[self.currentAccount setAmount:[f numberFromString:[amountString stringByReplacingOccurrencesOfString:@" " withString:@""]]];		
		
		isParsingAmount = NO;
	}
	else if ([elementName isEqualToString:@"span"] && isParsingName) {
		NSString *accountName = [self.elementInnerContent stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t\n "]];
		accountName = [accountName stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        self.currentAccount.accountName = accountName;
		isParsingName = NO;
	}
	
}

@end
