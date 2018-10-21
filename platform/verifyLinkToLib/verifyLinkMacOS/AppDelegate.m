//
//  AppDelegate.m
//  verifyLinkMacOS
//
//  Created by Doron Adler on 04/01/2018.
//

#import "AppDelegate.h"
#import <dylibRTMP-macOS/dylibRTMP-macOS.h>

@interface AppDelegate () {
    struct RTMP* pRTMP;
}

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSLog(@"Allocating RTMP context");
    pRTMP = RTMP_Alloc();
    NSLog(@"Initializing RTMP context");
    RTMP_Init(pRTMP);
    NSLog(@"RTMP context address is %p", pRTMP);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    if (pRTMP) {
        NSLog(@"Deallocating RTMP context with address %p", pRTMP);
        RTMP_Free(pRTMP);
        pRTMP = NULL;
    }
    // Insert code here to tear down your application
}


@end
