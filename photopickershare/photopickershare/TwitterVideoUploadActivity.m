//
//  TwitterVideoUploadActivity.m
//  photopickershare
//
//  Created by jclaan on 9/19/15.
//  Copyright © 2015 jclaan. All rights reserved.
//


/*
 
 
 step 1 -- get twitter account
 step 2 -- INIT video
 step 3 -- upload video in 5MB chunks
 step 4 -- finalize video
 step 5 -- send twitter status
 
 
 
 */


#import "TwitterVideoUploadActivity.h"

#import <Social/Social.h>

@import Accounts;
@import AVFoundation;

@interface TwitterVideoUploadActivity ()

@property (nonatomic, strong) NSArray *activityItems;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) ACAccount* twitterAccount;
@property (nonatomic, strong) NSURL* videoURL;
@property (nonatomic,strong) NSString *caption;
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
            
            if ( [self isMovieFile:url]) {
                self.videoURL = url;
                return YES;
            };
        }
    }
    
    
    
    return NO;
}


- (BOOL) isMovieFile:(NSURL*)url {
    
    NSString *filenameext = [[url path] pathExtension];
    
    if ([filenameext isEqualToString:@"mov"] || [filenameext isEqualToString:@"mp4"] || [filenameext isEqualToString:@"m4v"] ) {
        return YES;
    }
    
      return NO;
}



- (UIViewController *)activityViewController {
//    SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
//    return [self activityViewControllerWithComposeViewController:composeViewController];
//    
//    
//    
//
    
    
    
    
    //check for video length for twitter
    
    AVAsset *movie = [AVAsset assetWithURL:self.videoURL];
    CGFloat movieLength = CMTimeGetSeconds(movie.duration);
    
    if (movieLength > 30.0) {
        
        UIAlertController * videoError=   [UIAlertController
                                                  alertControllerWithTitle:@"Error"
                                                  message:@"Your Video is longer than 30 seconds - please trim your video as Twitter has a max length of 30 seconds."
                                                  preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       //Do Some action here
                                              
                                                       [self activityDidFinish:NO];
                                                       
                                                       
                                                   }];
        
        [videoError addAction:ok];
        
        return videoError;
        
    }
    
    
    //get caption
    self.caption = [self firstStringOrEmptyStringFromArray:self.activityItems];
    
    
    UIAlertController * twitterVideoShare=   [UIAlertController
                                  alertControllerWithTitle:@"Share Video On Twitter"
                                  message:@"With Caption:"
                                  preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action) {
                                                   //Do Some action here
                                                   
                                                   [self stepOne_getTwitterAccount];
                                                   
                                               }];
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       //[alert dismissViewControllerAnimated:YES completion:nil];
                                                       

                                                       
                                                       
                                                       [self activityDidFinish:NO];
                                                       
                                                   }];
  
    
    [twitterVideoShare addAction:ok];
    [twitterVideoShare addAction:cancel];
    
    

    
    
    [twitterVideoShare addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Caption";
        textField.text = self.caption;
    }];
    
    
    return twitterVideoShare;
    
    
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


- (void)performActivity
{
    // THIS DOESNT GET CALLED
    

    

}

# pragma mark - UPLOAD STEPS

- (void) stepOne_getTwitterAccount {
    
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        if (!granted) {
            NSLog(@"Access denied.");
            [self activityDidFinish:NO];
            return;
        }
        else {
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            if (accounts.count > 0) {
               self.twitterAccount = [accounts objectAtIndex:0];
                
                
                //START
                [self stepTwo_getMedia_id_withCompletion:^(NSNumber *mediaID, NSError *error) {
                    
                    if (error) {
                        [self activityDidFinish:NO];
                        return;
                    }
                    
                    
                    
                    NSLog(@"MEDIA ID: %@", mediaID);
                    
                    self.mediaID = [mediaID stringValue];
                    
                    //__strong typeof(self) strongSelf = self;
      
                    
                    //this one has its own error block
                    [self stepThree_APPEND_videoWithsuccessBlock:^(id response) {
                                                         
                               
                         NSLog(@"RESPONSE %@", response);
                     
                         [self stepFour_finalizeUploadwithSuccessBlock:^(id response, NSError *error) {
                             if (error) {
                                 [self activityDidFinish:NO];
                                 return;
                             }
                             
                             
                             NSLog(@"RESPONSE %@", response);
                         
                             [self stepFive_postStatuswithSuccessBlock:^(id response, NSError *error) {
                                 if (error) {
                                     [self activityDidFinish:NO];
                                     return;
                                 }
                                 
                                 NSLog(@"RESPONSE %@", response);
                                 
                                 //WE ARE DONE
                                 [self activityDidFinish:YES];
                                 
                                 
                             }];
                             
                             
                         
                         }];
                                                         
                                                         
                                                         
                    //STEP 3 ERROR Block
                    } errorBlock:^(NSError* error){
                    
                     [self activityDidFinish:NO];
                    
                    }];
            
                
                
                
                
                
                
                
       
                }];
            
            
            
            }
        }
    }];
    
}

- (void)stepFive_postStatuswithSuccessBlock:(void(^)(id response, NSError *error))successBlock {

    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"status"] = self.caption;
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
                 
                 
                 successBlock(json[@"id"],nil);
             }
         }
         else {
             if (successBlock) {
                 successBlock(nil,error);
             }
             
         }
     }];
    
    
}




- (void)stepFour_finalizeUploadwithSuccessBlock:(void(^)(id response, NSError *error))successBlock {
    
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
                 
                 
                 successBlock(json[@"media_id"], nil);
             }
         }
         else {
             if (successBlock) {
                 successBlock(nil, error);
             }
             
         }
     }];
    
}





- (void)stepTwo_getMedia_id_withCompletion:(void(^)(NSNumber *mediaID, NSError *error))completion {
    
    NSData *data = [NSData dataWithContentsOfURL:self.videoURL];
    
    if(data == nil) {
        //TODO: error
        NSError *error = nil;
        error = [NSError errorWithDomain:@"com.laan.labs" code:200 userInfo:@{@"Error reason": @"File is Nil"}];
        
        completion(nil,error);
    }
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"command"] = @"INIT";
    md[@"media_type"] = @"video/mp4";
    md[@"total_bytes"] = [NSString stringWithFormat:@"%@", @([data length])];
    
    
    
   self.requestURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    

    
    SLRequest *postRequest = [SLRequest
                              requestForServiceType:SLServiceTypeTwitter
                              requestMethod:SLRequestMethodPOST
                              URL:self.requestURL parameters:md];
    
    
   
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


- (void)stepThree_APPEND_videoWithsuccessBlock:(void(^)(id response))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock {
    
    // https://dev.twitter.com/rest/public/uploading-media
    // https://dev.twitter.com/rest/reference/post/media/upload-chunked
    
    NSData *data = [NSData dataWithContentsOfURL:self.videoURL];
    
    NSInteger dataLength = [data length];
    
    if(dataLength == 0) {
     //TODO: error
    }
    
    NSString *fileName = [self.videoURL lastPathComponent];
    
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
            md[@"media_id"] = self.mediaID;
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