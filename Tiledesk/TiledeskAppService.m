//
//  TiledeskAppService.m
//  tiledesk
//
//  Created by Andrea Sponziello on 19/06/2018.
//  Copyright © 2018 Frontiere21. All rights reserved.
//

#import "TiledeskAppService.h"
#import "ChatUser.h"
#import "ChatAuth.h"
#import "HelloUser.h"
//#import "ChatConversation.h"
//#import "ChatManager.h"

@implementation TiledeskAppService

-(id)init {
    self = [super init];
    if (self) {
        // Init code
    }
    return self;
}

+ (NSString *)authService {
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"]];
    NSString *host = [dictionary objectForKey:@"auth-service-host"];
    NSString *authService = [dictionary objectForKey:@"auth-service-path"];
    NSString *service = [NSString stringWithFormat:@"%@%@", host, authService];
    NSLog(@"auth service url: %@", service);
    return service;
}

//+(NSString *)archiveConversationService:(NSString *)conversationId {
//    // https://us-central1-chat-v2-dev.cloudfunctions.net/api/tilechat/conversations/support-group-LGdXjl_T98q_Kz3ycdJ
//    NSString *tenant = [ChatManager getInstance].tenant;
//    NSString *url = [[NSString alloc] initWithFormat:@"https://us-central1-chat-v2-dev.cloudfunctions.net/api/%@/conversations/%@", tenant, conversationId];
//    return url;
//}
//
//+(NSString *)archiveAndCloseSupportConversationService:(NSString *)conversationId {
//    // https://us-central1-chat-v2-dev.cloudfunctions.net/supportapi/tilechat/groups/support-group-LG9WBQE2mkIKVIhZmHW
//    NSString *tenant = [ChatManager getInstance].tenant;
//    NSString *url = [[NSString alloc] initWithFormat:@"https://us-central1-chat-v2-dev.cloudfunctions.net/supportapi/%@/groups/%@", tenant, conversationId];
//    return url;
//}

+(void)loginWithEmail:(NSString *)email password:(NSString *)password completion:(void (^)(HelloUser *user, NSError *))callback {
    [TiledeskAppService loginForFirebaseTokenWithEmail:email password:password completion:^(NSString *token, NSError *error) {
        NSLog(@"Logging in with email: %@ pwd: %@", email, password);
        if (error) {
            callback(nil, error);
        }
        else {
            [ChatAuth authWithCustomToken:token completion:^(ChatUser *user, NSError *error) {
                if (error) {
                    NSLog(@"Authentication error. %@", error);
                    callback(nil, error);
                }
                else {
                    NSLog(@"Authentication success.");
                    HelloUser *signedUser = [[HelloUser alloc] init];
                    signedUser.userid = user.userId;
                    signedUser.username = user.email;
                    // Registration with custom token returns firebase's users without email.
                    // Using provided login form email to save user's email.
                    signedUser.email = user.email != nil ? user.email : email;
                    signedUser.password = password;
                    callback(signedUser, nil);
                }
            }];
        }
    }];
}

+(void)loginForFirebaseTokenWithEmail:(NSString *)email password:(NSString *)password completion:(void (^)(NSString *token, NSError *error))callback {
    NSString *auth_url = [TiledeskAppService authService];
    NSLog(@"CUSTOM AUTH URL: %@", auth_url);
    NSLog(@"email: %@", email);
    NSDictionary* dict = @{
                           @"email": email,
                           @"password": password
                           };
    NSData *jsonData = [TiledeskAppService dictAsJSON:dict];
    NSURL *url = [NSURL URLWithString:auth_url];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];

    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"firebase auth ERROR: %@", error);
            callback(nil, error);
        }
        else {
            NSString *token = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            NSLog(@"token response: %@", token);
            callback(token, nil);
        }
    }];
    [task resume];
}

//+(void)archiveConversation:(ChatConversation *)conversation completion:(void (^)(NSError *error))callback {
//    
//    FIRUser *fir_user = [FIRAuth auth].currentUser;
//    [fir_user getIDTokenWithCompletion:^(NSString * _Nullable token, NSError * _Nullable error) {
//        if (error) {
//            NSLog(@"Error while getting current FIrebase token: %@", error);
//            callback(error);
//            return;
//        }
//        NSString *service_url = [TiledeskAppService archiveConversationService:conversation.conversationId];
//        NSLog(@"URL: %@", service_url);
//        NSURL *url = [NSURL URLWithString:service_url];
//        NSURLSession *session = [NSURLSession sharedSession];
//        
//        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
//                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
//                                                           timeoutInterval:60.0];
//        [request addValue:token forHTTPHeaderField:@"Authorization"];
//        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//        [request setHTTPMethod:@"DELETE"];
//        
//        NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
//            if (error) {
//                NSLog(@"firebase auth ERROR: %@", error);
//                callback(error);
//            }
//            else {
//                NSString *token = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
//                NSLog(@"token response: %@", token);
//                callback(nil);
//            }
//        }];
//        [task resume];
//    }];
//}

+(NSData *)dictAsJSON:(NSDictionary *)dict {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
        return nil;
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//        NSLog(@"JSON String: %@", jsonString);
        return jsonData;
    }
}

@end
