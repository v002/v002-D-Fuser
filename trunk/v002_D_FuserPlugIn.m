//
//  v002_D_FuserPlugIn.m
//  v002 D-Fuser
//
//  Created by vade on 7/6/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "AMSerialPortList.h"
#import "AMSerialPortAdditions.h"

#import "v002_D_FuserPlugIn.h"

#define	kQCPlugIn_Name				@"v002 D-Fuser"
#define	kQCPlugIn_Description		@"v002 D-Fuser description"

// all of our serial ports
static NSMutableArray* serialPortArray;

// all of our hard coded resolutions, and their strings.
static NSArray* resolutionsArray;

// all of our EDID slots names
static NSArray* edidSlotNames;

// all of our keyer setting names
static NSArray* keyerSettingNames;

#pragma mark -
#pragma mark TV1 Library Read and Write callbacks

void MyTV1ReadCallback(char* result, void* context)
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSString* resultString = nil;
	
	resultString = [(v002_D_FuserPlugIn*)context readString];	
	[resultString retain];
	
	if(resultString)
		[resultString getCString:result maxLength:21 encoding:NSASCIIStringEncoding];

	[resultString release];
	
	[pool drain];
}

void MyTV1WriteCallback(char* command, void* context)
{
	//printf("%s", command);
	[(v002_D_FuserPlugIn*)context writeString:[NSString stringWithCString:command encoding:NSASCIIStringEncoding] priority:v002DFuserWriteHighPriority];
}	 

#pragma mark -

@implementation v002_D_FuserPlugIn

@dynamic inputSerialPort;

// Mix Controls
@dynamic inputMaxFadeChannel1;
@dynamic inputMaxFadeChannel2;

@dynamic inputEnableKeyer;
@dynamic inputKeyerMode;
@dynamic inputKeyerParameters;
@dynamic inputSwapChannels;

@dynamic inputBackgroundColor;

@dynamic inputWindow1AspectRatio;
@dynamic inputWindow2AspectRatio;

@dynamic inputMixerResolution;
@dynamic inputMixerEDIDEmulation;
//@dynamic inputMixerOutputType;

@dynamic inputReInitializeMixer;
@dynamic inputLockPanel;

@synthesize keyerSettings;

