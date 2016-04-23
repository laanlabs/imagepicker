//
//  VineVideoUploadActivityDialog.m
//  photopickershare
//
//  Created by jclaan on 4/23/16.
//  Copyright © 2016 jclaan. All rights reserved.
//

#import "VineVideoUploadActivityDialog.h"


/*
 
 
 VINE COLOR - 00a478
 https://github.com/TakayoshiMiyamoto/PasswordDialogViewController
 
 */


// Duration
static const CGFloat kShowDuration = .1f;

// Size
static const NSInteger kMainViewWidth = 280;
static const NSInteger kMainViewHeight = 250;
static const NSInteger kFontSize = 16;
static const NSInteger kTextFieldMargin = 0;

// Completion block
typedef void (^completion)(VineInfo* vineInfo, BOOL isOK);




@interface VineVideoUploadActivityDialog ()<UITextFieldDelegate>

@property (nonatomic, copy) completion completion;
@property (nonatomic, strong) UIView *mainView;

@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *captionTextField;



@end

@implementation VineVideoUploadActivityDialog {
    dispatch_once_t _onceToken;
}


#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    [self _initialize];

    
    self.view.opaque = YES;
    self.view.backgroundColor = [UIColor clearColor];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    dispatch_once(&_onceToken, ^(void) {
        [UIView animateWithDuration:kShowDuration animations:^(void) {
            _mainView.alpha = 1.f;
        } completion:nil];
    });
}





#pragma mark - Public instance methods



- (void)show:(void (^)(VineInfo* vineInfo, BOOL isOK))completion {
    if (![self delegate] ) {
        completion(nil, NO);
        return;
    }
    
    _completion = completion;

    //holy wow you need this hack
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootViewController = window.rootViewController;
    rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    if ([UIViewController instancesRespondToSelector:@selector(modalPresentationStyle)]) {
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }


}

- (void)show:(void (^)(VineInfo* vineInfo, BOOL isOK))completion delegate:(__weak id)sender {
    _delegate = sender;
    
    [self show:completion];
}


#pragma mark - Private instance methods

