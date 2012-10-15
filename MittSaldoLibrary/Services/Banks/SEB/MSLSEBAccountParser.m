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

#import "MSLSEBAccountParser.h"
#import "MSLParsedAccount.h"

@interface MSLSEBAccountParser()
@property (nonatomic, strong) MSLParsedAccount *currentAccount;
@property (nonatomic, strong) NSMutableString *elementInnerContent;
@end

@implementation MSLSEBAccountParser
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
    
    if (isParsingAccounts) {
        // These are the elements we read information from.
        if ([elementName isEqualToString:@"td"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"name"]) {
            isParsingAccount = YES;
        }
        else if (isParsingAccount) {
            if ([elementName isEqualToString:@"a"]) {
                self.currentAccount = [[MSLParsedAccount alloc] init];
                self.currentAccount.accountId = @((int)[self.parsedAccounts count]);
                
                self.elementInnerContent = [NSMutableString string];
            }
            else if ([elementName isEqualToString:@"td"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"numeric"]) {
                if (!isParsingAmount) {
                    isParsingAmount = YES;
                }
                else {
                    isParsingAmount = NO;
                    isParsingAvailableAmount = YES;
                }
                
                self.elementInnerContent = [NSMutableString string];
            }
        }
    }
    else if (!isParsingAccounts && [elementName isEqualToString:@"th"]) {
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
    
	if (!isParsingAccounts && [elementName isEqualToString:@"th"] && [self.elementInnerContent isEqualToString:@"Konton"]) {
        isParsingAccounts = YES;
        self.elementInnerContent = nil;
    }
	else if (isParsingAccounts && [elementName isEqualToString:@"table"]) {
		isParsingAccounts = NO;
	}
	else if (isParsingAccount && [elementName isEqualToString:@"a"]) {
		self.currentAccount.accountName = self.elementInnerContent;
        self.elementInnerContent = nil;
	}
	else if ((isParsingAmount || isParsingAvailableAmount) && [elementName isEqualToString:@"td"]) {
		if(isParsingAmount) {
			[self.currentAccount setAmountWithString:self.elementInnerContent];
		}
		else if(isParsingAvailableAmount) {
			[self.currentAccount setAvailableAmountWithString:self.elementInnerContent];
			isParsingAvailableAmount = NO;
            
            debug_NSLog(@"%@. %@ -> %@ kr. Disponibelt: %@", self.currentAccount.accountId, self.currentAccount.accountName, self.currentAccount.amount, self.currentAccount.availableAmount);
            
            [self.parsedAccounts addObject:self.currentAccount];
            self.currentAccount = nil;
		}
        self.elementInnerContent = nil;
	}
}

- (NSStringEncoding)sourceStringEncoding
{
    return NSISOLatin1StringEncoding;
}

@end
