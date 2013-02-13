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

#import "MSLNordeaServiceProxy.h"
#import "MSLNordeaLoginParser.h"
#import "MSLNordeaAccountParser.h"
#import "MSLNetworkingClient.h"

NSString * const kMSNordeaLoginURL = @"https://mobil.nordea.se/banking-nordea/nordea-c3/login.html";
NSString * const kMSNordeaTransferFundsURL = @"https://mobil.nordea.se/banking-nordea/nordea-c3/transfer.html";
NSString * const kMSNordeaAccountListURL = @"https://mobil.nordea.se/banking-nordea/nordea-c3/accounts.html";

@interface MSLServiceProxyBase(Private)
- (void)callFailureBlock:(MSLServiceFailureBlock)failureBlock withError:(NSError *)error andMessage:(NSString *)message;
- (void)callSuccessBlock:(MSLServiceSimpleBlock)successBlock;
@end

@interface MSLNordeaServiceProxy ()
@property (nonatomic, strong) MSLNordeaLoginParser *loginParser;
@property (nonatomic, strong) NSString *captchaCode;
@end

@implementation MSLNordeaServiceProxy

+ (id)proxyWithUsername:(NSString *)username andPassword:(NSString *)password
{
    MSLNordeaServiceProxy *login = [[self alloc] init];
    login.username = username;
    login.password = password;
    
    return login;
}

- (void)performLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    if ([self.username length] != 12) {
        failure(nil, @"Ditt personnummer innehåller inte 12 siffror. Nya krav från Nordea! Uppdatera personnummer under 'Inställningar'");
        return;
    }
    
    self.loginParser = [[MSLNordeaLoginParser alloc] init];
    
    NSURL *loginUrl = [self loginURL];
    [[MSLNetworkingClient sharedClient] getRequestWithURL:loginUrl cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {
            
            NSData *xhtmlData = [self cleanStringFromJavascript:requestOperation.responseString];
            [self.loginParser parseXMLData:xhtmlData parseError:nil];
            
            if (self.loginParser.csrf_token == nil || [self.loginParser.csrf_token isEqualToString:@""]) {
                [self callFailureBlock:failure withError:nil andMessage:@"BankLoginFailureAlert"];
            }
            else {
                [self postLoginWithSuccessBlock:success failure:failure];
            }
        }
        else {
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
}

- (void)postLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:self.username forKey:self.loginParser.usernameField];
    [params setValue:self.password forKey:self.loginParser.passwordField];
    [params setValue:self.loginParser.csrf_token forKey:@"_csrf_token"];
    
    if (self.captchaCode) {
        [params setValue:self.captchaCode forKey:@"captcha"];
    }
    
    NSURL *postUrl = [self loginURL];
    [[MSLNetworkingClient sharedClient] postRequestWithURL:postUrl andParameters:params cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        if ([requestOperation hasAcceptableStatusCode]) {
            
            if ([requestOperation.responseString rangeOfString:@"info_systemfailure.png"].location != NSNotFound) {
                [self callFailureBlock:failure withError:nil andMessage:@"Nordeas mobilbank ligger tyvärr nere. Dom beklagar och jobbar säkert med att lösa problemet."];
            }
            else if (!self.captchaCode && [requestOperation.responseString rangeOfString:@"captcha.png"].location != NSNotFound) {
                
                // We hit the login limit, fear not, hi-res captchas can be handled easily!
                NSData *xhtmlData = [self cleanStringFromJavascript:requestOperation.responseString];
                
                [self.loginParser parseXMLData:xhtmlData parseError:nil];
                if (self.loginParser.csrf_token == nil || [self.loginParser.csrf_token isEqualToString:@""]) {
                    [self callFailureBlock:failure withError:nil andMessage:@"BankLoginFailureAlert"];
                }
                else {
                    // We have a new csrf-token and we're ready to ocr the captcha and re-try login
                    [self performCaptchaLoginWithSuccessBlock:success failure:failure];
                }
            }
            else if ([requestOperation.responseString rangeOfString:@"_csrf_token"].length > 0) {
                [self callFailureBlock:failure withError:nil andMessage:@"BankLoginDeniedAlert"];
            }
            else {
                [self callSuccessBlock:success];
            }
        } 
        else {
            [self callFailureBlock:failure withError:requestOperation.error andMessage:nil];
        }
    }];
}

