//
//  MSLSLAccessLoginParser.h
//  MittSaldoLibrary
//
//  Created by Björn Sållarp on 2/17/13.
//  Copyright (c) 2013 Björn Sållarp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSLSLAccessLoginParser : NSObject

@property (nonatomic, strong) NSMutableDictionary *hiddenFields;
@property (nonatomic, strong) NSString *ssnFieldName;
@property (nonatomic, strong) NSString *passwordFieldName;

- (void)parseHtmlString:(NSString *)htmlString;

@end