+ (NSDictionary*) attributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	// initialize our resolutions array
	resolutionsArray = [[NSArray arrayWithObjects:	[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionVGA],			@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionVGA			encoding:NSASCIIStringEncoding], @"description", nil],	
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionNTSC],			@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionNTSC			encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionPAL],			@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionPAL			encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionSVGA],			@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionSVGA			encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionXGAp5994],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionXGAp5994		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionXGAp60],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionXGAp60		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionXGAp75],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionXGAp75		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution720p2398],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription720p2398		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution720p24],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription720p24		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution720p25],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription720p25		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution720p2997],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription720p2997		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution720p30],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription720p30		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution720p50],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription720p50		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution720p5994],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription720p5994		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution720p60],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription720p60		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionWXGA5by3p60],	@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionWXGA5by3p60	encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionWXGA5by3p75],	@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionWXGA5by3p75	encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionWXGA16by10p60], @"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionWXGA16by10p60 encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionWXGA16by10p75], @"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionWXGA16by10p75 encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionSGAp60],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionSGAp60		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionSGAp75],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionSGAp75		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionWSXGAp60],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionWSXGAp60		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionUXGAp60],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionUXGAp60		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionUXGAp75],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionUXGAp75		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionUXGAp85],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionUXGAp85		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionWSXGAPLUSp60],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionWSXGAPLUSp60		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution1080p2398],	@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription1080p2398	encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution1080p24],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription1080p24		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution1080p25],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription1080p25		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution1080p2997],	@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription1080p2997	encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution1080p30],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription1080p30		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution1080p50],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription1080p50		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution1080p5996],	@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription1080p5996	encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution1080p60],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription1080p60		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1Resolution1080p75],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescription1080p75		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionWUXGAp60],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionWUXGAp60		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionWUXGAp75],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionWUXGAp75		encoding:NSASCIIStringEncoding], @"description", nil],
													[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kTV1ResolutionWUXGAp85],		@"resolutionNum", [NSString stringWithCString:kTV1ResolutionDescriptionWUXGAp85		encoding:NSASCIIStringEncoding], @"description", nil],
												//	[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:, @"serialString", @"2048x1080 @ 60Hz", @"description", nil],
												//	[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:, @"serialString", @"2880x900 @ 60Hz", @"description", nil],

													nil] retain];
		
	edidSlotNames = [[NSArray arrayWithObjects:	@"Memory 1", @"Memory 2", @"Memory 3", @"MATROX TH2GO", @"3D", @"HDMI", @"DVI", @"Monitor", nil] retain];
	
	keyerSettingNames = [[NSArray arrayWithObjects: @"Black", @"White", @"Blue", @"Custom", nil] retain]; 
  
	// get our list of serial ports.
	serialPortArray = [[NSMutableArray arrayWithCapacity:2] retain];
	
	// get an port enumerator
	NSEnumerator *enumerator = [AMSerialPortList portEnumerator];
	AMSerialPort *aPort;
	
	while (aPort = [enumerator nextObject])
	{
		[serialPortArray addObject:[aPort bsdPath]];
	}	
	
	if([key isEqualToString:@"inputSerialPort"])
	   return [NSDictionary dictionaryWithObjectsAndKeys:@"Serial Port", QCPortAttributeNameKey, 
			   serialPortArray, QCPortAttributeMenuItemsKey,
			   [NSNumber numberWithInt:0], QCPortAttributeDefaultValueKey,
			   [NSNumber numberWithInt:0], QCPortAttributeMinimumValueKey,
			   [NSNumber numberWithInt:[serialPortArray count] -1], QCPortAttributeMaximumValueKey, nil]; 

	if([key isEqualToString:@"inputRawSerialCommand"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Raw Serial Command", QCPortAttributeNameKey, nil];	

	if([key isEqualToString:@"inputMixAmount"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Mix", QCPortAttributeNameKey, 
				[NSNumber numberWithDouble:0.0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithDouble:0.0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithDouble:1.0], QCPortAttributeMaximumValueKey, nil]; 
	
	if([key isEqualToString:@"inputMaxFadeChannel1"])
	return [NSDictionary dictionaryWithObjectsAndKeys:@"Fade Channel 1", QCPortAttributeNameKey, 
			[NSNumber numberWithDouble:0.0], QCPortAttributeDefaultValueKey,
			[NSNumber numberWithDouble:0.0], QCPortAttributeMinimumValueKey,
			[NSNumber numberWithDouble:1.0], QCPortAttributeMaximumValueKey, nil]; 
	
	if([key isEqualToString:@"inputMaxFadeChannel2"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Fade Channel 2", QCPortAttributeNameKey, 
				[NSNumber numberWithDouble:0.0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithDouble:0.0], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithDouble:1.0], QCPortAttributeMaximumValueKey, nil]; 
	
	// Keying
	
	if([key isEqualToString:@"inputEnableKeyer"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Enable Keyer on 1", QCPortAttributeNameKey, nil];	

	if([key isEqualToString:@"inputKeyerMode"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Keyer Mode", QCPortAttributeNameKey,
				keyerSettingNames, QCPortAttributeMenuItemsKey,
				[NSNumber numberWithInt:0], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithInt:[keyerSettingNames count] -1], QCPortAttributeMaximumValueKey, nil];
	
	if([key isEqualToString:@"inputKeyerParameters"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Keyer Parameters", QCPortAttributeNameKey, nil];
	
	if([key isEqualToString:@"inputSwapChannels"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Swap Inputs", QCPortAttributeNameKey, nil];

	// Not technically part of Keyer controls but...
	if([key isEqualToString:@"inputBackgroundColor"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Key Background Color", QCPortAttributeNameKey, nil];	

	// End Keying
	
	
	if([key isEqualToString:@"inputMixerResolution"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Output Resolution", QCPortAttributeNameKey, [resolutionsArray valueForKey:@"description"], QCPortAttributeMenuItemsKey, [NSNumber numberWithInt:0], QCPortAttributeDefaultValueKey, [NSNumber numberWithInt:0], QCPortAttributeMinimumValueKey, [NSNumber numberWithInt:[resolutionsArray count] -1], QCPortAttributeMaximumValueKey, nil];
	
  if([key isEqualToString:@"inputMixerEDIDEmulation"])
    return [NSDictionary dictionaryWithObjectsAndKeys:@"EDID Emulation", QCPortAttributeNameKey, edidSlotNames, QCPortAttributeMenuItemsKey, [NSNumber numberWithInt:6], QCPortAttributeDefaultValueKey, [NSNumber numberWithInt:0], QCPortAttributeMinimumValueKey, [NSNumber numberWithInt:[edidSlotNames count] -1], QCPortAttributeMaximumValueKey, nil];
  
    // Utility
    
    NSArray* ARArray = [NSArray arrayWithObjects:@"Fill", @"Aspect", @"Horizontal Fit", @"Vertical Fit", @"1:1", nil];
    
	if([key isEqualToString:@"inputWindow1AspectRatio"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Channel 1 Aspect Ratio", QCPortAttributeNameKey, ARArray, QCPortAttributeMenuItemsKey, [NSNumber numberWithInt:0], QCPortAttributeDefaultValueKey, [NSNumber numberWithInt:0], QCPortAttributeMinimumValueKey, [NSNumber numberWithInt:[ARArray count] -1], QCPortAttributeMaximumValueKey, nil];

    if([key isEqualToString:@"inputWindow2AspectRatio"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Channel 2 Aspect Ratio", QCPortAttributeNameKey, ARArray, QCPortAttributeMenuItemsKey, [NSNumber numberWithInt:0], QCPortAttributeDefaultValueKey, [NSNumber numberWithInt:0], QCPortAttributeMinimumValueKey, [NSNumber numberWithInt:[ARArray count] -1], QCPortAttributeMaximumValueKey, nil];

    if([key isEqualToString:@"inputLockPanel"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Utility Lock Front Panel", QCPortAttributeNameKey, nil];

    
    if([key isEqualToString:@"inputReInitializeMixer"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Utility Re-Initialize Mixer", QCPortAttributeNameKey, nil];
    
	return nil;
}

+ (NSArray*) sortedPropertyPortKeys
{
	return [NSArray arrayWithObjects:@"inputSerialPort",
									@"inputMixerResolution",
									@"inputMixerEDIDEmulation",
									@"inputMaxFadeChannel1",	// Mixing
									@"inputMaxFadeChannel2",
									@"inputEnableKeyer",		// Keying
									@"inputKeyerMode",
									@"inputKeyerParameters",
									@"inputSwapChannels",
									@"inputBackgroundColor",
									@"inputWindow1AspectRatio", // Aspect
									@"inputWindow2AspectRatio",
									@"inputLockPanel",          // Utility
									@"inputReInitializeMixer",
                                    
									nil];
}


+ (QCPlugInExecutionMode) executionMode
{
	return kQCPlugInExecutionModeConsumer;
}

+ (QCPlugInTimeMode) timeMode
{
	return kQCPlugInTimeModeTimeBase;
}

- (id) init
{
	if(self = [super init])
	{
        error = kTV1NoError;
        
		writeQueue = [[NSMutableArray alloc] initWithCapacity:kv002DFuserQueueLength];
		readQueue =  [[NSMutableArray alloc] initWithCapacity:kv002DFuserQueueLength];
		
		keyerSettings = [[NSMutableDictionary alloc] initWithCapacity:4];
		[keyerSettings setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt:0], @"minY",
								  [NSNumber numberWithInt:18], @"maxY",
								  [NSNumber numberWithInt:0], @"softY",
								  [NSNumber numberWithInt:0], @"minU",
								  [NSNumber numberWithInt:255], @"maxU",
								  [NSNumber numberWithInt:0], @"softU",
								  [NSNumber numberWithInt:0], @"minV",
								  [NSNumber numberWithInt:255], @"maxV",
								  [NSNumber numberWithInt:0], @"softV",
								  nil]
						  forKey:@"Black"];
		 
		[keyerSettings setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt:0], @"minY",
								  [NSNumber numberWithInt:255], @"maxY",
								  [NSNumber numberWithInt:10], @"softY",
								  [NSNumber numberWithInt:0], @"minU",
								  [NSNumber numberWithInt:255], @"maxU",
								  [NSNumber numberWithInt:10], @"softU",
								  [NSNumber numberWithInt:0], @"minV",
								  [NSNumber numberWithInt:255], @"maxV",
								  [NSNumber numberWithInt:10], @"softV",
								  nil]
							forKey:@"White"];
		
		[keyerSettings setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt:0], @"minY",
								  [NSNumber numberWithInt:255], @"maxY",
								  [NSNumber numberWithInt:10], @"softY",
								  [NSNumber numberWithInt:0], @"minU",
								  [NSNumber numberWithInt:255], @"maxU",
								  [NSNumber numberWithInt:10], @"softU",
								  [NSNumber numberWithInt:0], @"minV",
								  [NSNumber numberWithInt:255], @"maxV",
								  [NSNumber numberWithInt:10], @"softV",
								  nil]
							 forKey:@"Blue"];
		
		[keyerSettings setObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithInt:0], @"minY",
								  [NSNumber numberWithInt:255], @"maxY",
								  [NSNumber numberWithInt:10], @"softY",
								  [NSNumber numberWithInt:0], @"minU",
								  [NSNumber numberWithInt:255], @"maxU",
								  [NSNumber numberWithInt:10], @"softU",
								  [NSNumber numberWithInt:0], @"minV",
								  [NSNumber numberWithInt:255], @"maxV",
								  [NSNumber numberWithInt:10], @"softV",
								  nil] 
						  forKey:@"Custom"];
		
		tv1RegisterSerialReadCallback(MyTV1ReadCallback, self);
		tv1RegisterSerialWriteCallback(MyTV1WriteCallback, self);
	}
	
	return self;
}

- (void) finalize
{
	[super finalize];
}

- (void) dealloc
{
	[readQueue release];
	[writeQueue release];

	[super dealloc];
}

+ (NSArray*) plugInKeys
{
	return [NSArray arrayWithObjects:@"keyerSettings", nil];
}

- (id) serializedValueForKey:(NSString*)key;
{
	return [super serializedValueForKey:key];
}

- (void) setSerializedValue:(id)serializedValue forKey:(NSString*)key
{	
	[super setSerializedValue:serializedValue forKey:key];
}

- (QCPlugInViewController*) createViewController
{
	return [[QCPlugInViewController alloc] initWithPlugIn:self viewNibName:@"Settings"];
}

@end

@implementation v002_D_FuserPlugIn (Execution)

- (NSTimeInterval) executionTimeForContext:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments;
{	
	return nextTimeToExecute;
}

- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	return YES;
}

- (void) enableExecution:(id<QCPlugInContext>)context
{
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
#pragma mark -
#pragma mark Handle Time to execute
    
	nextTimeToExecute = time + kTV1MaxSendSpeedLim;
	
	// Did we get a new Serial Port?
	if([self didValueForInputKeyChange:@"inputSerialPort"])
	{
		[self initPort:self.inputSerialPort];
	}
    
#pragma mark -
#pragma mark Handle QC inputs to Mixer
	
	// output resolution
	if([self didValueForInputKeyChange:@"inputMixerResolution"])
		[self setResolution:self.inputMixerResolution];
  
  // EDID emulation
  if([self didValueForInputKeyChange:@"inputMixerEDIDEmulation"])
		[self setEDID:self.inputMixerEDIDEmulation];
  
	// Lock Panel
	if([self didValueForInputKeyChange:@"inputLockPanel"])
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustFrontPanelLock, (unsigned int) self.inputLockPanel) );
	
#pragma mark -
#pragma mark Mixing
	
	if([self didValueForInputKeyChange:@"inputMaxFadeChannel1"])
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustWindowsMaxFadeLevel, (unsigned int) ( self.inputMaxFadeChannel1 * 100.0)) );

	if([self didValueForInputKeyChange:@"inputMaxFadeChannel2"])
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDB, kTV1FunctionAdjustWindowsMaxFadeLevel, (unsigned int) ( self.inputMaxFadeChannel2 * 100.0)) );

	
#pragma mark -
#pragma mark Keyer Handling
	// Note: All key commands apply to kTV1WindowIDA, as A is 'above' B. (Note this is changed behaviour, Channel 1 has to be above Channel 2 as thats how they sit in the inspector, one fade slider above the other)
	
	if([self didValueForInputKeyChange:@"inputEnableKeyer"])
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerEnable, (unsigned int) self.inputEnableKeyer) );

	if([self didValueForInputKeyChange:@"inputKeyerParameters"])
	{
		// Update appropriate setting(s) in keyerSettings. 
		// inputKeyerParameters should be a dictionary with either 
		// - any custom keyer setting parameter(s) as key-value pairs
		// - whole keyer settings with name as key and dictionary as value
		
		// TODO: Check to see whether min+max YUV or NSColor is supplied and act appropriately.
		NSArray* keyerKeys = [NSArray arrayWithObjects:@"minY", @"minU", @"minV", @"maxY", @"maxU", @"maxV", @"softY", @"softU", @"softV", nil];
		NSDictionary* input = self.inputKeyerParameters;
		
		SPKLog(@"keyerSettings before: %@", keyerSettings);
		
		if (!keyerSettings)
		{
			NSLog(@"!keyerSettings");
		}
		
		for (id thing in input)
		{
			if ([keyerSettingNames containsObject:thing])
			{
				// defensive: when being decoded from saved state, can become non-mutable
				if ([keyerSettings class] != [NSMutableDictionary class])
				{
					NSMutableDictionary* mutCopy = [keyerSettings mutableCopy];
					[keyerSettings release];
					keyerSettings = mutCopy;
				}
				
				[keyerSettings setObject:[[input objectForKey:thing] mutableCopy] forKey:thing];
			}
			else if ([keyerKeys containsObject:thing])
			{
				// defensive: when being decoded from saved state, can become non-mutable
				if ([keyerSettings class] != [NSMutableDictionary class])
				{
					NSMutableDictionary* mutCopy = [keyerSettings mutableCopy];
					[keyerSettings release];
					keyerSettings = mutCopy;
				}
				if ([[keyerSettings valueForKey:@"Custom"] class] != [NSMutableDictionary class])
				{
					NSMutableDictionary* mutCopy = [[keyerSettings valueForKey:@"Custom"] mutableCopy];
					[keyerSettings setObject:mutCopy forKey:@"Custom"];
				}

				[[keyerSettings valueForKey:@"Custom"] setObject:[input objectForKey:thing] forKey:thing];
			}
			else
			{
				NSLog(@"Unusable structure key in Keyer Parameters: %@", thing);
			}
		}
		
		SPKLog(@"keyerSettings after: %@", keyerSettings);
	}
	
	if([self didValueForInputKeyChange:@"inputKeyerMode"] || [self didValueForInputKeyChange:@"inputKeyerParameters"])
	{
		NSDictionary* keySetting = [keyerSettings valueForKey:[keyerSettingNames objectAtIndex:self.inputKeyerMode]];
		// TODO: Check to see whether min+max YUV or NSColor is in dict and act appropriately. 
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerMinY, [[keySetting valueForKey:@"minY"] unsignedIntValue]) );
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerMinU, [[keySetting valueForKey:@"minU"] unsignedIntValue]) );
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerMinV, [[keySetting valueForKey:@"minV"] unsignedIntValue]) );
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerMaxY, [[keySetting valueForKey:@"maxY"] unsignedIntValue]) );
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerMaxU, [[keySetting valueForKey:@"maxU"] unsignedIntValue]) );
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerMaxV, [[keySetting valueForKey:@"maxV"] unsignedIntValue]) );
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerSoftnessY, [[keySetting valueForKey:@"softY"] unsignedIntValue]) );
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerSoftnessU, [[keySetting valueForKey:@"softU"] unsignedIntValue]) );
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerSoftnessV, [[keySetting valueForKey:@"softV"] unsignedIntValue]) );
	}
	
	if([self didValueForInputKeyChange:@"inputSwapChannels"])
	{
		BOOL swapped = self.inputSwapChannels;
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustWindowsWindowSource, swapped ? kTV1SourceRGB2 : kTV1SourceRGB1) );	
		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustWindowsWindowSource, swapped ? kTV1SourceRGB1 : kTV1SourceRGB2) );
	}
		
	
