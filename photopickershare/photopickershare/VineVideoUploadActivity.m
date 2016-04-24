//
//  VineVideoUploadActivity.m
//  photopickershare
//
//  Created by jclaan on 4/21/16.
//  Copyright © 2016 jclaan. All rights reserved.
//


/*
 
 unofficial docs
 https://github.com/VineAPI/VineAPI/blob/master/endpoints.md

shows some end points
 https://github.com/songsinh88/VineKit/blob/master/VineKit/VineKit.m

 video upload
 https://github.com/bangslosan/videoslide/blob/66e2359443d5d2d2f8a479da1a0c23c91115dd2a/VideoSlide/source/Manager/SCVineManager.m
 
 
 
 CHANNEL NUMBERS
 
 'comedy'                => 1,
 'art-and-experimental'  => 2,
 'nature'                => 5,
 'family'                => 7,
 'special-fx'            => 8,
 'sports'                => 9,
 'food'                  => 10,
 'music'                 => 11,
 'beauty-and-fashion'    => 12,
 'health-and-fitness'    => 13,
 'news-and-politics'     => 14,
 'animals'               => 17
 
 
 
 */

#import "VineVideoUploadActivity.h"
#import "VineVideoUploadActivityDialog.h"
#import "VineInfo.h"


@import AVFoundation;



#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define SC_MEDIA_TYPE_MOV       AVFileTypeQuickTimeMovie

@interface VineVideoUploadActivity ()

@property (nonatomic, strong) NSArray *activityItems;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic,strong) NSString *caption;



@property (nonatomic, strong) NSURL* videoURL;
@property (nonatomic, strong) NSURL* croppedVideoURL;
@property (nonatomic, strong) UIImage* thumbnail;

@property (nonatomic,strong) VineInfo *vineInfo;
@property (nonatomic,strong) NSString* videoUploadedURL;
@property (nonatomic,strong) NSString* thumbnailUploadedURL;




@end


@implementation VineVideoUploadActivity

# pragma mark - UIActivity

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    [super prepareWithActivityItems:activityItems];
    
    self.activityItems = activityItems;
}

+ (UIActivityCategory)activityCategory {
    return UIActivityCategoryShare;
}

- (NSString *)activityType {
    return @"org.vine";
}

- (NSString *)activityTitle {
    return @"Vine";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"color_VineActivity"];
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
    
    NSString *filenameext = [[[url path] pathExtension] lowercaseString];
    
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
    
    
    
    
    
    
    VineVideoUploadActivityDialog* vineDialog = [[VineVideoUploadActivityDialog alloc] init];
    vineDialog.delegate = self;

    vineDialog.view.backgroundColor = [UIColor clearColor];
    vineDialog.modalPresentationStyle = UIModalPresentationCurrentContext;


    
    //vineDialog.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    //vineDialog.modalPresentationStyle = UIModalPresentationFormSheet;
    
    VineInfo* newVineInfo = [VineInfo new];
    
    newVineInfo.caption = self.caption;
    vineDialog.vineInfo = newVineInfo;
    
    __weak typeof(self) weakSelf = self;

    
    
    [vineDialog show:^(VineInfo* vineInfo, BOOL isOK) {
        if (isOK) {
            NSLog(@"Succeed");
            
            weakSelf.vineInfo = vineInfo;
            
            [self stepOne_prepareVideo];
            
        }
        else {
            NSLog(@"Cancel");
            [self activityDidFinish:NO];

        }
    }];
    
    
    return vineDialog;
    

    
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


- (void) stepOne_prepareVideo {
    
    _croppedVideoURL = [VineVideoUploadActivity createURLFromTempWithName:@"output.mp4"];
    
    //[self cropVideoSquareFrom:_videoURL to:_croppedVideoURL];
    
    [self convertVideoFrom:_videoURL to:_croppedVideoURL];

    //_croppedVideoURL = _videoURL;
    //[self stepTwo_LoginVine];
}


