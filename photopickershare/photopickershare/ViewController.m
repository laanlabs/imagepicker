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

@interface ViewController ()
@property (strong) UIImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
     [self.view setBackgroundColor:[UIColor greenColor]];
    
    UIButton* pickerBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    pickerBtn.frame = CGRectMake(20, 40, 120, 40);
    pickerBtn.backgroundColor = [UIColor blueColor];
    [pickerBtn setTitle:@"Open Images" forState:UIControlStateNormal];
    [pickerBtn addTarget:self action:@selector(openMediaPicker:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pickerBtn];
    
    
    UIButton* shareBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    shareBtn.frame = CGRectMake(20, 80, 120, 40);
    shareBtn.backgroundColor = [UIColor blueColor];
    [shareBtn setTitle:@"share" forState:UIControlStateNormal];
    [shareBtn addTarget:self action:@selector(shareButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:shareBtn];
    
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 200, 120, 40) ];
    
      self.imageView.image = [UIImage imageNamed:@"wine"];
    
    [self.view addSubview:self.imageView];
    
    
}


- (void) openMediaPicker:(id)sender {
    
    
    MediaAlbumsListViewController *vc = [[MediaAlbumsListViewController alloc] init];
    
    UINavigationController *nc=[[UINavigationController alloc]initWithRootViewController:vc];
    

    [self presentViewController:nc animated:YES completion:nil];
    
}

- (void)shareButtonClicked:(id)sender {
    
    
  

    
    //-- set strings and URLs
    NSString *textObject = @"Information that I want to tweet or share";
    NSString *urlString = [NSString stringWithFormat:@"http://www.mygreatdomain/%@", @"asfdads"];
    
    NSString * message = @"My too cool Son";
    
    UIImage * image = [UIImage imageNamed:@"wine.png"];
    
    NSString*thePath=[[NSBundle mainBundle] pathForResource:@"trim" ofType:@"mp4"];
    NSURL*theurl=[NSURL fileURLWithPath:thePath];
    
    
    
    
    NSArray *shareItems = [NSArray arrayWithObjects: message, theurl, nil];
    
    
    //NSArray * shareItems = @[message, image];
    
    //NSURL *url = [NSURL URLWithString:urlString];
    
    //NSArray *activityItems = [NSArray arrayWithObjects:textObject, url,  nil];
    
    
    TwitterVideoUploadActivity *activity = [[TwitterVideoUploadActivity alloc] init];
    
    //-- initialising the activity view controller
    UIActivityViewController *avc = [[UIActivityViewController alloc]
                                     initWithActivityItems:shareItems
                                     applicationActivities:@[activity]];
    
    
    //avc.excludedActivityTypes = @[UIActivityTypePostToWeibo, UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard ];
    
    
    //-- define the activity view completion handler
    avc.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError)
    {
        if (completed) {
            // NSLog(@"Selected activity was performed.");
        } else {
            if (activityType == NULL) {
                //   NSLog(@"User dismissed the view controller without making a selection.");
            } else {
                //  NSLog(@"Activity was not performed.");
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
