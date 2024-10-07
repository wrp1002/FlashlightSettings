#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "Tweak.h"


#define TWEAK_NAME @"FlashlightSettings"
#define BUNDLE [NSString stringWithFormat:@"com.wrp1002.%@", [TWEAK_NAME lowercaseString]]
#define BUNDLE_NOTIFY (CFStringRef)[NSString stringWithFormat:@"%@/ReloadPrefs", BUNDLE]

@interface Debug : NSObject
	+(void)Log:(NSString *)msg;
@end

@implementation Debug
	//	Show log with tweak name as prefix for easy grep
	+(void)Log:(NSString *)msg {
		NSLog(@"%@: %@", TWEAK_NAME, msg);
	}
@end


bool enabled;
bool disableRaiseToWake;
bool disableTapToWake;
bool setMaxBrightness;
bool autoLock;
NSString *flashlightShortcut;
bool flashlightTimeoutEnabled;
NSInteger flashlightTimeoutVal;

NSTimeInterval lastVolumeUpPressTime = 0;
NSTimeInterval lastVolumeDownPressTime = 0;
NSTimer *flashlightTimer;


// Preference functions
NSUserDefaults *prefs = nil;


static void InitPrefs(void) {
	if (!prefs) {
		NSDictionary *defaultPrefs = @{
			@"kEnabled": @YES,
			@"kAutoLock": @NO,
			@"kDisableRaiseToWake": @YES,
			@"kDisableTapToWake": @YES,
			@"kMaxLevel": @YES,
			@"kFlashlightShortcut": @"disabled",
			@"kFlashlightTimeoutEnabled": @NO,
			@"kFlashlightTimeoutVal": @15,
		};
		prefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];
		[prefs registerDefaults:defaultPrefs];
	}
}


static void UpdatePrefs() {
	enabled = [prefs boolForKey: @"kEnabled"];
	autoLock = [prefs boolForKey: @"kAutoLock"];
	disableRaiseToWake = [prefs boolForKey: @"kDisableRaiseToWake"];
	disableTapToWake = [prefs boolForKey: @"kDisableTapToWake"];
	setMaxBrightness = [prefs boolForKey: @"kMaxLevel"];
	flashlightShortcut = [prefs stringForKey: @"kFlashlightShortcut"];
	flashlightTimeoutEnabled = [prefs boolForKey:@"kFlashlightTimeoutEnabled"];
	flashlightTimeoutVal = [prefs integerForKey:@"kFlashlightTimeoutVal"];
}


static void PrefsChangeCallback(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo) {
	UpdatePrefs();
}


// Other util functions

static void ToggleFlashlight() {
	SBUIFlashlightController *flashlightController = [NSClassFromString(@"SBUIFlashlightController") sharedInstance];

	if ([flashlightController isAvailable]) {
		if ([flashlightController level]) {
			[flashlightController _turnPowerOff];
		}
		else {
			if (setMaxBrightness)
				[flashlightController setLevel:4];
			else
				[flashlightController setLevel:[flashlightController _loadFlashlightLevel]];

			[flashlightController turnFlashlightOnForReason:@"Flashlight Shortcut"];
		}
	}
	else
		[Debug Log:@"SBUIFlashlightController not available"];
}

static void TurnOffFlashlight() {
	SBUIFlashlightController *flashlightController = [NSClassFromString(@"SBUIFlashlightController") sharedInstance];

	if ([flashlightController isAvailable]) {
		[flashlightController _turnPowerOff];
	}
	else
		[Debug Log:@"SBUIFlashlightController not available"];
}


static void StartFlashlightTimer() {
	if (flashlightTimer) {
		[flashlightTimer invalidate];
		flashlightTimer = nil;
	}

	flashlightTimer = [NSTimer scheduledTimerWithTimeInterval:(flashlightTimeoutVal * 60)
								repeats:NO
								block:^(NSTimer * _Nonnull timer) {
									TurnOffFlashlight();
						}];

}


static bool FlashlightOn() {
	SBUIFlashlightController *flashlightController = [NSClassFromString(@"SBUIFlashlightController") sharedInstance];

	if ([flashlightController isAvailable]) {
		return (bool)([flashlightController level]);
	}
	else
		return NO;
}


static void lockDevice() {
	id springBoard = (SpringBoard *)[%c(SpringBoard) sharedApplication];

	if (springBoard) {
		SBUserAgent *userAgent = [springBoard valueForKey:@"_pluginUserAgent"];

		if (userAgent) {
			[userAgent lockAndDimDevice];
		}
		else {
			[Debug Log:@"No SpringBoard UserAgent"];
		}
	}
	else
		[Debug Log:@"No SpringBoard"];
}


static void DetectBothVolumeButtonsPressed() {
	if (fabs(lastVolumeUpPressTime - lastVolumeDownPressTime) < 0.1) {
		ToggleFlashlight();
	}
}


//	=========================== Hooks ===========================


%hook SBUIFlashlightController
	-(void)_updateStateWithAvailable:(BOOL)arg1 level:(unsigned long long)arg2 overheated:(BOOL)arg3 {
		if (arg2 && flashlightTimeoutEnabled) {
			StartFlashlightTimer();
		}

		%orig;
	}

	-(void)turnFlashlightOnForReason:(id)arg1 {
		if (autoLock && arg1)
			lockDevice();

		%orig;
	}
%end


%hook SBVolumeHardwareButtonActions
	-(void)volumeIncreasePressDownWithModifiers:(long long)arg1 {
		if (enabled && [flashlightShortcut isEqualToString: @"volume"]) {
			NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
			lastVolumeUpPressTime = currentTime;
			DetectBothVolumeButtonsPressed();
		}

		%orig;
	}

	-(void)volumeDecreasePressDownWithModifiers:(long long)arg1 {
		if (enabled && [flashlightShortcut isEqualToString: @"volume"]) {
			NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
			lastVolumeDownPressTime = currentTime;
			DetectBothVolumeButtonsPressed();
		}

		%orig;
	}
%end


%hook SBLockHardwareButton
	-(void)triplePress:(id)arg1 {
		if (enabled && [flashlightShortcut isEqualToString: @"tripleLock"]) {
			ToggleFlashlight();
			return;
		}

		%orig;
	}
%end


%hook SBBacklightController
	-(BOOL)shouldTurnOnScreenForBacklightSource:(long long)arg1 {
		if (!enabled)
			return %orig;

		if (!FlashlightOn())
			return %orig;

		if (arg1 == 9 && disableTapToWake)
			return NO;

		if (arg1 == 20 && disableRaiseToWake)
			return NO;

		return %orig;
	}
%end



%ctor {
	[Debug Log:[NSString stringWithFormat:@"============== %@ started ==============", TWEAK_NAME]];

	InitPrefs();
	UpdatePrefs();

	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		&PrefsChangeCallback,
		BUNDLE_NOTIFY,
		NULL,
		0
	);
}
