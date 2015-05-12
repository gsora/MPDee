//
//  AppDelegate.h
//  MPDee
//
//  Created by Gianguido Sorà on 12/05/15.
//  Copyright (c) 2015 Gianguido Sorà. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SPMediaKeyTap.h"
#include "mpd/client.h"
#include "mpd/status.h"
#include "mpd/song.h"
#include "mpd/entity.h"
#include "mpd/search.h"
#include "mpd/tag.h"

#define PLAY_PAUSE 1
#define NEXT 2
#define PREVIOUS 3


@interface AppDelegate : NSObject <NSApplicationDelegate> {
    SPMediaKeyTap *keyTap;
    struct mpd_connection *conn;
}
@end