- (void) stepTwo_LoginVine {
 

    
    
    NSString *urlString = @"https://api.vineapp.com/users/authenticate";
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
   
    NSDictionary *parameters = @{@"username":_vineInfo.username, @"password":_vineInfo.password};
    
    
    [manager POST:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
    
        
        NSLog(@"JSON: %@", responseObject);
        
        
        _vineInfo.key = [[responseObject objectForKey:@"data"] objectForKey:@"key"];
        _vineInfo.userId  = [[responseObject objectForKey:@"data"] objectForKey:@"userId"];
        _vineInfo.vineUserName  = [[responseObject objectForKey:@"data"] objectForKey:@"username"];
        
        
        [self uploadVideo];
        
        //handler(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        
        NSLog(@"ERROR: %@", [error userInfo]);
        [self uploadDidFailWithError:error];
        
    }];
    


}


- (void)uploadVideo {
    
    
    NSData *videoData = [NSData dataWithContentsOfURL:self.croppedVideoURL];
    
    
    NSString *urlString = @"https://media.vineapp.com/upload/videos/1.3.1.mp4";

    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
   

    
    [request setValue:@"video/mp4" forHTTPHeaderField:@"Content-Type"];
    [request setValue:_vineInfo.key forHTTPHeaderField:@"vine-session-id"];

    
    //[request setValue:@"ios/1.3.1" forHTTPHeaderField:@"X-Vine-Client"];
    //[request setValue:@"en;q=1, fr;q=0.9, de;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5" forHTTPHeaderField:@"Accept-Language"];
    //[request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    //[request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    //[request setValue:@"iphone/1.3.1 (iPad; iOS 6.1.3; Scale/1.00)" forHTTPHeaderField:@"User-Agent"];
    
    [request setHTTPMethod: @"PUT"];
    
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[videoData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:videoData];
    
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        
         NSLog(@"JSON: %@", responseObject);
        
        NSHTTPURLResponse *res = (NSHTTPURLResponse*)operation.response;
        NSDictionary *dict = res.allHeaderFields;
        self.videoUploadedURL = [dict objectForKey:@"X-Upload-Key"];

        NSLog(@"VIDEO_URL: %@", _videoUploadedURL);
        [self uploadThumbnail];
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        
        NSLog(@"ERROR: %@", [error userInfo]);
        NSLog(@"ERROR: %@", operation.responseObject);

        [self uploadDidFailWithError:error];
        
    }];
    
    [operation start ];
    
    
    
    

}



- (void)uploadThumbnail {
    
    
    NSData *data = UIImageJPEGRepresentation(_thumbnail, 1);
    
    NSString *urlString = @"https://media.vineapp.com/upload/thumbs/1.3.1.mp4.jpg";
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setValue:_vineInfo.key forHTTPHeaderField:@"vine-session-id"];

    [request setValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    
    //[request setValue:@"ios/1.3.1" forHTTPHeaderField:@"X-Vine-Client"];
    //[request setValue:@"en;q=1, fr;q=0.9, de;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5" forHTTPHeaderField:@"Accept-Language"];
    //[request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    //[request setValue:@"iphone/1.3.1 (iPad; iOS 6.1.3; Scale/1.00)" forHTTPHeaderField:@"User-Agent"];
    
    
    [request setHTTPMethod: @"PUT"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
         NSLog(@"JSON: %@", responseObject);
        
        
        NSHTTPURLResponse *res = (NSHTTPURLResponse*)operation.response;
        NSDictionary *dict = res.allHeaderFields;
        _thumbnailUploadedURL = [dict objectForKey:@"X-Upload-Key"];
        
        NSLog(@"THUMB_URL: %@", _thumbnailUploadedURL);
        
        [self uploadVine];
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        
        NSLog(@"ERROR: %@", [error userInfo]);
        NSLog(@"ERROR: %@", operation.responseObject);
        
        [self uploadDidFailWithError:error];
        
    }];
    
    [operation start ];
    
    
    
    
    
}



