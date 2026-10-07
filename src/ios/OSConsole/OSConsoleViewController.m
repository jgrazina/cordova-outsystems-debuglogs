#import "OSConsoleViewController.h"

@interface OSConsoleViewController ()
- (IBAction)onClearBtnTouchUp:(UIButton *)sender;
- (IBAction)onCopyBtnTouchUp:(UIButton *)sender;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyModernAppearance];
}

/**
 * Restyles the nib at runtime rather than editing OSConsole.xib: a malformed nib
 * fails at load time on device, which is a bad trade when the nib cannot be tested
 * here. Everything below is null-guarded so a changed nib degrades instead of
 * crashing.
 */
-(void)applyModernAppearance {
    self.view.backgroundColor = [UIColor clearColor];

    // Frosted smoky pane behind everything.
    UIBlurEffect *effect;
    if (@available(iOS 13.0, *)) {
        effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark];
    } else {
        effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    }
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:effect];
    blur.frame = self.view.bounds;
    blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:blur atIndex:0];

    UIView *tint = [[UIView alloc] initWithFrame:self.view.bounds];
    tint.backgroundColor = [UIColor colorWithWhite:0.04 alpha:0.45];
    tint.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tint.userInteractionEnabled = NO;
    [self.view insertSubview:tint atIndex:1];

    // The toolbar is whichever subview owns the buttons - found by inspection so a
    // nib reshuffle does not break it.
    UIView *toolbar = nil;
    for (UIView *sub in self.view.subviews) {
        for (UIView *inner in sub.subviews) {
            if ([inner isKindOfClass:[UIButton class]]) {
                toolbar = sub;
                break;
            }
        }
        if (toolbar != nil) {
            break;
        }
    }

    if (toolbar != nil) {
        toolbar.backgroundColor = [UIColor clearColor];
        for (UIView *inner in toolbar.subviews) {
            if ([inner isKindOfClass:[UIButton class]]) {
                [self styleButton:(UIButton *)inner];
            }
        }

        UIButton *copyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [copyBtn setTitle:@"Copy" forState:UIControlStateNormal];
        [copyBtn addTarget:self
                    action:@selector(onCopyBtnTouchUp:)
          forControlEvents:UIControlEventTouchUpInside];
        [self styleButton:copyBtn];
        copyBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [toolbar addSubview:copyBtn];
        [NSLayoutConstraint activateConstraints:@[
            [copyBtn.centerXAnchor constraintEqualToAnchor:toolbar.centerXAnchor],
            [copyBtn.topAnchor constraintEqualToAnchor:toolbar.topAnchor constant:20.0],
            [copyBtn.heightAnchor constraintEqualToConstant:34.0],
            [copyBtn.widthAnchor constraintGreaterThanOrEqualToConstant:84.0]
        ]];
    }

    if (self.outputTextView != nil) {
        self.outputTextView.backgroundColor = [UIColor clearColor];
        UIFont *mono = [UIFont fontWithName:@"Menlo" size:11.0];
        self.outputTextView.font = (mono != nil) ? mono : [UIFont systemFontOfSize:11.0];
        self.outputTextView.textColor = [UIColor colorWithWhite:0.90 alpha:1.0];
        self.outputTextView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        self.outputTextView.textContainerInset = UIEdgeInsetsMake(8.0, 10.0, 16.0, 10.0);
    }
}

/** Pill button matching the Android console. */
-(void)styleButton:(UIButton *)button {
    if (button == nil) {
        return;
    }
    button.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    [button setTitleColor:[UIColor colorWithWhite:0.95 alpha:1.0] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    button.layer.cornerRadius = 17.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.25].CGColor;
    button.clipsToBounds = YES;
    button.contentEdgeInsets = UIEdgeInsetsMake(0.0, 16.0, 0.0, 16.0);
}

/**
 * Copies the whole buffer to the pasteboard so a tester can paste it somewhere.
 * There is no toast on iOS, so the button itself reports back briefly.
 */
- (IBAction)onCopyBtnTouchUp:(UIButton *)sender {
    NSString *payload = (self.logString != nil) ? self.logString.string : @"";
    [UIPasteboard generalPasteboard].string = payload;

    NSString *original = [sender titleForState:UIControlStateNormal];
    [sender setTitle:[NSString stringWithFormat:@"Copied %lu", (unsigned long)payload.length]
            forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [sender setTitle:original forState:UIControlStateNormal];
    });
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
        
        self.view.backgroundColor = [UIColor clearColor];
        // Inset by the safe area so the close/clear buttons are not under the status
        // bar, notch or home indicator. This app runs without a safe-area layout, so
        // without this the top row sits beneath the clock and wifi/battery icons,
        // which also swallow the taps.
        UIEdgeInsets safe = UIEdgeInsetsZero;
        if (@available(iOS 11.0, *)) {
            safe = _parentVC.view.safeAreaInsets;
            // An app that suppresses safe-area layout can report zero here, so fall
            // back to the window, which always reports the physical device insets.
            if (UIEdgeInsetsEqualToEdgeInsets(safe, UIEdgeInsetsZero)) {
                UIWindow *window = _parentVC.view.window;
                if (window != nil) {
                    safe = window.safeAreaInsets;
                }
            }
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
    // Background stays clear so the frosted pane shows through.
    [self.outputTextView setAttributedText: self.logString];
}

@end