//	if([self didValueForInputKeyChange:@"inputKeyColorMin"])
//		// releases CGColorCopy
//		[self writeKeyColorMin:CGColorCreateCopy(self.inputKeyColorMin)];	
//
//	if([self didValueForInputKeyChange:@"inputKeyColorMax"])
//		// releases CGColor copy
//		[self writeKeyColorMax:CGColorCreateCopy(self.inputKeyColorMax)];	

	if([self didValueForInputKeyChange:@"inputBackgroundColor"])
		// releases CGColor copy
		[self writeBGColor:CGColorCreateCopy(self.inputBackgroundColor)];	
	
//	if([self didValueForInputKeyChange:@"inputKeySoftnessY"])
//		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerSoftnessY, (unsigned int) floor(self.inputKeySoftnessY * 255)) );
//
//	if([self didValueForInputKeyChange:@"inputKeySoftnessU"])
//		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerSoftnessU, (unsigned int) floor(self.inputKeySoftnessU * 255)) );
//
//	if([self didValueForInputKeyChange:@"inputKeySoftnessV "])
//		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerSoftnessV, (unsigned int) floor(self.inputKeySoftnessV * 255)) );
//		
//	if([self didValueForInputKeyChange:@"inputKeySwap"]) // 760 not 750 function?
//		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerSwap, (unsigned int) self.inputKeySwap) );
//
//	if([self didValueForInputKeyChange:@"inputKeyInvertY"])
//		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerInvertY, (unsigned int) self.inputKeyInvertY) );
//		
//	if([self didValueForInputKeyChange:@"inputKeyInvertU"])
//		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerInvertU, (unsigned int) self.inputKeyInvertU) );
//
//	if([self didValueForInputKeyChange:@"inputKeyInvertV"]) // TYPO IN MANUAL - softness for V is noted as 156
//		error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(0, kTV1WindowIDA, kTV1FunctionAdjustKeyerInvertV, (unsigned int) self.inputKeyInvertV) );		

	
#pragma mark -
#pragma mark Aspect Ratio handling
    
	
	return YES;
}

