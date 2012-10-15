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

#import "MSLIkanoBankAccountParser.h"
#import "MSLParsedAccount.h"

@interface MSLIkanoBankAccountParser()
@property (nonatomic, strong) MSLParsedAccount *currentAccount;
@property (nonatomic, strong) NSMutableString *elementInnerContent;
@end

@implementation MSLIkanoBankAccountParser
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

    if ([elementName isEqualToString:@"table"] && [self.parsedAccounts count] == 0) {
        isParsingAccounts = YES;
    }
	else if (isParsingAccounts) {
        if ([elementName isEqualToString:@"a"]) {
            self.currentAccount = [[MSLParsedAccount alloc] init];
            self.currentAccount.accountId = @((int)[self.parsedAccounts count]);
            
            self.elementInnerContent = [NSMutableString string];
        }
        else if ([elementName isEqualToString:@"td"] && [[attributeDict valueForKey:@"class"] isEqualToString:@"txt-right"]) {
            isParsingAmount = YES;
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
    
    if (isParsingAccounts && [elementName isEqualToString:@"a"]) {
        [self.currentAccount setAccountName:self.elementInnerContent];
        self.elementInnerContent = nil;
    }
    else if (isParsingAmount && [elementName isEqualToString:@"td"] && self.elementInnerContent) {        
        [self.currentAccount setAmountWithString:self.elementInnerContent];
        
        debug_NSLog(@"%@. %@ -> %@ kr", self.currentAccount.accountId, self.currentAccount.accountName, self.currentAccount.amount);
        
        [self.parsedAccounts addObject:self.currentAccount];
        self.currentAccount = nil;
        isParsingAmount = NO;
	}
    else if (isParsingAccounts && [elementName isEqualToString:@"table"]) {
        isParsingAccounts = NO;
    }
}

@end
