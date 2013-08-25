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

#import "MSLAccountsParserBase.h"
#import "MSLParsedAccount.h"

@interface MSLAccountsParserBase()
- (NSStringEncoding)sourceStringEncoding;

@property (nonatomic, strong) MSLParsedAccount *currentAccount;
@property (nonatomic, strong) NSMutableString *elementInnerContent;
@end

@implementation MSLAccountsParserBase

- (BOOL)parseXMLData:(NSData *)XMLMarkup parseError:(NSError **)error
{
	BOOL successful = YES;
    self.parsedAccounts = [NSMutableArray array];
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[self tidyHTML:XMLMarkup]];
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

- (NSData *)tidyHTML:(NSData *)xmlData
{
    NSMutableString *html = [[NSMutableString alloc] initWithData:xmlData encoding:[self sourceStringEncoding]];
    [html replaceOccurrencesOfString:@"&nbsp;" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"&aring;" withString:@"å" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"&auml;" withString:@"ä" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"&ouml;" withString:@"ö" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"&Aring;" withString:@"å" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"&Auml;" withString:@"ä" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    [html replaceOccurrencesOfString:@"&Ouml;" withString:@"ö" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    
    [html replaceOccurrencesOfString:@"&" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [html length])];
    
    return [html dataUsingEncoding:[self dataStringEncoding] allowLossyConversion:YES];
}

- (NSStringEncoding)sourceStringEncoding
{
    return NSUTF8StringEncoding;
}

- (NSStringEncoding)dataStringEncoding
{
    return NSUTF8StringEncoding;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{

}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     

}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [self.elementInnerContent appendString:string];
}

@end
