//
//  AppDelegate.m
//  verifyLinkMacOS
//
//  Created by Doron Adler on 04/01/2018.
//

#import "AppDelegate.h"
#import <libRTMP_macOS/libRTMP_macOS.h>

@interface AppDelegate () {
    struct RTMP* pRTMP;
}

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    pRTMP = RTMP_Alloc();
    RTMP_Init(pRTMP);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    if (pRTMP) {
        RTMP_Free(pRTMP);
        pRTMP = NULL;
    }
    // Insert code here to tear down your application
}


@end
