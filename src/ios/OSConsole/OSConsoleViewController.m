#import "OSConsoleViewController.h"

@interface OSConsoleViewController ()
- (IBAction)onClearBtnTouchUp:(UIButton *)sender;
- (IBAction)onCloseBtnTouchUp:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@property (strong, nonatomic) NSMutableAttributedString* logString;
@property (weak, nonatomic) UIViewController* parentVC;

@end

@implementation OSConsoleViewController


-(instancetype)init {
    self = [super initWithNibName:@"OSConsole" bundle:nil];
    if (self) {
        [self setup];
    }
    return self;
}

-(instancetype) initWithParent:(UIViewController*)parent {
    self = [super initWithNibName:@"OSConsole" bundle:nil];
    if(self){
        self.parentVC = parent;
        [self setup];
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"CDVLoggerNotification"
                                                  object:nil];
    self.logString = nil;
    
}



-(void) setup {
    self.logString = [[NSMutableAttributedString alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedRemoteLog:)
                                                 name:@"CDVLoggerNotification"
                                               object:nil];
}

-(void) receivedRemoteLog: (NSNotification*) notification {
    if([notification.name isEqualToString:@"CDVLoggerNotification"]){
        NSDictionary* userInfo = notification.userInfo;
        NSString *output = (NSString*) userInfo[@"message"];
        NSString *level = (NSString*) userInfo[@"level"];
        [self log:output level:level];
    }
}

/** Console palette, matching the Android side. */
+ (UIColor*)colourForLevel:(NSString*)level {
    if ([level isEqualToString:@"ERROR"]) { return [UIColor colorWithRed:1.00 green:0.42 blue:0.42 alpha:1.0]; }
    if ([level isEqualToString:@"WARN"])  { return [UIColor colorWithRed:1.00 green:0.82 blue:0.40 alpha:1.0]; }
    if ([level isEqualToString:@"INFO"])  { return [UIColor colorWithRed:0.50 green:0.82 blue:0.91 alpha:1.0]; }
    if ([level isEqualToString:@"DEBUG"]) { return [UIColor colorWithRed:0.70 green:0.62 blue:0.86 alpha:1.0]; }
    return [UIColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:1.0];
}

-(void)log:(NSString*)output {
    [self log:output level:nil];
}

-(void)log:(NSString*)output level:(NSString*)level {
    if (output == nil) {
        return;
    }

    UIFont *font = self.outputTextView.font;
    if (font == nil) {
        font = [UIFont fontWithName:@"Menlo" size:11.0];
    }

    NSDictionary *attributes = @{
        NSForegroundColorAttributeName: [OSConsoleViewController colourForLevel:level],
        NSFontAttributeName: font
    };

    NSString *line = [NSString stringWithFormat:@"\n%@", output];
    NSAttributedString *entry = [[NSAttributedString alloc] initWithString:line
                                                               attributes:attributes];
    [self.logString appendAttributedString:entry];

    if([[_parentVC.view subviews]containsObject: self.view]) {
        [self.outputTextView setAttributedText: self.logString];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClearBtnTouchUp:(UIButton *)sender {
    self.logString = [[NSMutableAttributedString alloc] init];
    [self.outputTextView setAttributedText:self.logString];
}

- (IBAction)onCloseBtnTouchUp:(UIButton *)sender {
    //[OSConsoleViewController removeControllerIn:self.parentViewController animated:YES];
    [self hideConsoleAnimated:YES];
}

-(void)openConsoleAnimated:(BOOL) animated {
    if(_parentVC) {
        BOOL exists = NO;
        for(UIViewController* vc in _parentVC.childViewControllers) {
            if([vc isKindOfClass:[OSConsoleViewController class]]) {
                exists = YES;
                break;
            }
        }
        
        self.view.backgroundColor = [UIColor whiteColor];
        // Inset by the safe area so the close/clear buttons are not under the status
        // bar, notch or home indicator. This app runs without a safe-area layout, so
        // without this the top row sits beneath the clock and wifi/battery icons,
        // which also swallow the taps.
        UIEdgeInsets safe = UIEdgeInsetsZero;
        if (@available(iOS 11.0, *)) {
            safe = _parentVC.view.safeAreaInsets;
        }
        self.view.frame = UIEdgeInsetsInsetRect(_parentVC.view.bounds, safe);
        
        if(!exists){
            [_parentVC addChildViewController:self];
            [_parentVC willMoveToParentViewController:self];
        }
        
        
        if( ![[_parentVC.view subviews]containsObject: self.view]) {
            if (animated) {
                // animation with a simple fade
                self.view.alpha = 0.0f;

                [_parentVC.view addSubview:self.view];
                [UIView animateWithDuration:0.3 animations:^{
                    _parentVC.view.userInteractionEnabled = NO;
                    self.view.alpha = 1.0f;
                    
                }                completion:^(BOOL finished) {
                    _parentVC.view.userInteractionEnabled = YES;
                    [self onShow];
                }];
            } else {
                // no animation so we just add the view as subview
                [_parentVC.view addSubview:self.view];
                [self onShow];
            }
        }
        
        if(!exists){
            [_parentVC didMoveToParentViewController:self];
        }
    } else {
        NSLog(@"Controller can't be nil");
    }
}

-(void)hideConsoleAnimated:(BOOL) animated {
    if (_parentVC) {
        for (UIViewController *vc in _parentVC.childViewControllers) {
            if ([vc isKindOfClass:[OSConsoleViewController class]]) {
                
                if (animated) {
                    // animation with a simple fade
                    [UIView animateWithDuration:0.3 animations:^{
                        _parentVC.view.userInteractionEnabled = NO;
                        vc.view.alpha = 0.0f;
                        
                    } completion:^(BOOL finished) {
                        _parentVC.view.userInteractionEnabled = YES;
                        [vc.view removeFromSuperview];
                        [self onHide];
                    }];
                } else {
                    // no animation so we just add the view as subview
                    [vc.view removeFromSuperview];
                }
                //[vc removeFromParentViewController];
            }
        }
    } else {
        NSLog(@"Controller can't be nil");
    }
}


-(void)onHide {
    
}

-(void)onWillAppear {
    
}

-(void)onShow {
    // Dark ground so the coloured text reads, matching the Android console.
    self.outputTextView.backgroundColor = [UIColor colorWithRed:0.20 green:0.22 blue:0.27 alpha:1.0];
    [self.outputTextView setAttributedText: self.logString];
}

@end
