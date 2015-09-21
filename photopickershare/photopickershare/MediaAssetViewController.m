

#import "MediaAssetViewController.h"
#import "TwitterVideoUploadActivity.h"
#import "ICGVideoTrimmerView.h"
#import "MBProgressHUD.h"
#import "PHAsset+Utility.h"
#import "constants.h"

@import Photos;


@implementation CIImage (Convenience)
- (NSData *)aapl_jpegRepresentationWithCompressionQuality:(CGFloat)compressionQuality {
	static CIContext *ciContext = nil;
	if (!ciContext) {
		EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		ciContext = [CIContext contextWithEAGLContext:eaglContext];
	}
	CGImageRef outputImageRef = [ciContext createCGImage:self fromRect:[self extent]];
	UIImage *uiImage = [[UIImage alloc] initWithCGImage:outputImageRef scale:1.0 orientation:UIImageOrientationUp];
	if (outputImageRef) {
		CGImageRelease(outputImageRef);
	}
	NSData *jpegRepresentation = UIImageJPEGRepresentation(uiImage, compressionQuality);
	return jpegRepresentation;
}
@end


@interface MediaAssetViewController () <PHPhotoLibraryChangeObserver,ICGVideoTrimmerDelegate>
@property (strong)  UIImageView *imageView;
@property (strong)  NSURL  *videoURL;
@property (strong)  UIBarButtonItem *playButton;
@property (strong)  UIBarButtonItem *space;
@property (strong)  UIBarButtonItem *trashButton;
@property (strong)  UIBarButtonItem *editButton;
@property (strong)  UIProgressView *progressView;
@property (strong) AVPlayerLayer *playerLayer;
@property (assign) CGSize lastImageViewSize;

@property (strong) UIToolbar *toolbar;


//trimmer
@property (strong, nonatomic)  ICGVideoTrimmerView *trimmerView;

@property (strong, nonatomic) NSString *tempVideoPath;
@property (strong, nonatomic) AVAssetExportSession *exportSession;
@property (strong, nonatomic) AVAsset *avasset;

@property (assign, nonatomic) CGFloat startTime;
@property (assign, nonatomic) CGFloat stopTime;

@property (strong, nonatomic) UIButton *doTrimButton;
@property (strong, nonatomic) UIButton *cancelTrimButton;

@end


@implementation MediaAssetViewController

static NSString * const AdjustmentFormatIdentifier = @"com.laan.labs.photopicker";

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

