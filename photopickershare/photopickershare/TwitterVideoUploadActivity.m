//
//  TwitterVideoUploadActivity.m
//  photopickershare
//
//  Created by jclaan on 9/19/15.
//  Copyright © 2015 jclaan. All rights reserved.
//

#import "TwitterVideoUploadActivity.h"

#import <Social/Social.h>

@import Accounts;

@interface TwitterVideoUploadActivity ()

@property (nonatomic, strong) NSArray *activityItems;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) ACAccount* twitterAccount;
@property (nonatomic, strong) NSURL* videoURL;
@property (nonatomic,strong) NSURL* requestURL;
@property (nonatomic,strong) NSString *mediaID;

@end


@implementation TwitterVideoUploadActivity

# pragma mark - UIActivity

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    [super prepareWithActivityItems:activityItems];
    
    self.activityItems = activityItems;
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryShare;
}

- (NSString *)activityType {
    return @"org.twitter";
}

- (NSString *)activityTitle {
    return @"Twitter Vid";
}

- (UIImage *)activityImage {
    if ([[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."][0] intValue] >= 8) {
        return [UIImage imageNamed:@"color_videoTwitterActivity"];
    } else {
        return [UIImage imageNamed:@"videoTwitterActivity"];
    }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    
    for (id item in activityItems) {
        if ([item isKindOfClass:[NSURL class]]) {
            
            NSURL* url = item;
            
            NSString *filenameext = [[url path] pathExtension];
            
            if ([filenameext isEqualToString:@"mov"] || [filenameext isEqualToString:@"mp4"] || [filenameext isEqualToString:@"m4v"] ) {
                return YES;
            }    
        }
    }
    
    
    
    return NO;
}






- (UIViewController *)activityViewController {
    SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    return [self activityViewControllerWithComposeViewController:composeViewController];
}

# pragma mark - Helpers (UIActivity)

- (NSString *)firstStringOrEmptyStringFromArray:(NSArray *)array {
    for (id item in array) {
        if ([item isKindOfClass:[NSString class]]) {
            return item;
        }
    }
    return @"";
}

- (UIViewController *)activityViewControllerWithComposeViewController:(SLComposeViewController *)composeViewController {
 
    [composeViewController setInitialText:[self firstStringOrEmptyStringFromArray:self.activityItems]];
    for (id item in self.activityItems) {
        if ([item isKindOfClass:[UIImage class]]) {
            [composeViewController addImage:item];
            
            self.image = item;
            
        }
    }
    for (id item in self.activityItems) {
        if ([item isKindOfClass:[NSURL class]]) {
           
            //@TODO: add some checking about being a mov file
            
            self.videoURL = item;
            //[composeViewController addURL:item];
        }
    }
    __weak typeof(self) weakSelf = self;
//    composeViewController.completionHandler = ^(SLComposeViewControllerResult result) {
//        BOOL completed = (result == SLComposeViewControllerResultDone);
//        
//        [weakSelf getTwitterAccount];
//        //[weakSelf activityDidFinish:completed];
//    };
//    
//    return composeViewController;
    
    UIAlertController * alert=   [UIAlertController
                                  alertControllerWithTitle:@"My Title"
                                  message:@"Enter User Credentials"
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   //Do Some action here
                                                   
                                                   [weakSelf stepOne_getTwitterAccount];
                                                   
                                               }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Caption";
    }];


    
    return alert;
}




- (void)performActivity
{
    // This is where you can do anything you want, and is the whole reason for creating a custom
    // UIActivity
    

    

}


- (void) stepOne_getTwitterAccount {
    
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        if (!granted) {
            NSLog(@"Access denied.");
        }
        else {
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            if (accounts.count > 0) {
               self.twitterAccount = [accounts objectAtIndex:0];
                
                
                [self stepTwo_getMedia_id_withCompletion:^(NSNumber *mediaID, NSError *error) {
                    
                    
                    NSLog(@"MEDIA ID: %@", mediaID);
                    
                    self.mediaID = [mediaID stringValue];
                    
                    __strong typeof(self) strongSelf = self;
      
                    
                    [strongSelf postMediaUploadAPPENDWithVideoURL:self.videoURL
                                                          mediaID:self.mediaID
                     
                                                     successBlock:^(id response) {
                                                         
                               
                         NSLog(@"RESPONSE %@", response);
                     
                         [self stepFour_finalizeUploadwithSuccessBlock:^(id response) {
                         
                             NSLog(@"RESPONSE %@", response);
                         
                             [self stepFive_postStatuswithSuccessBlock:^(id response) {
                                 
                                 NSLog(@"RESPONSE %@", response);
                                 
                                 //WE ARE DONE
                                 [self activityDidFinish:completed];
                                 
                                 
                             }];
                             
                             
                         
                         }];
                                                         
                                                         
                                                         
                                                         
                            } errorBlock:nil];
            
                
                
                
                
                
                
                
       
                }];
            
            
            
            }
        }
    }];
    
}

