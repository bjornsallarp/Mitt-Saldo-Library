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

#import "MSLTicketRikskortetLoginParser.h"
#import "MSLTicketRikskortetTransaction.h"

@interface MSLTicketRikskortetLoginParser ()
@property (nonatomic, strong) NSMutableString *elementInnerContent;
@property (nonatomic, strong) MSLTicketRikskortetTransaction *transaction;
@end

@implementation MSLTicketRikskortetLoginParser


- (BOOL)parseXMLData:(NSData *)data parseError:(NSError **)error
{
	BOOL successful = YES;
    self.transactions = [NSMutableArray array];
	
	// Create XML parser
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    
	// Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
    [parser setDelegate:self];
	
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
	
    // Start parsing
    [parser parse];
    
    NSError *parseError = [parser parserError];
    if (parseError && error) {
        *error = parseError;
		successful = NO;
    }
    
    
	return successful;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName) {
        elementName = qName;
    }
    
    if ([elementName isEqualToString:@"EmployeeTransactionRecord"]) {
        self.transaction = [[MSLTicketRikskortetTransaction alloc] init];
    }
    
    self.elementInnerContent = [NSMutableString string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
    
    if ([elementName isEqualToString:@"ErrorCode"]) {
        self.errorCode = self.elementInnerContent;
    }
    else if ([elementName isEqualToString:@"Balance"]) {
        self.balance = [self.elementInnerContent doubleValue];
    }
    else if ([elementName isEqualToString:@"BalanceStr"]) {
        self.balanceString = self.elementInnerContent;
    }
    else if ([elementName isEqualToString:@"CardStatus"]) {
        self.cardStatus = self.elementInnerContent;
    }
    else if (self.transaction) {
        if ([elementName isEqualToString:@"Id"]) {
            self.transaction.transactionId = self.elementInnerContent;
        }
        else if ([elementName isEqualToString:@"CardAcceptor"]) {
            self.transaction.cardAcceptor = self.elementInnerContent;
        }
        else if ([elementName isEqualToString:@"Description"]) {
            self.transaction.description = self.elementInnerContent;
        }
        else if ([elementName isEqualToString:@"Amount"]) {
            self.transaction.amount = self.elementInnerContent;
        }
        else if ([elementName isEqualToString:@"Date"]) {
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            df.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ";
            
            // Replace the timezone information to work with NSDateFormatter
            self.transaction.date = [df dateFromString:[self.elementInnerContent stringByReplacingOccurrencesOfString:@"+02:00" withString:@"+0200"]];
        }
        else if ([elementName isEqualToString:@"Type"]) {
            self.transaction.type = self.elementInnerContent;
        }
        else if ([elementName isEqualToString:@"EmployeeTransactionRecord"]) {
            [self.transactions addObject:self.transaction];
            self.transaction = nil;
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [self.elementInnerContent appendString:string];
}

@end