- (void) disableExecution:(id<QCPlugInContext>)context
{
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	// We have to release the port when we stop
	[port release];
}

#pragma mark  -
#pragma mark Serial Port

- (AMSerialPort *)port
{
	return port;
}

- (void)setPort:(AMSerialPort *)newPort
{
	id old = nil;
	
	if (newPort != port) {
		old = port;
		port = [newPort retain];
		[old release];
	}
}

- (void) initPort:(NSUInteger)portIndex
{
	NSString *deviceName = [serialPortArray objectAtIndex:portIndex];

	@synchronized(port)
	{
		if (![deviceName isEqualToString:[port bsdPath]])
		{
			[port close];
			
			[self setPort:[[[AMSerialPort alloc] init:deviceName withName:deviceName type:(NSString*)CFSTR(kIOSerialBSDModemType)] autorelease]];
			
			// register as self as delegate for port
			[port setDelegate:self];
			
			// kill our previous background thead if we had one
			[serialIOThread cancel];
			[serialIOThread release];
			serialIOThread = nil;
			
			// open port - may take a few seconds ...
			if ([port openExclusively])
			{
				NSLog(@"Opened Serial Port: %@", deviceName);
				
				// flush our write queue.
				@synchronized(writeQueue)
				{
					[writeQueue removeAllObjects];
				}
				
				// flush our read queue.
				@synchronized(readQueue)
				{
					[readQueue removeAllObjects];
				}
				
				// set defaults
				[self initializeSerialPortSettings];
		
				// Spawn our background serial IO thread
				serialIOThread = [[NSThread alloc] initWithTarget:self selector:@selector(queueWriteReadsInBackground) object:nil];
				[serialIOThread start];
			}
			else
			{ // an error occured while creating port
				NSLog(@"Could not open serial port: %@", deviceName);
				[self setPort:nil];
			}
		}	
	}
}