-(void)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{ NSLog(@"controller dismissed"); }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];

    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(close:)];
    
    
    self.space = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                 target:nil
                                 action:nil];
    
    
    self.progressView = [[UIProgressView alloc] init];
    self.progressView.frame = CGRectMake(10,self.view.frame.size.height/2,self.view.frame.size.width-20,20);
    [self.view addSubview:self.progressView];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) ];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    
    
    
    self.playButton = [[UIBarButtonItem alloc]
                                    initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                    target:self
                                    action:@selector(handlePlayButtonItem:)];
    
    
    UIBarButtonItem* shareButton = [[UIBarButtonItem alloc]
                       initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                       target:self
                       action:@selector(handleShareButtonItem:)];
    
    UIBarButtonItem* trimButton = [[UIBarButtonItem alloc]
                                    initWithTitle:@"Trim"
                                    style:UIBarButtonItemStylePlain
                                   target:self
                                    action:@selector(handleTrimButton:)];
    
    
    UIBarButtonItem* gifButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"GIF"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(handleGIFButton:)];

    
    self.toolbar = [[UIToolbar alloc] init];
    self.toolbar.frame = CGRectMake(0, self.view.frame.size.height-44, self.view.frame.size.width, 44);
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    
    if (self.asset.mediaType == PHAssetMediaTypeVideo) {
        [self setUpVideo];
        [items addObject:self.playButton];
        [items addObject:self.space];
        [items addObject:trimButton];
        [items addObject:self.space];
        [items addObject:gifButton];
        [items addObject:self.space];
        [items addObject:shareButton];
    } else {
        [items addObject:self.space];
        [items addObject:shareButton];

        
        
    }
    
    
    //[items addObject:[[[UIBarButtonItem alloc] initWith....] autorelease]];
    [self.toolbar setItems:items animated:NO];
    [self.view addSubview:self.toolbar];

    
    //add trimmer and hide it
    if (self.asset.mediaType == PHAssetMediaTypeVideo) {
        
        self.trimmerView = [[ICGVideoTrimmerView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-100, self.view.frame.size.width, 100)];
        
        self.trimmerView.hidden = YES;
        [self.view addSubview:self.trimmerView];
        
        
        self.doTrimButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.doTrimButton.frame = CGRectMake(0, self.view.frame.size.height-100-40, self.view.frame.size.width/2, 40);
        self.doTrimButton.backgroundColor = [UIColor lightGrayColor];
        [self.doTrimButton setTitle:@"Trim Video" forState:UIControlStateNormal];
        [self.doTrimButton addTarget:self action:@selector(doTrimButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        self.doTrimButton.hidden = YES;
        [self.view addSubview:self.doTrimButton];
        
        self.cancelTrimButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.cancelTrimButton.frame = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height-100-40, self.view.frame.size.width/2, 40);
        self.cancelTrimButton.backgroundColor = [UIColor darkGrayColor];
        [self.cancelTrimButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [self.cancelTrimButton addTarget:self action:@selector(cancelTrimButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        self.cancelTrimButton.hidden = YES;
        [self.view addSubview:self.cancelTrimButton];
        
        
    }
    
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.asset.mediaType == PHAssetMediaTypeVideo) {
         self.toolbarItems = @[self.playButton, self.space];
        //self.toolbarItems = @[self.playButton, self.space, self.trashButton];
    } else {
        //self.toolbarItems = @[self.space, self.trashButton];
    }
    
//    BOOL isEditable = ([self.asset canPerformEditOperation:PHAssetEditOperationProperties] || [self.asset canPerformEditOperation:PHAssetEditOperationContent]);
//    self.editButton.enabled = isEditable;
//    
//    BOOL isTrashable = NO;
//    if (self.assetCollection) {
//        isTrashable = [self.assetCollection canPerformEditOperation:PHCollectionEditOperationRemoveContent];
//    } else {
//        isTrashable = [self.asset canPerformEditOperation:PHAssetEditOperationDelete];
//    }
//    self.trashButton.enabled = isTrashable;
    
    [self.view layoutIfNeeded];
    [self updateImage];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Disable iOS 7 back gesture
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        //self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Enable iOS 7 back gesture
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return NO;
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (!CGSizeEqualToSize(self.imageView.bounds.size, self.lastImageViewSize)) {
        [self updateImage];
    }
}

- (void)updateImage
{
    self.lastImageViewSize = self.imageView.bounds.size;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize targetSize = CGSizeMake(CGRectGetWidth(self.imageView.bounds) * scale, CGRectGetHeight(self.imageView.bounds) * scale);
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    
    // Download from cloud if necessary
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
            self.progressView.hidden = (progress <= 0.0 || progress >= 1.0);
        });
    };
    
    [[PHImageManager defaultManager] requestImageForAsset:self.asset targetSize:targetSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        if (result) {
            self.imageView.image = result;
        }
    }];
}

-(void) setUpVideo {
    
    if (!self.playerLayer) {
        [[PHImageManager defaultManager] requestAVAssetForVideo:self.asset options:nil resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!self.playerLayer) {
                    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:avAsset];
                    
                    
                    AVURLAsset* avURL =(AVURLAsset*)avAsset;
                    NSURL* url =(NSURL*)[avURL URL];
                    
                    self.videoURL = (NSURL*)url;
                    
                    
                    
                    playerItem.audioMix = audioMix;
                    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
                    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
                    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                    
                    CALayer *layer = self.view.layer;
                    [layer addSublayer:self.playerLayer];
                    [self.playerLayer setFrame:layer.bounds];
                    
                    
                }
            });
        }];
        
    }
    
}



