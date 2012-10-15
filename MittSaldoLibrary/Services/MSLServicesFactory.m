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

#import <objc/runtime.h>
#import "MSLServicesFactory.h"
#import "MSLServiceProxyBase.h"

@implementation MSLServicesFactory

+ (NSArray *)registeredServices
{
    static NSArray *_registeredServices = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
 
        // Use reflection to find classes that inherit our special service base class
        int numClasses = objc_getClassList(NULL, 0);
        Class *existingClasses = NULL;
        
        if (numClasses > 0) {
            NSMutableArray *registerdServices = [[NSMutableArray alloc] initWithCapacity:numClasses];
            
            existingClasses = malloc(sizeof(Class) * numClasses);
            numClasses = objc_getClassList(existingClasses, numClasses);
            
            for (int i = 0; i < numClasses; i++) {
                Class nextClass = existingClasses[i];
                
                if (!class_conformsToProtocol(nextClass, @protocol(MSLServiceDescriptionProtocol)))
                    continue;
                
                NSObject<MSLServiceDescriptionProtocol> *description = [[[nextClass alloc] init] autorelease];
                [registerdServices addObject:description];
            }
            free(existingClasses);
            
            _registeredServices = registerdServices;
        }        
    });
    
    return _registeredServices;
}

+ (NSArray *)supportedCards
{
    NSMutableArray *supportedCards = [NSMutableArray array];
    [[self registeredServices] enumerateObjectsUsingBlock:^(id<MSLServiceDescriptionProtocol> obj, NSUInteger idx, BOOL *stop) {
        if ([obj isCard]) {
            [supportedCards addObject:[obj serviceIdentifier]];
        }
    }];
    
    return supportedCards;
}

+ (NSArray *)supportedBanks
{
    NSMutableArray *supportedBanks = [NSMutableArray array];
    [[self registeredServices] enumerateObjectsUsingBlock:^(id<MSLServiceDescriptionProtocol> obj, NSUInteger idx, BOOL *stop) {
        if ([obj isBank]) {
            [supportedBanks addObject:[obj serviceIdentifier]];
        }
    }];
    
    return supportedBanks;
}

+ (MSLServiceProxyBase *)proxyForServiceWithIdentifier:(NSString *)identifier
{
    NSObject<MSLServiceDescriptionProtocol> *serviceDescription = [self descriptionForServiceWithIdentifier:identifier];
    MSLServiceProxyBase *serviceProxy = [serviceDescription serviceProxyWithUsername:nil andPassword:nil];
    return serviceProxy;
}

+ (NSObject<MSLServiceDescriptionProtocol> *)descriptionForServiceWithIdentifier:(NSString *)identifier
{   
    for (NSObject<MSLServiceDescriptionProtocol> * description in [self registeredServices]) {
        if ([[description serviceIdentifier] isEqualToString:identifier]) {
            return description;
        }
    }
    
    return nil;
}

@end