- (void)stepFive_postStatuswithSuccessBlock:(void(^)(id response))successBlock {

    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"status"] = @"hey we got the video uploaded";
    md[@"media_ids"] = self.mediaID;

    
    NSURL* postUrl = [[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    
    SLRequest *postRequest = [SLRequest
                              requestForServiceType:SLServiceTypeTwitter
                              requestMethod:SLRequestMethodPOST
                              URL:postUrl parameters:md];
    
    postRequest.account = self.twitterAccount;


    [postRequest performRequestWithHandler:
     ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         if (!error && responseData) {
             
             NSString *resp = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
             NSLog(@"restp : %@",resp);
             if (error) {
                 NSLog(@"error :%@",error);
             }
             NSError *jsonError = nil;
             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
             
             if (jsonError) {
                 error = jsonError;
             }
             
             if (successBlock) {
                 
                 
                 successBlock(json[@"id"]);
             }
         }
         else {
             if (successBlock) {
                 successBlock(nil);
             }
             
         }
     }];
    
    
}




- (void)stepFour_finalizeUploadwithSuccessBlock:(void(^)(id response))successBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"command"] = @"FINALIZE";
    md[@"media_id"] = self.mediaID;
    
    
    SLRequest *postRequest = [SLRequest
                              requestForServiceType:SLServiceTypeTwitter
                              requestMethod:SLRequestMethodPOST
                              URL:self.requestURL parameters:md];
    
    postRequest.account = self.twitterAccount;
    
    [postRequest performRequestWithHandler:
     ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         if (!error && responseData) {
             
             NSString *resp = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
             NSLog(@"restp : %@",resp);
             if (error) {
                 NSLog(@"error :%@",error);
             }
             NSError *jsonError = nil;
             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
             
             if (jsonError) {
                 error = jsonError;
             }
             
             if (successBlock) {
                 
                 
                 successBlock(json[@"media_id"]);
             }
         }
         else {
             if (successBlock) {
                 successBlock(nil);
             }
             
         }
     }];
    
}



//https://github.com/nst/STTwitter/blob/f6302b0aaaa7d670dca94bb3145507982173e281/STTwitter/STTwitterAPI.m

- (void)stepTwo_getMedia_id_withCompletion:(void(^)(NSNumber *mediaID, NSError *error))completion {
    
    NSData *data = [NSData dataWithContentsOfURL:self.videoURL];
    
    if(data == nil) {
        //TODO: error
    }
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"command"] = @"INIT";
    md[@"media_type"] = @"video/mp4";
    md[@"total_bytes"] = [NSString stringWithFormat:@"%@", @([data length])];
    
    
    
   self.requestURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    
    //Get image data
//    NSData *data = img;
//    if ([img isKindOfClass:[UIImage class]]) {
//        data = UIImagePNGRepresentation(img);
//    }
    
    


    
    SLRequest *postRequest = [SLRequest
                              requestForServiceType:SLServiceTypeTwitter
                              requestMethod:SLRequestMethodPOST
                              URL:self.requestURL parameters:md];
    
    
    
    //Setup upload TW request
    //[postRequest addMultipartData:data withName:@"media" type:@"image/png" filename:@"image.png"];
    
    postRequest.account = self.twitterAccount;
    
    //Post the request to get the media ID
    [postRequest performRequestWithHandler:
     ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         if (!error && responseData) {
             
             NSString *resp = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
             NSLog(@"restp : %@",resp);
             if (error) {
                 NSLog(@"error :%@",error);
             }
             NSError *jsonError = nil;
             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
             
             if (jsonError) {
                 error = jsonError;
             }
             
             if (completion) {
                 
                 
                 completion(json[@"media_id"],error);
             }
         }
         else {
             if (completion) {
                 completion(nil,error);
             }
             
         }
     }];
}