#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // check if there are changes to the album we're interested on (to its metadata, not to its collection of assets)
        PHObjectChangeDetails *changeDetails = [changeInstance changeDetailsForObject:self.asset];
        if (changeDetails) {
            // it changed, we need to fetch a new one
            self.asset = [changeDetails objectAfterChanges];
            
            if ([changeDetails assetContentChanged]) {
                [self updateImage];
                
                if (self.playerLayer) {
                    [self.playerLayer removeFromSuperlayer];
                    self.playerLayer = nil;
                }
            }
        }
        
    });
}

#pragma mark - Actions

- (void)applyFilterWithName:(NSString *)filterName
{
    PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
    [options setCanHandleAdjustmentData:^BOOL(PHAdjustmentData *adjustmentData) {
        return [adjustmentData.formatIdentifier isEqualToString:AdjustmentFormatIdentifier] && [adjustmentData.formatVersion isEqualToString:@"1.0"];
    }];
    [self.asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
        // Get full image
        NSURL *url = [contentEditingInput fullSizeImageURL];
        int orientation = [contentEditingInput fullSizeImageOrientation];
        CIImage *inputImage = [CIImage imageWithContentsOfURL:url options:nil];
        inputImage = [inputImage imageByApplyingOrientation:orientation];

        // Add filter
        CIFilter *filter = [CIFilter filterWithName:filterName];
        [filter setDefaults];
        [filter setValue:inputImage forKey:kCIInputImageKey];
        CIImage *outputImage = [filter outputImage];

        // Create editing output
        NSData *jpegData = [outputImage aapl_jpegRepresentationWithCompressionQuality:0.9f];
        PHAdjustmentData *adjustmentData = [[PHAdjustmentData alloc] initWithFormatIdentifier:AdjustmentFormatIdentifier formatVersion:@"1.0" data:[filterName dataUsingEncoding:NSUTF8StringEncoding]];
        
        PHContentEditingOutput *contentEditingOutput = [[PHContentEditingOutput alloc] initWithContentEditingInput:contentEditingInput];
        [jpegData writeToURL:[contentEditingOutput renderedContentURL] atomically:YES];
        [contentEditingOutput setAdjustmentData:adjustmentData];
        
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:self.asset];
            request.contentEditingOutput = contentEditingOutput;
        } completionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Error: %@", error);
            }
        }];
    }];
}

- (IBAction)handleEditButtonItem:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:NULL]];

    if ([self.asset canPerformEditOperation:PHAssetEditOperationProperties]) {
        NSString *favoriteActionTitle = !self.asset.favorite ? NSLocalizedString(@"Favorite", @"") : NSLocalizedString(@"Unfavorite", @"");
        [alertController addAction:[UIAlertAction actionWithTitle:favoriteActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:self.asset];
                [request setFavorite:![self.asset isFavorite]];
            } completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    NSLog(@"Error: %@", error);
                }
            }];
        }]];
    }
    if ([self.asset canPerformEditOperation:PHAssetEditOperationContent]) {
        if (self.asset.mediaType == PHAssetMediaTypeImage) {
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sepia", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self applyFilterWithName:@"CISepiaTone"];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Chrome", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self applyFilterWithName:@"CIPhotoEffectChrome"];
            }]];
        }
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Revert", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetChangeRequest *request = [PHAssetChangeRequest changeRequestForAsset:self.asset];
                [request revertAssetContentToOriginal];
            } completionHandler:^(BOOL success, NSError *error) {
                if (!success) {
                    NSLog(@"Error: %@", error);
                }
            }];
        }]];
    }
	alertController.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:alertController animated:YES completion:NULL];
	alertController.popoverPresentationController.barButtonItem = sender;
	alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
}

