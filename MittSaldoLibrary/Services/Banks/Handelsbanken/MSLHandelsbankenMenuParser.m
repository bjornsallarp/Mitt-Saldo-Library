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

#import "MSLHandelsbankenMenuParser.h"

@implementation MSLHandelsbankenMenuParser


- (BOOL)parseXMLData:(NSData *)XMLMarkup parseError:(NSError **)error
{
	BOOL successful = YES;
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:XMLMarkup];
    
	// Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
    [parser setDelegate:self];
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
	
	self.menuLinks = [NSMutableArray array];
	    
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
	
	
	// These are the elements we read information from.
	if ([elementName isEqualToString:@"ul"]) {
		if ([[attributeDict valueForKey:@"class"] isEqualToString:@"list"]) {
			isParsingMenu = YES;
		}	
	}
	else if (isParsingMenu == YES && [elementName isEqualToString:@"a"]) {
		// Create a complete url. The urls in the markup is relative
		[self.menuLinks addObject:[attributeDict valueForKey:@"href"]];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
    
	if ([elementName isEqualToString:@"ul"] && isParsingMenu) {
		isParsingMenu = NO;
	}
}

@end
