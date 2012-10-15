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


#import "MSICABankenAccountParser.h"
#import "MSLParsedAccount.h"

@interface MSICABankenAccountParser()
@property (nonatomic, strong) MSLParsedAccount *currentAccount;
@property (nonatomic, strong) NSMutableString *elementInnerContent;
@end

@implementation MSICABankenAccountParser
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
	if (!self.currentAccount && [elementName isEqualToString:@"div"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"row"] && [attributeDict valueForKey:@"onmousedown"] != nil) {
		self.currentAccount = [[MSLParsedAccount alloc] init];
        self.currentAccount.accountId = @((int)[self.parsedAccounts count]);
	}
	else if (self.currentAccount) {
        if ([elementName isEqualToString:@"span"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"form-label"]) {
            isParsingName = YES;
        }
        else if (isParsingName && [elementName isEqualToString:@"span"] && [attributeDict valueForKey:@"title"] != nil) {
            self.currentAccount.accountName = [attributeDict valueForKey:@"title"];
            isParsingName = NO;
        }
        else if([elementName isEqualToString:@"div"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"upper"]) {
            isParsingAmount = YES;
        }
        else if(isParsingAmount && [elementName isEqualToString:@"span"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"right"]) {
            self.elementInnerContent = [NSMutableString string];
        }
        else if([elementName isEqualToString:@"div"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"lower"]) {
            isParsingAvailableAmount = YES;
        }
        else if(isParsingAvailableAmount && [elementName isEqualToString:@"span"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"right"]) {
            self.elementInnerContent = [NSMutableString string];
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
    
	if((isParsingAmount || isParsingAvailableAmount) && [elementName isEqualToString:@"span"] && self.elementInnerContent) {        
		if(isParsingAmount) {
			[self.currentAccount setAmountWithString:self.elementInnerContent];
			isParsingAmount = NO;
		}
		else if(isParsingAvailableAmount) {
			[self.currentAccount setAvailableAmountWithString:self.elementInnerContent];
			isParsingAvailableAmount = NO;
            
            debug_NSLog(@"%@. %@ -> %@ kr. Disponibelt: %@", self.currentAccount.accountId, self.currentAccount.accountName, 
                        self.currentAccount.amount, self.currentAccount.availableAmount);
            
            [self.parsedAccounts addObject:self.currentAccount];
            self.currentAccount = nil;
		}
        
        self.elementInnerContent = nil;
	}	
}

@end
