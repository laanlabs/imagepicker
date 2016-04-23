//
//  ViewController.m
//  photopickershare
//
//  Created by jclaan on 9/16/15.
//  Copyright (c) 2015 jclaan. All rights reserved.
//

#import "ViewController.h"
#import "MediaAlbumsListViewController.h"
#import "TwitterVideoUploadActivity.h"

#import "VineVideoUploadActivity.h"


#import <MobileCoreServices/UTCoreTypes.h>
#import "PHAsset+Utility.h"
#import "MBProgressHUD.h"
#import "constants.h"

@import Photos;

@interface ViewController () <PHPhotoLibraryChangeObserver>
@property (strong) UIImageView *imageView;
@property (strong) NSURL *movieURL;
@property (strong) UIImage* image;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
     [self.view setBackgroundColor:[UIColor greenColor]];
    
    UIButton* pickerBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    pickerBtn.frame = CGRectMake(20, 40, 200, 40);
    pickerBtn.backgroundColor = [UIColor blueColor];
    [pickerBtn setTitle:@"Open UIPICKER" forState:UIControlStateNormal];
    [pickerBtn addTarget:self action:@selector(openUIMediaPicker:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pickerBtn];
 
    
    UIButton* customPickerBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    customPickerBtn.frame = CGRectMake(20, 90, 200, 40);
    customPickerBtn.backgroundColor = [UIColor blueColor];
    [customPickerBtn setTitle:@"Open custom picker" forState:UIControlStateNormal];
    [customPickerBtn addTarget:self action:@selector(openMediaPicker:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:customPickerBtn];
    
   
    UIButton* saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    saveBtn.frame = CGRectMake(20, 140, 200, 40);
    saveBtn.backgroundColor = [UIColor blueColor];
    [saveBtn setTitle:@"save to album" forState:UIControlStateNormal];
    [saveBtn addTarget:self action:@selector(saveButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveBtn];
    
    
    UIButton* shareBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    shareBtn.frame = CGRectMake(20, 190, 200, 40);
    shareBtn.backgroundColor = [UIColor blueColor];
    [shareBtn setTitle:@"share" forState:UIControlStateNormal];
    [shareBtn addTarget:self action:@selector(shareButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shareBtn];
    
 
    

    
    //add image or video
    
    NSString*thePath=[[NSBundle mainBundle] pathForResource:@"trim" ofType:@"mp4"];
    self.movieURL = [NSURL fileURLWithPath:thePath];
    
    self.image= [UIImage imageNamed:@"wine"];
    
    
    //make dummy image view
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 400, 120, 40) ];
    
    self.imageView.image = self.image;
    
    [self.view addSubview:self.imageView];
    
    
}




- (void) openUIMediaPicker:(id)sender {
    
    
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];

    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, kUTTypeImage,      nil];
    
    
    [imagePicker setAllowsEditing:YES];
    [imagePicker setDelegate:self];
    
    //place image picker on the screen
    [self presentViewController:imagePicker animated:YES completion:nil];
    
    
}


-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    

    [self dismissViewControllerAnimated:YES completion:NULL];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if ([mediaType isEqualToString:@"public.image"]){
        
        UIImage * pickedImage = [info objectForKey:UIImagePickerControllerOriginalImage];

        self.image = pickedImage;
        self.imageView.image = self.image;
    }
    
    else if ([mediaType isEqualToString:@"public.movie"]){
        
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        
        self.movieURL = videoURL;
        
        self.image = [self thumbnailImageForVideo:self.movieURL];
        self.imageView.image = self.image;
        
        
    }
    


}


- (UIImage*) thumbnailImageForVideo:(NSURL *)sourceURL
{
    AVAsset *asset = [AVAsset assetWithURL:sourceURL];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    NSError *err = NULL;
    CMTime time = CMTimeMake(1, 1);
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&err];
    NSLog(@"err==%@, imageRef==%@", err, imageRef);
    UIImage *thumbnail = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef); // CGImageRef won't be released by ARC
    return thumbnail;
}



#pragma mark - CUSTOM PICKER

- (void) openMediaPicker:(id)sender {
    
    
    [PHAsset ensureAlbumExistsWithTitle:FACESWAPPERALBUM];
    
    MediaAlbumsListViewController *vc = [[MediaAlbumsListViewController alloc] init];

    vc.prefferedAlbum = FACESWAPPERALBUM;
    UINavigationController *nc=[[UINavigationController alloc]initWithRootViewController:vc];


    [self presentViewController:nc animated:YES completion:nil];
    
    
    

    
    
}

#pragma mark - SAVE



- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    NSLog(@"Here");
}

- (void) getPhotoPermission {
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            
            NSLog(@"HAVE PHOTO PERMS");
            [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
        } else {
            
        }
    }];
    
}


- (void)saveButtonClicked:(id)sender {

    
    
    //[self saveVideo];
    [self saveImage];
    
}




- (void) saveVideo {
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
      
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [PHAsset saveVideoAtURL:self.movieURL location:nil completionBlock:^(PHAsset *asset, BOOL success) {
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


- (void) saveImage {
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [PHAsset saveImageToCameraRoll:self.image location:nil completionBlock:^(PHAsset *asset, BOOL success) {
                if(success){
                    NSLog(@"Success adding image to Photos");
                    hud.labelText = @"Writing image...";
                    [asset saveToAlbum:FACESWAPPERALBUM completionBlock:^(BOOL success) {
                        if(success){
                            NSLog(@"Success adding video to App Album");
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [UIView animateWithDuration:0.3 animations:^{
                                    //self.exitButton.alpha = 1.0;
                                    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                                }];
                            });
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                            });
                            NSLog(@"Error adding image to App Album");
                        }
                    }];
                } else {
                    NSLog(@"Error adding image to Photos");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                    });
                }
            }];
        });
    }];
    
    
}





#pragma mark - SHARE



- (void)shareButtonClicked:(id)sender {
    
    
  

    
    //-- set strings and URLs
    NSString *textObject = @"Information that I want to tweet or share";
    NSString *urlString = [NSString stringWithFormat:@"http://www.mygreatdomain/%@", @"asfdads"];
    
    NSString * message = @"My too cool Son";
    
    UIImage * image = [UIImage imageNamed:@"wine.png"];
    
    NSString*thePath=[[NSBundle mainBundle] pathForResource:@"test" ofType:@"MOV"];
    NSURL*theurl=[NSURL fileURLWithPath:thePath];
    
    
    
    
    NSArray *shareItems = [NSArray arrayWithObjects: message, theurl, nil];
    
    
    //NSArray * shareItems = @[message, image];
    
    //NSURL *url = [NSURL URLWithString:urlString];
    
    //NSArray *activityItems = [NSArray arrayWithObjects:textObject, url,  nil];
    
    
    TwitterVideoUploadActivity *activity = [[TwitterVideoUploadActivity alloc] init];
    
    VineVideoUploadActivity *activityVine = [[VineVideoUploadActivity alloc] init];

    
    //-- initialising the activity view controller
    UIActivityViewController *avc = [[UIActivityViewController alloc]
                                     initWithActivityItems:shareItems
                                     applicationActivities:@[activity,activityVine]];
    
    
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