#pragma mark -
#pragma mark Threading

// read incoming command queue in background thread to not block our main run loop
// with writing and waiting for responses, since the overhead and timing is non trivial
// and over a frame in duration.

- (void) queueWriteReadsInBackground
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSRunLoop *runLoop =  [NSRunLoop currentRunLoop];
	
	NSTimer* queueTimer = [NSTimer timerWithTimeInterval:kTV1MaxSendSpeedLim target:self selector:@selector(queueRW) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:queueTimer forMode:NSDefaultRunLoopMode];
	
	NSLog(@"Initializing to our suggested settings");
	tv1InitializeMixer();	
	
	NSDate * nextTimerDate = [runLoop limitDateForMode:NSDefaultRunLoopMode];
	
	while (![[NSThread currentThread] isCancelled])
	{
		if([nextTimerDate compare:[NSDate date]] == NSOrderedAscending)
		{
			nextTimerDate = [runLoop limitDateForMode:NSDefaultRunLoopMode];
		}
		[NSThread sleepUntilDate:nextTimerDate]; 
	}
	
	NSLog(@"shutting down thread");
	
	[pool drain];
}

- (void) queueRW
{
    // TODO: Actually handle errors
    
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
    NSString* command = nil;
    @synchronized(writeQueue)
    {
        if([writeQueue count])
        {
           // NSLog(@"write queue is %u long", [writeQueue count]);
            command = [writeQueue objectAtIndex:0];
            [command retain];
            [writeQueue removeObjectAtIndex:0];
        }	
    }
    
    if(command != nil)
    {
        NSString* resultString = nil;
        
        @synchronized(port)
        {       
            // Char 13 is \r (carriage return) in ASCII
            resultString = [port readBytes:20 upToChar:13 usingEncoding:NSASCIIStringEncoding error:nil];
            [resultString retain];
                          
            [port writeString:command usingEncoding:NSASCIIStringEncoding error:NULL];
            [command release];
        }
        
        @synchronized(readQueue)
        {	
            if(resultString)
            {
                [readQueue addObject:resultString];
                [resultString release];

                // reset error for next pass
                error = kTV1NoError;
            }
            else
            {
                error = kTV1NoReply;
            }
            
        }		
    }
	[pool drain];
}
		