- (void)uploadVine {
    
    
    
    NSString *urlString = @"https://api.vineapp.com/posts";
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    
    [request setValue:_vineInfo.key forHTTPHeaderField:@"vine-session-id"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    
    //[request setValue:@"ios/1.3.1" forHTTPHeaderField:@"X-Vine-Client"];
    //[request setValue:@"en;q=1" forHTTPHeaderField:@"Accept-Language"];
    //[request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    //[request setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    //[request setValue:@"iphone/1.3.1 (iPad; iOS 6.1.3; Scale/1.00)" forHTTPHeaderField:@"User-Agent"];
    
    
    //NSString *strParams = [NSString stringWithFormat:@"{\"videoUrl\":\"%@\",\"thumbnailUrl\":\"%@\",\"channelId\":%@,\"description\":\"%@\",\"entities\":[]}", _videoUploadedURL, _thumbnailUploadedURL, @"1", _vineInfo.caption];
    
        NSString *strParams = [NSString stringWithFormat:@"{\"videoUrl\":\"%@\",\"thumbnailUrl\":\"%@\",\"description\":\"hello\",\"channelId\":1,\"entities\":[]}", _videoUploadedURL, _thumbnailUploadedURL ];
    
    NSData *dataBody = [strParams dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[dataBody length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody:dataBody];
    
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    AFHTTPRequestOperation *operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        
        
        
        NSLog(@"JSON: %@", responseObject);
        
        
        _vineInfo.permalinkUrl = [[responseObject objectForKey:@"data"] objectForKey:@"permalinkUrl"];
        _vineInfo.postId  = [[responseObject objectForKey:@"data"] objectForKey:@"postId"];
        _vineInfo.publicVideoUrl  = [[responseObject objectForKey:@"data"] objectForKey:@"videoUrl"];
        
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        
        NSLog(@"ERROR: %@", [error userInfo]);
        NSLog(@"ERROR: %@", operation.responseObject);
        
        [self uploadDidFailWithError:error];
        
    }];
    
    [operation start ];
    
    
    
    
    
}

- (void) uploadVine2 {
    
    
    
    
    NSString *urlString = @"https://api.vineapp.com/users/authenticate";
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSDictionary *parameters = @{@"username":_vineInfo.username, @"password":_vineInfo.password};
    
    
    [manager POST:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        
        NSLog(@"JSON: %@", responseObject);
        
        
        _vineInfo.key = [[responseObject objectForKey:@"data"] objectForKey:@"key"];
        _vineInfo.userId  = [[responseObject objectForKey:@"data"] objectForKey:@"userId"];
        _vineInfo.vineUserName  = [[responseObject objectForKey:@"data"] objectForKey:@"username"];
        
        
        [self uploadVideo];
        
        //handler(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        
        NSLog(@"ERROR: %@", [error userInfo]);
        [self uploadDidFailWithError:error];
        
    }];
    
    
    
}



#pragma mark - error

- (void) uploadDidFailWithError:(NSError*)error {
    
    
    [self activityDidFinish:NO];
    
}



#pragma mark utils

+ (NSURL *)createURLFromTempWithName:(NSString *)name
{
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSString *filePath = [tmpDirectory stringByAppendingPathComponent:name];
    
    return [NSURL fileURLWithPath:filePath];
}





- (void) generateThumbFrom:(NSURL*)inputURL {
    
    
    AVAsset *asset = [AVAsset assetWithURL:inputURL];
    
    //grab a thum
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMake(1, 10);
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    _thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);  // CGImageRef won't be released by ARC
    
}



- (void) cropVideoSquareFrom:(NSURL*)inputURL to:(NSURL*)exportUrl {
    
    //load our movie Asset
    //AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"OriginalVideo" ofType:@"mov"]]];
    AVAsset *asset = [AVAsset assetWithURL:inputURL];

    
    
    //create an avassetrack with our asset
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    //create a video composition and preset some settings
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 30);
    //here we are setting its render size to its height x height (Square)
    
    //videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height);
    videoComposition.renderSize = CGSizeMake(480, 480);
    
    
    //create a video instruction
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30));
    
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    
    //Here we shift the viewing square up to the TOP of the video so we only see the top
    CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, 0 );
    
    //Use this code if you want the viewing square to be in the middle of the video
    //CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height) /2 );
    
    //Make sure the square is portrait
    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
    
    CGAffineTransform finalTransform = t2;
    [transformer setTransform:finalTransform atTime:kCMTimeZero];
    
    //add the transformer layer instructions, then add to video composition
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    //Create an Export Path to store the cropped video
    //NSString * documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //NSString *exportPath = [documentsPath stringByAppendingFormat:@"/CroppedVideo.mp4"];
    //NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
    
    //Remove any prevouis videos at that path
    [[NSFileManager defaultManager]  removeItemAtURL:exportUrl error:nil];
    
    //Export
    AVAssetExportSession* exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality] ;
    exporter.videoComposition = videoComposition;
    exporter.outputURL = exportUrl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^
     {
         dispatch_async(dispatch_get_main_queue(), ^{

             
             [self generateThumbFrom:self.croppedVideoURL];
             
             [self stepTwo_LoginVine];
             
         });
     }];
}


