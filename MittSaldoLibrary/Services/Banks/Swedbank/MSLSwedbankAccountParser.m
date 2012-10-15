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

#import "MSLSwedbankAccountParser.h"
#import "MSLParsedAccount.h"

@interface MSLSwedbankAccountParser()
@property (nonatomic, strong) MSLParsedAccount *currentAccount;
@property (nonatomic, strong) NSMutableString *elementInnerContent;
@end

@implementation MSLSwedbankAccountParser
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
	
    if ([elementName isEqualToString:@"dd"]) {
        self.currentAccount = [[MSLParsedAccount alloc] init];
        self.currentAccount.accountId = @((int)[self.parsedAccounts count]);
    }
	else if (self.currentAccount && [elementName isEqualToString:@"span"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"name"]) {
		isParsingName = YES;
        self.elementInnerContent = [NSMutableString string];
	}
	else if (self.currentAccount && [elementName isEqualToString:@"span"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"amount"]) {
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
    
    if ([elementName isEqualToString:@"dd"] && self.currentAccount) {
		debug_NSLog(@"%@. %@ -> %@ kr", self.currentAccount.accountId, self.currentAccount.accountName, self.currentAccount.amount);

        if (self.currentAccount.accountName && self.currentAccount.amount) {
            [self.parsedAccounts addObject:self.currentAccount];
        }
        
        self.currentAccount = nil;
	}
	else if ([elementName isEqualToString:@"span"] && isParsingName) {
        self.currentAccount.accountName = self.elementInnerContent;
		isParsingName = NO;
        self.elementInnerContent = nil;
	}
	else if ([elementName isEqualToString:@"span"] && isParsingAmount) {
		[self.currentAccount setAmountWithString:self.elementInnerContent];
		isParsingAmount = NO;
        self.elementInnerContent = nil;
	}
}

@end
