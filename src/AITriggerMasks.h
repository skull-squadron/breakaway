//
//  AITriggerMasks.h
//  Breakaway
//
//  Created by Kevin Nygaard on 5/19/11.
//  Copyright 2011 MutableCode. All rights reserved.
//
#ifndef __AITRIGGERMASKS_H__
#define __AITRIGGERMASKS_H__

typedef enum {
    kTriggerMute = 1 << 0, // 1 for mute on, 0 for mute off
    kTriggerJackStatus = 1 << 1, // 1 for heaphones, 0 for ispk
    kTriggerInt = 1 << 2, // 1 for source change, 0 for mute
} kTriggerMask;

#endif /* __AITRIGGERMASKS_H__ */