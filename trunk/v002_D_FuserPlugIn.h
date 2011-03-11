//
//  v002_D_FuserPlugIn.h
//  v002 D-Fuser
//
//  Created by vade on 7/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import "spk_v002_tvone.h"	// TV1 commands and defines

#import <Quartz/Quartz.h>
#import "AMSerialPort.h"

// Do we even need this? I dont know.
// TBZ: What we need is a 'can previous ones of me be dropped' flag, ie. for fading, and a 'i take longer to process' flag, ie. for keying etc. 
typedef enum {
	v002DFuserWriteLowPriority = 0,
	v002DFuserWriteHighPriority = 1
} v002DFuserWritePriority;

#define kv002DFuserQueueLength 9

@interface v002_D_FuserPlugIn : QCPlugIn
{
	kTV1Error error;
    
	NSTimeInterval nextTimeToExecute;
	
	// Our internal Serial Port
	AMSerialPort* port;
	
	// These Queues can get no longer than 20 commands long.
	// If a command is submitted to the write queue, and it would result in
	// an over sized queue, it is dropped unless it is high priority, where
	// it replaces the last item (to maintain ordering).
	
	NSMutableArray* writeQueue;
	NSMutableArray* readQueue;

	NSThread* serialIOThread;
	
	NSMutableDictionary* keyerSettings;
}

// The serial port used to communicate to the mixer.
@property (assign) NSUInteger inputSerialPort;

// Mixing controls
@property (assign) double inputMaxFadeChannel1;	// 0, 1 A only
@property (assign) double inputMaxFadeChannel2;

// Keying
@property (assign) BOOL inputEnableKeyer;
@property (assign) NSUInteger inputKeyerMode;
@property (assign) NSDictionary* inputKeyerParameters;
@property (assign) BOOL inputSwapChannels;

@property (assign) CGColorRef inputBackgroundColor;

@property (assign) BOOL inputLockPanel;

// Windowing/input mapping, window controls
// To keep things simple, we always make sure that:
// Window A -> DVI in 1
// Window B -> DVI in 2
// Window Z -> Disabled.

@property (assign) NSUInteger inputWindow1AspectRatio;
@property (assign) NSUInteger inputWindow2AspectRatio;

// This is a menu list of resolutions to set the mixers main output to.
@property (assign) NSUInteger inputMixerResolution;	// Resolution aka 640x480 @60hz, 1920x1080 @ 29.97 Hz

// The SPK-DFUSER aim is to generate / intelligently set the EDID so attached computers set themselves to the output resolution
// Till then, here is simple publishing of the EDID emulation options
@property (assign) NSUInteger inputMixerEDIDEmulation;

//@property (assign) NSUInteger inputMixerOutputType;	// RGBHV, 
@property (assign) BOOL	inputReInitializeMixer;


// QC Plugin Internal Settings
@property (assign) NSMutableDictionary* keyerSettings;

@end

@interface v002_D_FuserPlugIn (Execution)

// serial port data handling..
- (AMSerialPort *)port;
- (void)setPort:(AMSerialPort *)newPort;
- (void) initPort:(NSUInteger)portIndex;


// This does our reading and writing to our read and write queues (the actuall serial port stuff happens in a thread)
- (void) writeString:(NSString*)command priority:(v002DFuserWritePriority)priority;
- (NSString*) readString;

// color specifics
- (void) writeKeyColorMin:(CGColorRef)rgbColor;
- (void) writeKeyColorMax:(CGColorRef)rgbColor;
- (void) writeBGColor:(CGColorRef)rgbColor;

// Mixer
- (void) initializeSerialPortSettings;
- (void) setResolution:(NSUInteger)index;
- (void) setEDID:(NSUInteger)index;
- (void) uploadEDID:(NSData*)edidData toSlot:(NSUInteger)edidSlotIndex;
@end
