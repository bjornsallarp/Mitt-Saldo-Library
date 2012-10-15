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

#import "MSLHTTPRequestOperation.h"

@implementation MSLHTTPRequestOperation

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSHTTPURLResponse *)response
{
    if (response && self.redirectionBlock) {
        NSMutableURLRequest *newRequest = [request mutableCopy];
        
        if (self.redirectionBlock) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                self.redirectionBlock(connection, newRequest, response);
            });
        }
        
        return newRequest;
    }
   
    return request;
}

@end