- (void)_initialize {
    CGFloat textFieldWidth = kMainViewWidth - (kTextFieldMargin * 2);
    CGFloat textFieldHeight = 32;
    
    NSInteger viewMargin = 1;
    NSInteger buttonHeight = 50;
    
    NSInteger switchHeight =  35 ;
    
    // Frames
    CGRect mainViewFrame = CGRectMake(0,
                                      0,
                                      kMainViewWidth,
                                      kMainViewHeight + switchHeight);
    CGRect topViewFrame = CGRectMake(0,
                                     0,
                                     kMainViewWidth,
                                     mainViewFrame.size.height - buttonHeight);
    CGRect leftViewFrame = CGRectMake(0,
                                      topViewFrame.size.height + viewMargin,
                                      (kMainViewWidth / 2) - (viewMargin / 2),
                                      buttonHeight - viewMargin);
    CGRect rightViewFrame = CGRectMake(leftViewFrame.size.width + viewMargin,
                                       topViewFrame.size.height + viewMargin,
                                       leftViewFrame.size.width,
                                       leftViewFrame.size.height);
    CGRect titleLabelFrame = CGRectMake(0,
                                        13,
                                        topViewFrame.size.width,
                                        28);

    
    
    CGRect cancelButtonFrame = CGRectMake(0,
                                          0,
                                          leftViewFrame.size.width,
                                          leftViewFrame.size.height);
    CGRect okButtonFrame = CGRectMake(0,
                                      0,
                                      rightViewFrame.size.width,
                                      rightViewFrame.size.height);
    
    self.view.frame = [UIScreen mainScreen].bounds;
    self.view.backgroundColor = [UIColor clearColor];
    
    UIView *mainView = [[UIView alloc] initWithFrame:mainViewFrame];
    mainView.backgroundColor = [VineVideoUploadActivityDialog colorFromHexString:@"#dddce1" alpha:0.8];
    mainView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2 - 30);
    mainView.layer.cornerRadius = 4;
    mainView.layer.masksToBounds = YES;
    mainView.alpha = 0;
    
    UIView *topView = [[UIView alloc] initWithFrame:topViewFrame];
    topView.backgroundColor = [VineVideoUploadActivityDialog colorFromHexString:@"#ededed" alpha:.9];
    
    UIView *leftView = [[UIView alloc] initWithFrame:leftViewFrame];
    leftView.backgroundColor =  [VineVideoUploadActivityDialog colorFromHexString:@"#ededed" alpha:.9];
    
    UIView *rightView = [[UIView alloc] initWithFrame:rightViewFrame];
    rightView.backgroundColor =  [VineVideoUploadActivityDialog colorFromHexString:@"#ededed" alpha:.9];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleLabelFrame];
        titleLabel.text = @"Vine";

    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.numberOfLines = 1;
    titleLabel.adjustsFontSizeToFitWidth = NO;
    [topView addSubview:titleLabel];
    
    
    CGFloat yPos = 18 + titleLabelFrame.size.height;

    
    
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,
                                                                      yPos,
                                                                      topViewFrame.size.width - 20, 30)];
    messageLabel.text = @"adsfadsf";
    messageLabel.font = [UIFont fontWithName:@"Arial" size:15];
    messageLabel.textColor = [UIColor blackColor];
    messageLabel.textAlignment = NSTextAlignmentLeft;
    messageLabel.backgroundColor = [UIColor redColor];
    messageLabel.numberOfLines = 2;
    messageLabel.adjustsFontSizeToFitWidth = NO;
    [topView addSubview:messageLabel];
    
    
    yPos += 30;
    

    _usernameTextField = [[UITextField alloc] initWithFrame:CGRectMake(kTextFieldMargin,yPos,textFieldWidth,textFieldHeight)];
    _usernameTextField.font = [UIFont systemFontOfSize:kFontSize];
    _usernameTextField.textColor = [UIColor blackColor];
    _usernameTextField.borderStyle = UITextBorderStyleLine;
    _usernameTextField.textAlignment = NSTextAlignmentLeft;
    _usernameTextField.placeholder = @"Email";
    _usernameTextField.keyboardType = UIKeyboardTypeDefault;
    _usernameTextField.returnKeyType = UIReturnKeyDone;
    _usernameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _usernameTextField.secureTextEntry = NO;
    _usernameTextField.delegate = self;
    [topView addSubview:_usernameTextField];
    
     yPos += textFieldHeight;
    
    _passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(kTextFieldMargin,yPos,textFieldWidth,textFieldHeight)];
    _passwordTextField.font = [UIFont systemFontOfSize:kFontSize];
    _passwordTextField.textColor = [UIColor blackColor];
    _passwordTextField.borderStyle = UITextBorderStyleLine;
    _passwordTextField.textAlignment = NSTextAlignmentLeft;

    _passwordTextField.placeholder = @"Password";
    _passwordTextField.keyboardType = UIKeyboardTypeDefault;
    _passwordTextField.returnKeyType = UIReturnKeyDone;
    _passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _passwordTextField.secureTextEntry = YES;
    _passwordTextField.delegate = self;
    [topView addSubview:_passwordTextField];
    

    yPos += textFieldHeight;
    
    _captionTextField = [[UITextField alloc] initWithFrame:CGRectMake(kTextFieldMargin,yPos,textFieldWidth,textFieldHeight)];
    _captionTextField.font = [UIFont systemFontOfSize:kFontSize];
    _captionTextField.textColor = [UIColor blackColor];
    _captionTextField.borderStyle = UITextBorderStyleLine;
    _captionTextField.textAlignment = NSTextAlignmentLeft;
    
    _captionTextField.placeholder = @"Caption";
    _captionTextField.keyboardType = UIKeyboardTypeDefault;
    _captionTextField.returnKeyType = UIReturnKeyDone;
    _captionTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _captionTextField.secureTextEntry = NO;
    _captionTextField.delegate = self;
    [topView addSubview:_captionTextField];
    
    
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.frame = cancelButtonFrame;
    [cancelButton addTarget:self action:@selector(pressCloseButton:) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:NSLocalizedString(@"Cancel", @"Cancel") forState:UIControlStateNormal];
    [cancelButton setTitleColor:[VineVideoUploadActivityDialog colorFromHexString:@"#1e56fe" alpha:1]
                       forState:UIControlStateNormal];
    cancelButton.backgroundColor = [UIColor clearColor];
    [leftView addSubview:cancelButton];
    
    UIButton *okButton = [UIButton buttonWithType:UIButtonTypeCustom];
    okButton.frame = okButtonFrame;
    [okButton addTarget:self action:@selector(pressOKButton:) forControlEvents:UIControlEventTouchUpInside];
    [okButton setTitle:NSLocalizedString(@"OK", @"OK") forState:UIControlStateNormal];
    [okButton setTitleColor:[VineVideoUploadActivityDialog colorFromHexString:@"#1e56fe" alpha:1]
                   forState:UIControlStateNormal];
    okButton.backgroundColor = [UIColor clearColor];
    [rightView addSubview:okButton];
    
    [mainView addSubview:topView];
    [mainView addSubview:leftView];
    [mainView addSubview:rightView];
    
    [[self view] addSubview:mainView];
    
    _mainView = mainView;
    
    
    
    _usernameTextField.text = @"labs@laan.com";
    _passwordTextField.text = @"testtest";
    _captionTextField.text = @"this is a caption";
    

    
}


#pragma mark - Action methods



- (void)pressOKButton:(id)sender {

    //@todo: form error control
    
    _vineInfo.username = _usernameTextField.text;
    _vineInfo.password = _passwordTextField.text;
    _vineInfo.caption = _captionTextField.text;

    
    if (_completion) {
        _completion(_vineInfo, YES);
    }
}

- (void)pressCloseButton:(id)sender {
    if (_completion) {
        _completion(nil, NO);
    }
}


#pragma mark - memory


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark - Utilities

+ (UIColor *)colorFromHexString:(NSString *)hexString alpha:(CGFloat)alpha {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    scanner.scanLocation = 1;
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0
                           green:((rgbValue & 0xFF00) >> 8)/255.0
                            blue:(rgbValue & 0xFF)/255.0
                           alpha:alpha];
}



@end
