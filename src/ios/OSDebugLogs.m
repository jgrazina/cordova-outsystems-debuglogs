#import "OSDebugLogs.h"
#import "OSConsoleViewController.h"

@interface OSDebugLogs()
 
 @property (strong, nonatomic) OSConsoleViewController* osConsoleVC;

@end

@implementation OSDebugLogs


-(void)pluginInitialize{
    
    _osConsoleVC = [[OSConsoleViewController alloc] initWithParent:self.viewController];

}


- (void)openConsole:(CDVInvokedUrlCommand*)command
{
	CDVPluginResult* pluginResult = nil;
	if(_osConsoleVC){

		[_osConsoleVC openConsoleAnimated:YES];

		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	}
	else{
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];	
	}

    

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)closeConsole:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
	if(_osConsoleVC){

		[_osConsoleVC hideConsoleAnimated:YES];

		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
	}
	else{
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];	
	}

    
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

/*
 * Receives console output forwarded from JS and re-posts it as
 * CDVLoggerNotification, which OSConsoleViewController observes.
 *
 * This used to live in a fork of cordova-plugin-console, whose CDVLogger class
 * collided at link time with the CDVLogger that cordova-ios now ships inside
 * CordovaLib ("duplicate symbol _OBJC_CLASS_$_CDVLogger"). Keeping the behaviour
 * here means the plugin owns it outright and declares no class that CordovaLib
 * also defines.
 *
 * The notification name and the userInfo keys are deliberately unchanged, so
 * OSConsoleViewController needs no edits.
 */
- (void)logLevel:(CDVInvokedUrlCommand*)command
{
    id level = [command argumentAtIndex:0];
    id message = [command argumentAtIndex:1];

    if ([level isEqualToString:@"LOG"]) {
        NSLog(@"%@", message);
    } else {
        NSLog(@"%@: %@", level, message);
    }

    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    if (level) {
        [dict setValue:level forKey:@"level"];
    }
    if (message) {
        [dict setValue:message forKey:@"message"];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"CDVLoggerNotification"
                                                        object:nil
                                                      userInfo:dict];

    // Deliberately no sendPluginResult: JS passes no callbacks, and log volume can
    // be high. This matches what the old CDVLogger did.
}

@end
