//
//  VineVideoUploadActivityDialog.h
//  photopickershare
//
//  Created by jclaan on 4/23/16.
//  Copyright © 2016 jclaan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VineInfo.h"


@interface VineVideoUploadActivityDialog : UIViewController

@property (nonatomic, weak) id delegate;


@property (nonatomic, strong) VineInfo* vineInfo;



- (void)show:(void (^)(VineInfo* vineInfo, BOOL isOK))completion;


@end