#pragma mark -
#pragma mark Mixer & Serial Command Queue

// Add to our command to our write queue
- (void) writeString:(NSString*)command priority:(v002DFuserWritePriority)priority
{	
	@synchronized(writeQueue)
	{
		// handle priorities. Low Priority gets dropped
		// High Priority replaces last submitted command 
		if([writeQueue count] >= kv002DFuserQueueLength)
		{			
			if(priority == v002DFuserWriteHighPriority)
			{	
				[writeQueue replaceObjectAtIndex:[writeQueue count] - 1 withObject:command];
			}
			
		}
		else
			[writeQueue addObject:command];
	}
}

- (NSString*) readString
{	
	NSString* resultString = nil;
	@synchronized(readQueue)
	{
		if([readQueue count])
		{
			resultString = [readQueue objectAtIndex:0];
			[resultString retain];
			
			[readQueue removeObjectAtIndex:0];
		}
	}
	return [resultString autorelease];
}

#pragma mark -
#pragma mark Helpers

- (void) writeKeyColorMin:(CGColorRef)rgbColor
{
	const CGFloat * rgbColorArray;
	rgbColorArray =  CGColorGetComponents(rgbColor);
	
	error = tv1SetKeyerMinColor(rgbColorArray[0], rgbColorArray[1], rgbColorArray[2]);
	
	CGColorRelease(rgbColor);
}