- (IBAction)handleTrashButtonItem:(id)sender
{
    void (^completionHandler)(BOOL, NSError *) = ^(BOOL success, NSError *error) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self navigationController] popViewControllerAnimated:YES];
            });
        } else {
            NSLog(@"Error: %@", error);
        }
    };
    
    if (self.assetCollection) {
        // Remove asset from album
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.assetCollection];
            [changeRequest removeAssets:@[self.asset]];
        } completionHandler:completionHandler];
        
    } else {
        // Delete asset from library
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest deleteAssets:@[self.asset]];
        } completionHandler:completionHandler];
        
    }
}

#pragma mark - BUTTON ITEMS

- (void)handleGIFButton:(id)sender
{
    
    
}








- (void)handlePlayButtonItem:(id)sender
{

        if (self.playerLayer.player.rate > 0 && !self.playerLayer.player.error) {
            [self.playerLayer.player pause];
        } else {
            [self.playerLayer.player.currentItem seekToTime:kCMTimeZero];
           [self.playerLayer.player play];
        }
        
        
    
    
    UIBarButtonItem *pause = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pauseClick:)];
    NSMutableArray *tbItems = [self.toolbar.items mutableCopy];
    NSInteger index=[tbItems indexOfObject:self.playButton];
    self.toolbar.items = tbItems;
    self.playButton = pause;
    [tbItems replaceObjectAtIndex:index withObject:pause];
    self.toolbar.items = tbItems;
    
    
}




-(void)pauseClick:(UIBarButtonItem *)sender {
    
    if (self.playerLayer.player.rate > 0 && !self.playerLayer.player.error) {
        [self.playerLayer.player pause];
    }
    
    
    UIBarButtonItem *play = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(handlePlayButtonItem:)];
    NSMutableArray *tbItems = [self.toolbar.items mutableCopy];
    NSInteger index=[tbItems indexOfObject:self.playButton];
    
    self.playButton = play;
    [tbItems replaceObjectAtIndex:index withObject:play];
    self.toolbar.items = tbItems;
    
    
    
}

- (void)handleShareButtonItem:(id)sender
{
    
    
    NSArray * shareItems = @[];
    
    if (self.asset.mediaType == PHAssetMediaTypeVideo) {
  
        
        NSString * message = @"My too cool Son";
        shareItems = @[message, self.videoURL];
        
        
    } else {
        
        NSString * message = @"My too cool Son";
        shareItems = @[message, self.imageView.image];
        
    }
    
    
  
    
    TwitterVideoUploadActivity *activity = [[TwitterVideoUploadActivity alloc] init];
    
    //-- initialising the activity view controller
    UIActivityViewController *avc = [[UIActivityViewController alloc]
                                     initWithActivityItems:shareItems
                                     applicationActivities:@[activity]];
    
    
    //avc.excludedActivityTypes = @[UIActivityTypePostToWeibo, UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard ];
    
    /*
     
     UIActivityTypePostToFacebook
     UIActivityTypePostToTwitter
     UIActivityTypePostToWeibo
     UIActivityTypeMessage
     UIActivityTypeMail
     UIActivityTypePrint
     UIActivityTypeCopyToPasteboard
     UIActivityTypeAssignToContact
     UIActivityTypeSaveToCameraRoll
     UIActivityTypeAddToReadingList
     UIActivityTypePostToFlickr
     UIActivityTypePostToVimeo
     UIActivityTypePostToTencentWeibo
     UIActivityTypeAirDrop
     */
    
    
    
    //-- define the activity view completion handler
    avc.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError)
    {
        
        NSLog(@"ERROR: %@", activityError);
        
        if (completed) {
            NSLog(@"Selected activity was performed.");
        } else {
            if (activityType == NULL) {
                NSLog(@"User dismissed the view controller without making a selection.");
            } else {
                NSLog(@"Activity was not performed.");
            }
        }
    };
    
    
    [self presentViewController:avc animated:YES completion:nil];
    

 
    
    
}