- (NSMutableURLRequest *)createCaptchaOcrRequest:(NSDictionary *)postKeys withData:(NSData *)data
{
	NSURL *captchaServiceUrl = [NSURL URLWithString:@"http://maggie.ocrgrid.org/cgi-bin/weocr/submit_ocrad.cgi"];
	NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:captchaServiceUrl];
	[postRequest setHTTPMethod:@"POST"];
	
	//Add the header info
	NSString *stringBoundary = @"0xKhTmLbOuNdArY";
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",stringBoundary];
	[postRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
	
	//create the body
	NSMutableData *postBody = [NSMutableData data];
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	//add key values from the NSDictionary object
	NSEnumerator *keys = [postKeys keyEnumerator];

	for (int i = 0, keyCount = [postKeys count]; i < keyCount; i++) {
		NSString *tempKey = [keys nextObject];
		[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",tempKey] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[[NSString stringWithFormat:@"%@",postKeys[tempKey]] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	}
    
	// add data field and file data
	[postBody appendData:[@"Content-Disposition: form-data; name=\"userfile\"; filename=\"captcha.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[NSData dataWithData:data]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	// add the body to the post
	[postRequest setHTTPBody:postBody];
    [postRequest addValue:[NSString stringWithFormat:@"%d", [postBody length]] forHTTPHeaderField:@"Content-Length"];
    
	return postRequest;
}

- (void)performCaptchaLoginWithSuccessBlock:(MSLServiceSimpleBlock)success failure:(MSLServiceFailureBlock)failure
{
    [[MSLNetworkingClient sharedClient] getRequestWithURL:[NSURL URLWithString:@"https://mobil.nordea.se/banking-nordea/nordea-c1/captcha.png"] cookieStorage:self.cookieStorage completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
        
        if ([requestOperation hasAcceptableStatusCode]) {
            UIImage *captcha = [UIImage imageWithData:requestOperation.responseData];
            NSData *jpgCaptchaData = UIImageJPEGRepresentation(captcha, 1.0);
            
            NSDictionary *dict = @{@"outputencoding": @"utf-8", 
                                  @"outputformat": @"txt",
                                  @"contentlang": @"eng"};
            
            [[MSLNetworkingClient sharedClient] enqueueRequest:[self createCaptchaOcrRequest:dict withData:jpgCaptchaData] cookieStorage:nil completionBlock:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                
                if ([requestOperation hasAcceptableStatusCode]) {
                    
                    // Remove any new-line chars
                    NSString *captcha = [requestOperation.responseString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    // 5's are sometimes translated into 's'.
                    captcha = [captcha stringByReplacingOccurrencesOfString:@"s" withString:@"5"];
                    captcha = [captcha stringByReplacingOccurrencesOfString:@"l" withString:@"1"];
                    
                    self.captchaCode = captcha;
                    
                    debug_NSLog(@"Captcha resolved: '%@'", self.captchaCode);
                    [self postLoginWithSuccessBlock:success failure:failure];
                }
                else {
                    [self callFailureBlock:failure withError:nil andMessage:@"Du har loggat in väldigt många gånger hos Nordea idag, tyvärr är det problem med captcha-funktionen just nu. Testa igen och Logga in manuellt idag om det inte löser sig."];
                }
            }];
        }
    }];
}

- (NSData *)manipulateAccountBalanceResponse:(NSData *)html
{
    NSString *htmlString = [[NSString alloc] initWithData:html encoding:NSISOLatin1StringEncoding];
    return [self cleanStringFromJavascript:htmlString];
}


#pragma mark - Accessors

- (id)accountsParser
{
    return [[MSLNordeaAccountParser alloc] init];
}

- (NSURL *)loginURL
{
    return [NSURL URLWithString:kMSNordeaLoginURL];
}

- (NSURL *)transferFundsURL
{
    return [NSURL URLWithString:kMSNordeaTransferFundsURL];
}

- (NSURL *)accountsListURL
{
    return [NSURL URLWithString:kMSNordeaAccountListURL];
}

@end
