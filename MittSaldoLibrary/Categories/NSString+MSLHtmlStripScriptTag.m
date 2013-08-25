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

#import "NSString+MSLHtmlStripScriptTag.h"

@implementation NSString (MSLHtmlStripScriptTag)

- (NSData *)cleanStringFromJavascriptWithEncoding:(NSStringEncoding)encoding
{
    // The pesky inline javascript (not wrapped on CDATA as they should!) need to go for the markup to be valid xhtml
    NSString *regexToReplaceRawLinks = @"<script[\\d\\D]*?>[\\d\\D]*?</script>";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexToReplaceRawLinks
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSString *cleanHtml = [regex stringByReplacingMatchesInString:self
                                                          options:0
                                                            range:NSMakeRange(0, [self length])
                                                     withTemplate:@""];
    return [cleanHtml dataUsingEncoding:encoding allowLossyConversion:YES];
}

@end