#pragma mark - ICGVideoTrimmerDelegate

- (void)handleTrimButton:(id)sender
{
    
    self.avasset = [AVAsset assetWithURL:self.videoURL];
    
    // set properties for trimmer view
    [self.trimmerView setThemeColor:[UIColor lightGrayColor]];
    [self.trimmerView setAsset:self.avasset];
    [self.trimmerView setShowsRulerView:YES];
    [self.trimmerView setDelegate:self];
    
    self.trimmerView.hidden = NO;
    self.doTrimButton.hidden = NO;
    self.cancelTrimButton.hidden = NO;
    
    // important: reset subviews
    [self.trimmerView resetSubviews];
    
    
}

- (void)doTrimButtonClicked:(id)sender
{
    
    self.tempVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmpMov.mov"];
    
    [self deleteTempFile];
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:self.avasset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        
        self.exportSession = [[AVAssetExportSession alloc]
                              initWithAsset:self.avasset presetName:AVAssetExportPresetPassthrough];
        // Implementation continues.
        
        NSURL *furl = [NSURL fileURLWithPath:self.tempVideoPath];
        
        self.exportSession.outputURL = furl;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        CMTime start = CMTimeMakeWithSeconds(self.startTime, self.avasset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(self.stopTime - self.startTime, self.avasset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        self.exportSession.timeRange = range;
        
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            switch ([self.exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    
                    NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    
                    NSLog(@"Export canceled");
                    break;
                default:
                    NSLog(@"NONE");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        NSURL *movieUrl = [NSURL fileURLWithPath:self.tempVideoPath];
                        
                        [self saveVideoFromURL:movieUrl];
                        
                       // UISaveVideoAtPathToSavedPhotosAlbum([movieUrl relativePath], self,@selector(video:didFinishSavingWithError:contextInfo:), nil);
                    });
                    
                    break;
            }
        }];
        
    }

    
    
    
}




- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}


- (void) saveVideoFromURL:(NSURL*)movieURL {
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [PHAsset saveVideoAtURL:movieURL location:nil completionBlock:^(PHAsset *asset, BOOL success) {
                if(success){
                    NSLog(@"Success adding video to Photos");
                    hud.labelText = @"Writing video...";
                    [asset saveToAlbum:FACESWAPPERALBUM completionBlock:^(BOOL success) {
                        if(success){
                            NSLog(@"Success adding video to App Album");
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [UIView animateWithDuration:0.3 animations:^{
                                    //self.exitButton.alpha = 1.0;
                                    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                    
                                    [self videoTrimCompleteWithAsset:asset];
                                    
                                }];
                            });
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                            });
                            NSLog(@"Error adding video to App Album");
                        }
                    }];
                } else {
                    NSLog(@"Error adding video to Photos");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                    });
                }
            }];
        });
    }];
    
    
}


- (void) videoTrimCompleteWithAsset:(PHAsset*)asset {
    
    [self hideTrimmer];
    
    self.asset = asset;
    
    [self updateImage];
    
    self.playerLayer = nil;
    
    [self setUpVideo];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Trimmed" message:@"Saved To Photo Album"
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}


- (void)deleteTempFile
{
    NSURL *url = [NSURL fileURLWithPath:self.tempVideoPath];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:url.path];
    NSError *err;
    if (exist) {
        [fm removeItemAtURL:url error:&err];
        NSLog(@"file deleted");
        if (err) {
            NSLog(@"file remove error, %@", err.localizedDescription );
        }
    } else {
        NSLog(@"no file by that name");
    }
}


- (void)cancelTrimButtonClicked:(id)sender
{
    
    [self hideTrimmer];
    
}


- (void) hideTrimmer {
    self.trimmerView.hidden = YES;
    self.doTrimButton.hidden = YES;
    self.cancelTrimButton.hidden = YES;
}


- (void)trimmerView:(ICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime
{
    self.startTime = startTime;
    self.stopTime = endTime;
}


@end


