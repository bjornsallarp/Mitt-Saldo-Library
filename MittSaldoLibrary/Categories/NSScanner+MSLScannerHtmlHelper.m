//
//  NSScanner+MSLScannerHtmlHelper.m
//  MittSaldoLibrary
//
//  Created by Sållarp on 7/17/13.
//  Copyright (c) 2013 Björn Sållarp. All rights reserved.
//

#import "NSScanner+MSLScannerHtmlHelper.h"

@implementation NSScanner (MSLScannerHtmlHelper)

- (void)skipIntoTag:(NSString *)tagName
{
    // Go to start tag
    NSString *tag = [NSString stringWithFormat:@"<%@", tagName];
    [self scanUpToString:tag intoString:nil];
    
    // Go to end of that tag
    [self scanUpToString:@">" intoString:nil];
    
    // Skip on char ahead to get past the '<'-char
    [self setScanLocation:[self scanLocation] + 1];
}

@end
