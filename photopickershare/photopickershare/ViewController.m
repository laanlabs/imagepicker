//
//  ViewController.m
//  photopickershare
//
//  Created by jclaan on 9/16/15.
//  Copyright (c) 2015 jclaan. All rights reserved.
//

#import "ViewController.h"
#import "MediaAlbumsListViewController.h"


@interface ViewController ()

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
    
}


- (void) openMediaPicker:(id)sender {
    
    NSLog(@"afsadfds");
    
    MediaAlbumsListViewController *vc = [[MediaAlbumsListViewController alloc] init];
    
    UINavigationController *nc=[[UINavigationController alloc]initWithRootViewController:vc];
    
    
    
    [self presentViewController:nc animated:YES completion:nil];
    
    
    
    
    
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
