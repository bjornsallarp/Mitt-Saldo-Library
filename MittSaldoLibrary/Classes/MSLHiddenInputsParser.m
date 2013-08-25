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

#import "MSLHiddenInputsParser.h"

@implementation MSLHiddenInputsParser

- (BOOL)parseXMLData:(NSData *)XMLMarkup parseError:(NSError **)error
{
    self.hiddenFields = [NSMutableDictionary dictionary];
    
    NSString *html = [[NSString alloc] initWithData:XMLMarkup encoding:NSUTF8StringEncoding];
    NSError *regexError = nil;
    
    // This regex picks up hidden inputs that have a value attribute.
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<input[^>]*type=\"hidden\"[^>]*name=\"([^\\\"]+)\"[^>]*value=\"([^\\\"]+)\""
                                                                           options:NSRegularExpressionCaseInsensitive error:&regexError];
    
    NSArray *results = [regex matchesInString:html options:0 range:NSMakeRange(0, [html length])];
    
    if (regexError != nil) {
        *error = regexError;
        return NO;
    }
    
    [results enumerateObjectsUsingBlock:^(NSTextCheckingResult *match, NSUInteger idx, BOOL *stop) {
        NSString *name = [html substringWithRange:[match rangeAtIndex:1]];
        NSString *value = [html substringWithRange:[match rangeAtIndex:2]];
        
        [self.hiddenFields setValue:value forKey:name];
    }];
    
    return YES;
}

@end
