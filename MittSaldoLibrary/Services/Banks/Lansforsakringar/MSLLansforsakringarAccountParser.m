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

#import "MSLLansforsakringarAccountParser.h"
#import "MSLParsedAccount.h"

@interface MSLLansforsakringarAccountParser()
@property (nonatomic, strong) MSLParsedAccount *currentAccount;
@property (nonatomic, strong) NSMutableString *elementInnerContent;
@end

@implementation MSLLansforsakringarAccountParser
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
	if ([elementName isEqualToString:@"form"] && [[attributeDict valueForKey:@"id"] isEqualToString:@"paymentAcccountsAndCards"]) {
		accountsParsed = 0;
		
		isParsingPayAccounts = YES;
		isParsingSavingsAccounts = isParsingAccount = isParsingAmount = NO;
	} 
	else if ([elementName isEqualToString:@"form"] && [[attributeDict valueForKey:@"id"] isEqualToString:@"savingsAccountsForm"]) {
		isParsingSavingsAccounts = YES;
		isParsingPayAccounts = isParsingAccount = isParsingAmount = NO;		
		
		// We start at 1000, it's unlikely someone will have 1000+ pay accounts
		savingsAccountsParsed = 1000;
	}
	else if ((isParsingSavingsAccounts || isParsingPayAccounts) && 
			[elementName isEqualToString:@"tr"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"clickable"]) {
		isParsingAccount = YES;
		isParsingAmount = NO;
        self.elementInnerContent = [NSMutableString string];
	}
	else if (isParsingAccount && [elementName isEqualToString:@"td"] && [[attributeDict valueForKey:@"colspan"] isEqualToString:@"2"]) {
		isParsingAccount = NO;
	}
	else if (isParsingAccount && [elementName isEqualToString:@"td"] && !isParsingAmount) {

        self.currentAccount = [[MSLParsedAccount alloc] init];
        self.currentAccount.accountId = @(isParsingPayAccounts ? accountsParsed : savingsAccountsParsed);
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
    
	if (isParsingAccount && [elementName isEqualToString:@"tr"]) {
		isParsingAccount = isParsingAmount = NO;
	}
	else if ([elementName isEqualToString:@"form"]) {
		isParsingPayAccounts = isParsingSavingsAccounts = NO;
	}
	else if (isParsingAccount && isParsingAmount && [elementName isEqualToString:@"td"]) {
		NSString *amountString = [self.elementInnerContent stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t\n "]];
		amountString = [amountString stringByReplacingOccurrencesOfString:@" " withString:@""];
		amountString = [amountString stringByReplacingOccurrencesOfString:@"." withString:@""];
		
		NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
		[f setNumberStyle:NSNumberFormatterDecimalStyle];
		[f setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"sv_SE"]];
		
        self.currentAccount.amount = [f numberFromString:amountString];
		
		
		
		debug_NSLog(@"%@. %@ -> %@ kr.", self.currentAccount.accountId, self.currentAccount.accountName, self.currentAccount.amount);
		
		if (isParsingPayAccounts) {
			accountsParsed++;
		}
		else if (isParsingSavingsAccounts) {
			savingsAccountsParsed++;
		}
		
        [self.parsedAccounts addObject:self.currentAccount];
        self.currentAccount = nil;
        
		// After the amount we're not parsing more
		isParsingAmount = NO;
		isParsingAccount = NO;
        self.elementInnerContent = nil;
	}
	else if (isParsingAccount && [elementName isEqualToString:@"td"]) {
		NSString *accountName = [self.elementInnerContent stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t\n "]];
		self.currentAccount.accountName = [accountName stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		// After accountname we parse amount
		isParsingAmount = YES;
        self.elementInnerContent = [NSMutableString string];
	}
}

@end
