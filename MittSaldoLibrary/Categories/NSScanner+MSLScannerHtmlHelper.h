//
//  NSScanner+MSLScannerHtmlHelper.h
//  MittSaldoLibrary
//
//  Created by Sållarp on 7/17/13.
//  Copyright (c) 2013 Björn Sållarp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSScanner (MSLScannerHtmlHelper)

- (void)skipIntoTag:(NSString *)tagName;

@end
