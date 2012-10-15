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

#import "MSNetworkingClient.h"
#import "MSLHTTPRequestOperation.h"
#import "JSONKit.h"

@interface MSLNetworkingClient()
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation MSLNetworkingClient

+ (MSLNetworkingClient *)sharedClient 
{
    static MSLNetworkingClient *_sharedClient = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedClient = [[self alloc] init];
        
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    });
    
    return _sharedClient;
}

- (id)init
{
    if ((self = [super init])) {
        self.operationQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

- (void)setCookies:(NSArray *)cookies inContainer:(NSMutableArray *)cookieContainer forURL:url
{
    for (NSHTTPCookie *newCookie in cookies) {
        
        NSHTTPCookie *toRemove = nil;
        for (NSHTTPCookie *existingCookie in cookieContainer) {
            if ([newCookie.name isEqualToString:existingCookie.name]) {
                toRemove = existingCookie;
                break;
            }
        }
        
        if (toRemove) {
            [cookieContainer removeObject:toRemove];
        }
        
        if (newCookie.value != nil && ![newCookie.value isEqualToString:@""]) {
            [cookieContainer addObject:newCookie];
        }
    }
}

- (void)applyCookieHeaderToRequest:(NSMutableURLRequest *)request withCookies:(NSArray *)cookies
{
	if ([cookies count] > 0) {
		NSHTTPCookie *cookie;
		NSString *cookieHeader = nil;
		for (cookie in cookies) {
			if (!cookieHeader) {
				cookieHeader = [NSString stringWithFormat: @"%@=%@",[cookie name],[cookie value]];
			} else {
				cookieHeader = [NSString stringWithFormat: @"%@; %@=%@",cookieHeader,[cookie name],[cookie value]];
			}
		}
		if (cookieHeader) {
			[request setValue:cookieHeader forHTTPHeaderField:@"Cookie"];
		}
	}
}

- (void)enqueueRequest:(NSMutableURLRequest *)request cookieStorage:(NSMutableArray *)cookieStorage completionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block
{
    // Add default headers
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPShouldHandleCookies:NO];

    // Set our default user agent if one isn't already set
    NSString *userAgent = [request valueForHTTPHeaderField:@"User-Agent"]; 
    if (!userAgent) {
        userAgent = self.userAgent;
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    // As promised, we attach a special header lettings Handelsbanken know our real identity.
    if ([request.URL.absoluteString hasPrefix:@"https://m.handelsbanken.se"]) {
        [request setValue:@"mittsaldo" forHTTPHeaderField:@"X_SHB_EXTERN"];
    }
    
    // Apply request cookies
    [self applyCookieHeaderToRequest:request withCookies:cookieStorage];
    
    MSLHTTPRequestOperation *requestOperation = [[MSLHTTPRequestOperation alloc] initWithRequest:request];
    
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *newCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[requestOperation.response allHeaderFields] forURL:requestOperation.request.URL];
        
        [self setCookies:newCookies inContainer:cookieStorage forURL:requestOperation.request.URL];
        
        if (block) {
            block(operation, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            block(operation, error);
        }
    }];
    
    
    [requestOperation setRedirectionBlock: ^(NSURLConnection *connection, NSMutableURLRequest *request, NSHTTPURLResponse *response) {
        [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [request setHTTPShouldHandleCookies:NO];
        [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        
        // Store cookies
        NSArray *newCookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:response.URL];
        
        [self setCookies:newCookies inContainer:cookieStorage forURL:response.URL];
        
        // Apply request cookies
        [self applyCookieHeaderToRequest:request withCookies:cookieStorage];
    }];
    
    [self.operationQueue addOperation:requestOperation];
}

- (void)postRequestWithURL:(NSURL *)url andParameters:(NSDictionary *)parameters cookieStorage:(NSMutableArray *)cookieStorage completionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block
{
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:url];
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))] forHTTPHeaderField:@"Content-Type"];
    [postRequest setHTTPBody:[AFQueryStringFromParametersWithEncoding(parameters, NSUTF8StringEncoding) dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self enqueueRequest:postRequest cookieStorage:cookieStorage completionBlock:block];
}

- (void)getRequestWithURL:(NSURL *)url cookieStorage:(NSMutableArray *)cookieStorage completionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block
{
    NSMutableURLRequest *getRequest = [NSMutableURLRequest requestWithURL:url];
    [getRequest setHTTPMethod:@"GET"];
    
    [self enqueueRequest:getRequest cookieStorage:cookieStorage completionBlock:block];
}

- (void)postSoapRequestWithURL:(NSURL *)url andSoapAction:(NSString *)soapAction soapBody:(NSString *)soapBody cookieStorage:(NSMutableArray *)cookieStorage completionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block
{
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:url];
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setValue:soapAction forHTTPHeaderField:@"SOAPAction"];
    
    [postRequest setValue:[NSString stringWithFormat:@"text/xml; charset=%@", (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))] forHTTPHeaderField:@"Content-Type"];

    [postRequest setHTTPBody:[soapBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self enqueueRequest:postRequest cookieStorage:cookieStorage completionBlock:block];
}

- (void)postJSONRequestWithURL:(NSURL *)url andParameters:(NSDictionary *)parameters cookieStorage:(NSMutableArray *)cookieStorage completionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block
{
    [self postJSONRequestWithURL:url userAgent:nil parameters:parameters cookieStorage:cookieStorage completionBlock:block];
}

- (void)postJSONRequestWithURL:(NSURL *)url userAgent:(NSString *)userAgent parameters:(NSDictionary *)parameters cookieStorage:(NSMutableArray *)cookieStorage completionBlock:(void (^)(AFHTTPRequestOperation *requestOperation, NSError *error))block
{
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:url];
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [postRequest setHTTPBody:[parameters JSONData]];
    
    if (userAgent) {
        [postRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    [self enqueueRequest:postRequest cookieStorage:cookieStorage completionBlock:block];
}


@end
