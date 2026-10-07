#import <UIKit/UIKit.h>

@interface OSConsoleViewController : UIViewController

-(void)log:(NSString*)output;
-(void)log:(NSString*)output level:(NSString*)level;
-(void)hideConsoleAnimated:(BOOL) animated;
-(void)openConsoleAnimated:(BOOL) animated;
-(instancetype) initWithParent:(UIViewController*)parent;
@end
