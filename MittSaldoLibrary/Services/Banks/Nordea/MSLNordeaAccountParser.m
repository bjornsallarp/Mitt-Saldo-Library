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

#import "MSLNordeaAccountParser.h"
#import "MSLParsedAccount.h"

@interface MSLNordeaAccountParser()
@property (nonatomic, strong) MSLParsedAccount *currentAccount;
@property (nonatomic, strong) NSMutableString *elementInnerContent;
@end

@implementation MSLNordeaAccountParser
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
	if ([elementName isEqualToString:@"ul"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"list"]) {
		isParsingAccounts = YES;
	}
	else if (isParsingAccounts && [elementName isEqualToString:@"a"]) {

        self.currentAccount = [[MSLParsedAccount alloc] init];

        NSString *accountUrl = [attributeDict valueForKey:@"href"];
		NSString *accountId = [accountUrl substringFromIndex:[accountUrl rangeOfString:@":"].location+1];
        
		NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		
		self.currentAccount.accountId = [f numberFromString:accountId];
        self.elementInnerContent = [NSMutableString string];
	}
	else if (self.currentAccount && [elementName isEqualToString:@"span"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"linkinfoRight"]) { 
        NSString *accountName = [self.elementInnerContent stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t\n "]];
        accountName = [accountName stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        self.currentAccount.accountName = accountName;
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
	else if ([elementName isEqualToString:@"a"] && self.currentAccount) {		
		debug_NSLog(@"%@. %@ -> %@ kr", self.currentAccount.accountId, self.currentAccount.accountName, self.currentAccount.amount);
		
        [self.parsedAccounts addObject:self.currentAccount];
        self.currentAccount = nil;
	}
	else if([elementName isEqualToString:@"span"] && isParsingAmount)
	{
		[self.currentAccount setAmountWithString:self.elementInnerContent];
		isParsingAmount = NO;
	}
}

- (NSStringEncoding)sourceStringEncoding
{
    return NSISOLatin1StringEncoding;
}

- (NSStringEncoding)dataStringEncoding
{
    return NSISOLatin1StringEncoding;
}

@end
