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

#import "MSLLansforsakringarLoginParser.h"

@implementation MSLLansforsakringarLoginParser


- (BOOL)parseXMLData:(NSData *)XMLMarkup parseError:(NSError **)error
{
	BOOL successful = YES;
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:XMLMarkup];
    
	// Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
    [parser setDelegate:self];
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
	
	self.hiddenFields = [NSMutableDictionary dictionary];
	
    // Start parsing
    [parser parse];
    
    NSError *parseError = [parser parserError];
    if (parseError && error) {
        *error = parseError;
		successful = NO;
    }
    
	
	return successful;
}

#pragma mark - NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
	attributes:(NSDictionary *)attributeDict
{
	if (qName) {
        elementName = qName;
    }
	
	if ([elementName isEqualToString:@"form"]) {
        inLoginForm = [[attributeDict valueForKey:@"name"] isEqualToString:@"login"];
	}
	else if (inLoginForm) {
		// Store all the hidden fields. Some viewstate information in hidden inputfields 
		// are required for a successful postback
		if ([elementName isEqualToString:@"input"] && [[attributeDict valueForKey:@"type"] isEqualToString:@"hidden"]) {
			(self.hiddenFields)[[attributeDict valueForKey:@"name"]] = [attributeDict valueForKey:@"value"];
		}
	}
}

@end