- (void) writeKeyColorMax:(CGColorRef)rgbColor
{
	const CGFloat * rgbColorArray;
	rgbColorArray =  CGColorGetComponents(rgbColor);
	
	error = tv1SetKeyerMaxColor(rgbColorArray[0], rgbColorArray[1], rgbColorArray[2]);
	
	CGColorRelease(rgbColor);
}

- (void) writeBGColor:(CGColorRef)rgbColor;
{
	const CGFloat * rgbColorArray;
	rgbColorArray =  CGColorGetComponents(rgbColor);
	
	error = tv1SetBackgroundColor(rgbColorArray[0], rgbColorArray[1], rgbColorArray[2]);
	
	CGColorRelease(rgbColor);
}

- (void) initializeSerialPortSettings
{	
	// set up our serial port to proper speed, parity, etc.
	[port setSpeed:B57600];
	[port setParity:kAMSerialParityNone];
	[port setStopBits:kAMSerialStopBitsOne];
	[port setDataBits:8];
	
	// disable all flow control
	[port setRTSInputFlowControl:NO];
	[port setDTRInputFlowControl:NO];
	[port setCTSOutputFlowControl:NO];
	[port setDSROutputFlowControl:NO];
	[port setCAROutputFlowControl:NO];
	
	// timeout set pretty low, just below 2 frames.
	[port setReadTimeout:kTV1MaxSendSpeedLim];
	
	[port commitChanges];
}

- (void) setResolution:(NSUInteger)index
{
	// Pull the serial string for the appropriate selected resolution
	NSNumber* resolution = [[resolutionsArray objectAtIndex:index] valueForKey:@"resolutionNum"];
	
	// send.
	error = tv1SetResolution([resolution unsignedIntValue]);
}

- (void) setEDID:(NSUInteger)index
{
    // SPK-DFuser: Slot 4 is reserved for Triplehead2Go 
    if (index == 3)
    {
        // Load EDID binary file from resource folder
        NSString* path = [[NSBundle bundleForClass:[self class]] pathForResource:@"mtx edid" ofType:@"bin"];
        NSData* edid = [NSData dataWithContentsOfFile:path];
        
        SPKLog(@"edid path: %@, data: %@", path, edid);

        [self uploadEDID:edid toSlot:3];
    }
  
    // Do for both DVI1 & 2
    error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(kTV1SourceRGB1, kTV1WindowIDA, kTV1FunctionAdjustSourceEDID, index) );
    error = tv1SubmitSerialCommand( tv1CreateSerialCommandString(kTV1SourceRGB2, kTV1WindowIDB, kTV1FunctionAdjustSourceEDID, index) );
}

