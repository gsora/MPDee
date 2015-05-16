//
//  AppDelegate.m
//  MPDee
//
//  Created by Gianguido Sorà on 12/05/15.
//  Copyright (c) 2015 Gianguido Sorà. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (assign, nonatomic) BOOL darkModeOn;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.image = [NSImage imageNamed:@"note.png"];
    [_statusItem.image setTemplate:YES];
    
    _statusItem.highlightMode = YES;
    [_statusItem setMenu:menu];
    [menu setDelegate:self];
    [self refreshDarkMode];
    
    keyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
    if([SPMediaKeyTap usesGlobalMediaKeyTap])
        [keyTap startWatchingMediaKeys];
    else
        NSLog(@"Media key monitoring disabled");

}

- (void)refreshDarkMode {
    NSString * value = (__bridge NSString *)(CFPreferencesCopyValue((CFStringRef)@"AppleInterfaceStyle", kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost));
    if ([value isEqualToString:@"Dark"]) {
        self.darkModeOn = YES;
    }
    else {
        self.darkModeOn = NO;
    }
}

NSString* print_tag(const struct mpd_song *song, enum mpd_tag_type type,
          const char *label)
{
    unsigned i = 0;
    const char *value;
    
    while ((value = mpd_song_get_tag(song, type, i++)) != NULL) {
        return([NSString stringWithFormat:@"%s", value]);
    }
    return nil;
}

- (NSString *) currentSongArtist {
    NSMutableString *artistTitle = [[NSMutableString alloc] init];
    
    // create a mpd connection struct
    conn = NULL;
    
    // make the connection
    conn = mpd_connection_new(NULL, 0, 30000);
    
    // if errors, close all!
    if (mpd_connection_get_error(conn) != MPD_ERROR_SUCCESS) {
        mpd_connection_free(conn);
        conn = NULL;
        NSLog(@"Connection error");
    }
    
    struct mpd_song *song;
    song = mpd_run_current_song(conn);
    
    if(song != NULL) {
        [artistTitle appendFormat:@"%@ - %@", print_tag(song, MPD_TAG_ARTIST, "artist"), print_tag(song, MPD_TAG_TITLE, "title")];
        mpd_song_free(song);
        mpd_connection_free(conn);
    } else {
        [artistTitle appendString:@"nothing"];
    }
    
    return artistTitle;
}

- (void)menuWillOpen:(NSMenu *)menu
{
    [currentSong setTitle:[self currentSongArtist]];
}

- (void)makeItDark {
    //Set theme and update listeners
    CFPreferencesSetValue((CFStringRef)@"AppleInterfaceStyle", @"Dark", kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    dispatch_async(dispatch_get_main_queue(), ^{
        CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (CFStringRef)@"AppleInterfaceThemeChangedNotification", NULL, NULL, YES);
    });
    
    //set wallpaper
}

- (void)makeItBright {
    //Set theme and update listeners
    CFPreferencesSetValue((CFStringRef)@"AppleInterfaceStyle", NULL, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    dispatch_async(dispatch_get_main_queue(), ^{
        CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), (CFStringRef)@"AppleInterfaceThemeChangedNotification", NULL, NULL, YES);
    });
    
}

- (void) mpdDo:(int)action {
    // create a mpd connection struct
    conn = NULL;
    
    // make the connection
    conn = mpd_connection_new(NULL, 0, 30000);
    
    // if errors, close all!
    if (mpd_connection_get_error(conn) != MPD_ERROR_SUCCESS) {
        mpd_connection_free(conn);
        conn = NULL;
        NSLog(@"Connection error");
    }
    
    // do action
    if(action == PLAY_PAUSE) {
        mpd_run_toggle_pause(conn);
    } else if(action == PREVIOUS) {
        mpd_run_previous(conn);
    } else if(action == NEXT) {
        mpd_run_next(conn);
    }
    
    // free up the connection
    mpd_connection_free(conn);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

+(void)initialize;
{
    if([self class] != [AppDelegate class]) return;
    
    // Register defaults for the whitelist of apps that want to use media keys
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers], kMediaKeyUsingBundleIdentifiersDefaultsKey,
                                                             nil]];
}

-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event;
{
    NSAssert([event type] == NSSystemDefined && [event subtype] == SPSystemDefinedEventMediaKeys, @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
    // here be dragons...
    int keyCode = (([event data1] & 0xFFFF0000) >> 16);
    int keyFlags = ([event data1] & 0x0000FFFF);
    BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
    int keyRepeat = (keyFlags & 0x1);
    
    if (keyIsPressed) {
        NSString *debugString = [NSString stringWithFormat:@"%@", keyRepeat?@", repeated.":@"."];
        switch (keyCode) {
            case NX_KEYTYPE_PLAY:
                debugString = [@"Play/pause pressed" stringByAppendingString:debugString];
                [self mpdDo:PLAY_PAUSE];
                break;
                
            case NX_KEYTYPE_FAST:
                debugString = [@"Ffwd pressed" stringByAppendingString:debugString];
                [self mpdDo:NEXT];
                break;
                
            case NX_KEYTYPE_REWIND:
                debugString = [@"Rewind pressed" stringByAppendingString:debugString];
                [self mpdDo:PREVIOUS];
                break;
            default:
                debugString = [NSString stringWithFormat:@"Key %d pressed%@", keyCode, debugString];
                break;
                // More cases defined in hidsystem/ev_keymap.h
        }
        NSLog(@"%@", debugString);
    }
}


@end
