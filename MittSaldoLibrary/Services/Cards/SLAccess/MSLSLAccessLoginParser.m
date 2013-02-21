//
//  MSLSLAccessLoginParser.m
//  MittSaldoLibrary
//
//  Created by Björn Sållarp on 2/17/13.
//  Copyright (c) 2013 Björn Sållarp. All rights reserved.
//

#import "MSLSLAccessLoginParser.h"

@implementation MSLSLAccessLoginParser
@synthesize passwordFieldName = _passwordFieldName;
@synthesize ssnFieldName = _ssnFieldName;
@synthesize hiddenFields = _hiddenFields;

- (void)parseHtmlString:(NSString *)htmlString
{
    NSError *error = NULL;
    NSRegularExpression *inputFieldsRegex = [NSRegularExpression regularExpressionWithPattern:@"<input.+>"
                                                                                 options:NSRegularExpressionCaseInsensitive
                                                                                   error:&error];
    
    NSRegularExpression *hiddenAttributeRegex = [NSRegularExpression regularExpressionWithPattern:@"type=\"hidden\""
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:&error];
    
    NSRegularExpression *nameAttributeRegex = [NSRegularExpression regularExpressionWithPattern:@"name=\"(.+?)\""
                                                                                        options:NSRegularExpressionCaseInsensitive
                                                                                          error:&error];
    
    NSRegularExpression *valueAttributeRegex = [NSRegularExpression regularExpressionWithPattern:@"value=\"(.+?)\""
                                                                                        options:NSRegularExpressionCaseInsensitive
                                                                                          error:&error];
    
    
    NSArray *fieldMatches = [inputFieldsRegex matchesInString:htmlString options:0 range:NSMakeRange(0, [htmlString length])];

    NSMutableDictionary *hiddenFields = [NSMutableDictionary dictionary];
    
    for (NSTextCheckingResult *match in fieldMatches) {
        NSString *matchString = [htmlString substringWithRange:match.range];
        NSRange matchStringRange = NSMakeRange(0, [matchString length]);
        
        NSTextCheckingResult *hidden = [hiddenAttributeRegex firstMatchInString:matchString options:0 range:matchStringRange];
        NSTextCheckingResult *value = [valueAttributeRegex firstMatchInString:matchString options:0 range:matchStringRange];
        NSTextCheckingResult *name = [nameAttributeRegex firstMatchInString:matchString options:0 range:matchStringRange];
        
        if (name) {
            NSString *nameString = [matchString substringWithRange:[name rangeAtIndex:1]];
            
            if (hidden && value) {
                NSString *valueString = [matchString substringWithRange:[value rangeAtIndex:1]];
                [hiddenFields setValue:valueString forKey:nameString];
            }
            else if ([[nameString lowercaseString] rangeOfString:@"username"].location != NSNotFound) {
                self.ssnFieldName = nameString;
            }
            else if ([[nameString lowercaseString] rangeOfString:@"password"].location != NSNotFound) {
                self.passwordFieldName = nameString;
            }
        }
    }
    
    self.hiddenFields = hiddenFields;
}

@end