- (void) uploadEDID:(NSData*)edidData toSlot:(NSUInteger)edidSlotIndex
{
	// The EDID commands are differently formed and take longer than typical to process.
	// Therefore we're setting a higher timeout and generally handling this manually.
	NSTimeInterval serialReadTimeoutOriginal = [port readTimeout];
	[port setReadTimeout:2];
	
	BOOL ackFail = NO;
	
	NSUInteger commandLength, ackLength; 
	NSUInteger i,j;
	
	// TASK: Check and return if processor's EDID is already correct

	// This command is reverse engineered from RS232 comms logged between TVOne test app and unit

	// To read EDID, its requested as extra long chunks in the acknowledgement to the command
	// Command: 8 bytes of command (see code below)
	// Acknowledgement: 8 bytes of command (see code below) + 32 bytes of EDID payload + End byte

	commandLength = 8+1; 
	ackLength = 8+32+1;
	
	char readEDIDBytes[256];
	NSData* readEDIDData;

	for (i=0; i<[edidData length]; i=i+32)
    {
		char command[commandLength];
		
		command[0] = 0x53;
		command[1] = 0x07;
		command[2] = 0xA2;
		command[3] = 0x7;
		command[4] = edidSlotIndex; // as per edidSlotNames
		command[5] = 0;
		command[6] = i / 32; // ie. chunk index
		command[7] = 0;
		command[8] = 0x3F;
		
		SPKLog(@"cmd: %@", [NSData dataWithBytes:command length:commandLength]);
		
		// Clear read buffer
		if ([port bytesAvailable]) [port readAndReturnError:nil];
		
		// Write command
		[port writeBytes:command length:commandLength error:nil];

		// Wait for Acknowledgement
		NSData* ack = [port readBytes:ackLength error:nil];
		
		SPKLog(@"ack: %@", ack);
		
		if ([ack length] == ackLength) // We should also test for success bit.
		{
			for (j=0; j<32; j++)
			{
				if (8+j < [ack length]) 
					[ack getBytes:(readEDIDBytes+i+j) range:NSMakeRange(8+j, 1)];
				else 
					*(readEDIDBytes+i+j) = 0;
			}
		}
		else
		{
			SPKLog(@"Failed to read EDID part");
			ackFail = YES;
			break;
		}
		
		// I am quite aware this looks insane. 
		// Ideally all EDID serial would be rolled into [self writeString] with custom timing etc.
		// The TVOne has successfully replied with the EDID part, and yet if you ask it straight away for the next part, it will fail perfectly predictably.
		// Note no such restriction when writing. Crazy.
		// If the sleep value is 0.5 it will fail on the fourth read. You try getting it to work without.
		sleep(1);
	}
	
	// If we failed on an acknowledgement, lets bail as we can't trust the result.
	// (Using ackFail so can reattempt read/write in future version)
	if (ackFail) 
	{
		NSLog(@"Failed to read existing EDID, bailing before write");
		
		[port setReadTimeout:serialReadTimeoutOriginal];
		return;
	}
	
	// We want to compare like-for-like, so using length of edidData rather than full 256
	readEDIDData = [NSData dataWithBytes:readEDIDBytes length:[edidData length]];
		
	if ([readEDIDData isEqual:edidData])
	{
		NSLog(@"Correct EDID already present, skipping upload");
		
		[port setReadTimeout:serialReadTimeoutOriginal];
		return;
	}
	else
	{
		NSLog(@"EDID requires uploading.");
		SPKLog(@"Found: %@", readEDIDData);
	}

	
	// TASK: Upload EDID

	// This command is reverse engineered from a VB snippet and RS232 comms logged between TVOne test app and unit 
	
	// To write EDID, its broken into chunks and sent as a series of extra-long commands
	// Command: 8 bytes of command (see code below) + 32 bytes of EDID payload + End byte
	// Acknowledgement: 53 02 40 95 (Hex)
	
	ackFail = NO;

	commandLength = 8+32+1;
	ackLength = 4;

	char ackBytes[] = {0x53, 0x02, 0x40, 0x95};
	NSData* goodAck = [NSData dataWithBytes:ackBytes length:ackLength];

	// We want to upload full EDID slot, ie. zero out to 256 even if edidData is only 128bytes.
	for (i=0; i<256; i=i+32)
	{
		char command[commandLength];

		command[0] = 0x53;
		command[1] = 0x27;
		command[2] = 0x22;
		command[3] = 0x7;
		command[4] = edidSlotIndex; // as per edidSlotNames
		command[5] = 0;
		command[6] = i / 32; // ie. chunk index
		command[7] = 0;

		for (j=0; j<32; j++)
		{
		  if (i+j < [edidData length]) 
			[edidData getBytes:(command+8+j) range:NSMakeRange(i+j, 1)];
		  else 
			*(command+8+j) = 0;
		}

		command[8+32] = 0x3F;

		SPKLog(@"EDID command: %@", [NSData dataWithBytes:command length:commandLength]);

		// Writing directly not via callback as we are no longer 20 bytes long
		// Also, null terminated strings surely don't work here as we've got hex bytes in the command which are often 0.
		// Also also, using [self writeString] didn't work either, AMSerialDebug showed null was ultimately being sent
		// TODO: introduce size_t length into callbacks, and don't ever rely on null termination
		// FIXME: roll this section into callbacks when that is done
		
		// Clear read buffer
		if ([port bytesAvailable]) [port readAndReturnError:nil];
		
		// Write command
		[port writeBytes:command length:commandLength error:nil];

		// Wait for Acknowledgement
		NSData* ack = [port readBytes:ackLength error:nil];

		// Check acknowledgement			
		if ([ack isEqual:goodAck])
		{
			SPKLog(@"EDID part write OK");
		}
		else 
		{
			ackFail = YES;
			break;
			SPKLog(@"EDID part write failed. ACK: %@", ack);
		}
	}
	
	if (ackFail)
	{
		NSLog(@"EDID Write failed. And possibly corrupted the entry. You should retry.");
	}
	
	[port setReadTimeout:serialReadTimeoutOriginal];
}
@end