- (void)postMediaUploadAPPENDWithVideoURL:(NSURL *)videoMediaURL
                                  mediaID:(NSString *)mediaID
                             successBlock:(void(^)(id response))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock {
    
    // https://dev.twitter.com/rest/public/uploading-media
    // https://dev.twitter.com/rest/reference/post/media/upload-chunked
    
    NSData *data = [NSData dataWithContentsOfURL:self.videoURL];
    
    NSInteger dataLength = [data length];
    
    if(dataLength == 0) {
     //TODO: error
    }
    
    NSString *fileName = [videoMediaURL isFileURL] ? [[videoMediaURL path] lastPathComponent] : @"media.jpg";
    
    NSUInteger fiveMegaBytes = 5 * (int) pow((double) 2,20);
    
    NSUInteger segmentIndex = 0;
    
    __block id lastResponseReceived = nil;
    __block NSError *lastErrorReceived = nil;
    __block NSUInteger accumulatedBytesWritten = 0;
    
    dispatch_group_t group = dispatch_group_create();
    
    while((segmentIndex * fiveMegaBytes) < dataLength) {
        
        NSUInteger subDataLength = MIN(dataLength - segmentIndex * fiveMegaBytes, fiveMegaBytes);
        NSRange subDataRange = NSMakeRange(segmentIndex * fiveMegaBytes, subDataLength);
        NSData *subData = [data subdataWithRange:subDataRange];
        
        //NSLog(@"-- SEGMENT INDEX %lu, SUBDATA %@", segmentIndex, NSStringFromRange(subDataRange));
        
        __weak typeof(self) weakSelf = self;
        
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if(strongSelf == nil) {
                lastErrorReceived = [NSError errorWithDomain:@"STTwitter" code:9999 userInfo:nil]; // TODO: improve
                return;
            }
            
            NSMutableDictionary *md = [NSMutableDictionary dictionary];
            md[@"command"] = @"APPEND";
            md[@"media_id"] = mediaID;
            md[@"segment_index"] = [NSString stringWithFormat:@"%lu", (unsigned long)segmentIndex];
            //md[@"media"] = subData;
            //md[@"kSTPOSTDataKey"] = @"media"; //dummy var
            //md[@"kSTPOSTMediaFileNameKey"] = fileName; //dummy var
            
            //NSLog(@"-- POST %@", [md valueForKey:@"segment_index"]);
            
            
            SLRequest *postRequest = [SLRequest
                                      requestForServiceType:SLServiceTypeTwitter
                                      requestMethod:SLRequestMethodPOST
                                      URL:self.requestURL parameters:md];
            
            postRequest.account = self.twitterAccount;
            
            [postRequest addMultipartData:subData withName:@"media" type:@"video/mp4" filename:fileName];
            
            [postRequest performRequestWithHandler:
             ^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
             {
                 
                  NSLog(@"RESPONSE %@", urlResponse);
                 
                 NSLog(@"-- POST OK %@", [md valueForKey:@"segment_index"]);
                 lastResponseReceived = urlResponse;
                 dispatch_group_leave(group);
                 
                 
             }];
            
//            [strongSelf postResource:@"media/upload.json"
//                       baseURLString:kBaseURLStringUpload_1_1
//                          parameters:md
//                 uploadProgressBlock:^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
//                     accumulatedBytesWritten += bytesWritten;
//                     uploadProgressBlock(bytesWritten, accumulatedBytesWritten, dataLength);
//                 } downloadProgressBlock:nil
//                        successBlock:^(NSDictionary *rateLimits, id response) {
//                            //NSLog(@"-- POST OK %@", [md valueForKey:@"segment_index"]);
//                            lastResponseReceived = response;
//                            dispatch_group_leave(group);
//                        } errorBlock:^(NSError *error) {
//                            //NSLog(@"-- POST KO %@", [md valueForKey:@"segment_index"]);
//                            errorBlock(error);
//                            dispatch_group_leave(group);
//                        }];
        });
        
        segmentIndex += 1;
    }
    
    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSLog(@"finished");
        if(lastErrorReceived) {
            errorBlock(lastErrorReceived);
        } else {
            successBlock(lastResponseReceived);
        }
    });
}




@end