- (void)convertVideoFrom:(NSURL*)fromURL to:(NSURL*)toURL
{
    
    NSError *error = nil;
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:toURL fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:480], AVVideoWidthKey,
                                   [NSNumber numberWithInt:480], AVVideoHeightKey,
                                   //codecSettings, AVVideoCompressionPropertiesKey,
                                   AVVideoScalingModeResizeAspectFill
                                   ,AVVideoScalingModeKey, nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoSettings];
    
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    
    
    
    videoWriterInput.expectsMediaDataInRealTime = YES;
    
    [videoWriter addInput:videoWriterInput];
    
    AVAsset *avAsset = [[AVURLAsset alloc] initWithURL:fromURL options:nil];
    NSError *aerror = nil;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:avAsset error:&aerror];
    
    AVAssetTrack *videoTrack = [[avAsset tracksWithMediaType:AVMediaTypeVideo]objectAtIndex:0];
    
    videoWriterInput.transform = videoTrack.preferredTransform;
    
    NSDictionary *videoOptions = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                  [NSNumber numberWithInt:480], kCVPixelBufferWidthKey,
                                  [NSNumber numberWithInt:480], kCVPixelBufferHeightKey,
                                  nil];
    
    AVAssetReaderTrackOutput *asset_reader_output = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:videoOptions];
    
    [reader addOutput:asset_reader_output];
    // audio setup
    AVAssetWriterInput *audioWriterInput;
    AVAssetReader *audioReader;
    AVAssetTrack *audioTrack;
    AVAssetReaderOutput *audioReaderOutput;
    if ([[avAsset tracksWithMediaType:AVMediaTypeAudio] count] > 0) {
        audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:nil];
        audioReader = [AVAssetReader assetReaderWithAsset:avAsset error:nil];
        audioTrack = [[avAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        audioReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
        [audioReader addOutput:audioReaderOutput];
        
        [videoWriter addInput:audioWriterInput];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        
        [videoWriter startWriting];
        [videoWriter startSessionAtSourceTime:kCMTimeZero];
        [reader startReading];
        
        CMSampleBufferRef buffer;
        
        
        while ([reader status]==AVAssetReaderStatusReading)
        {
            if(![videoWriterInput isReadyForMoreMediaData])
                continue;
            
            buffer = [asset_reader_output copyNextSampleBuffer];
            
            NSLog(@"READING");
            
            if(buffer){
                [videoWriterInput appendSampleBuffer:buffer];
                CFRelease(buffer);
            }
            
            NSLog(@"WRITTING...");
            
            
        }
        
        //Finish the session:
        [videoWriterInput markAsFinished];
        
        if (audioWriterInput) {
            [videoWriter startSessionAtSourceTime:kCMTimeZero];
            [audioReader startReading];
            
            while (audioWriterInput.readyForMoreMediaData) {
                CMSampleBufferRef audioSampleBuffer;
                if ([audioReader status] == AVAssetReaderStatusReading &&
                    (audioSampleBuffer = [audioReaderOutput copyNextSampleBuffer])) {
                    if (audioSampleBuffer) {
                        printf("write audio  ");
                        [audioWriterInput appendSampleBuffer:audioSampleBuffer];
                    }
                    CFRelease(audioSampleBuffer);
                } else {
                    [audioWriterInput markAsFinished];
                    switch ([audioReader status]) {
                        case AVAssetReaderStatusCompleted:
                        {
                            
                        }
                    }
                }
            }
        }
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            [videoWriter endSessionAtSourceTime:avAsset.duration];
            [videoWriter finishWritingWithCompletionHandler:^{
   
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self generateThumbFrom:self.croppedVideoURL];
                    
                    [self stepTwo_LoginVine];
                    
                });
            
            }];
            
   
            
        });
    });
    
}




@end
