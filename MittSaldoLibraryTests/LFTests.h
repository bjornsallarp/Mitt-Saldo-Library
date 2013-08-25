//
//  LFTests.h
//  MittSaldoLibrary
//
//  Created by Sållarp on 7/15/13.
//  Copyright (c) 2013 Björn Sållarp. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface LFTests : SenTestCase

- (NSArray *)parseAccountTableRowsFromHtml:(NSString *)html error:(NSError *)error;

@end
