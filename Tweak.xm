//#import <SpringBoard/SBVolumeHardwareButton.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import <AVFoundation/AVCaptureDevice.h>


#define TWEAK_NAME @"FlashlightSettings"

@interface Debug : NSObject
	+(void)Log:(NSString *)msg;
@end

@implementation Debug
	//	Show log with tweak name as prefix for easy grep
	+(void)Log:(NSString *)msg {
		NSLog(@"%@: %@", TWEAK_NAME, msg);
	}
@end


//	=========================== Classes / Functions ===========================



//	=========================== Hooks ===========================


NSTimeInterval lastVolumeUpPressTime = 0;
NSTimeInterval lastVolumeDownPressTime = 0;






void toggleFlashlight() {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    if ([device hasTorch] && [device hasFlash]) {
        NSError *error = nil;

        if ([device lockForConfiguration:&error]) {
            if ([device isTorchActive]) {
                // Turn off the flashlight
                [device setTorchMode:AVCaptureTorchModeOff];
            } else {
                // Turn on the flashlight
                [device setTorchMode:AVCaptureTorchModeOn];
            }
            [device unlockForConfiguration];
        } else {
            [Debug Log:[NSString stringWithFormat:@"Error locking device for flashlight configuration: %@", error.localizedDescription]];
        }
    }
}

bool flashlightOn() {
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    if ([device hasTorch] && [device hasFlash]) {
        NSError *error = nil;

        if ([device lockForConfiguration:&error]) {
            if ([device isTorchActive]) {
                return YES;
            } else {
                return NO;
            }
        }
    }
	return NO;
}






void detectBothVolumeButtonsPressed() {
    if (fabs(lastVolumeUpPressTime - lastVolumeDownPressTime) < 0.1) {
        NSLog(@"FlashlightSettings: Both volume buttons pressed!");
        // Trigger the desired action

		toggleFlashlight();
    }
}



%hook SBVolumeHardwareButtonActions
	//%property (nonatomic) NSTimeInterval lastVolumeUpPressTime;
	//%property (nonatomic) NSTimeInterval lastVolumeDownPressTime;


-(void)volumeIncreasePressDownWithModifiers:(long long)arg1 {
	NSLog(@"FlashlightSettings: volumeUp Pressed");
	NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
	lastVolumeUpPressTime = currentTime;

	detectBothVolumeButtonsPressed();

	%orig;
}

-(void)volumeDecreasePressDownWithModifiers:(long long)arg1 {
	NSLog(@"FlashlightSettings: volumeDown Pressed");
	NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
	lastVolumeDownPressTime = currentTime;

	detectBothVolumeButtonsPressed();

	%orig;
}
%end





%hook SBBacklightController
	-(BOOL)shouldTurnOnScreenForBacklightSource:(long long)arg1 {
		if (flashlightOn() && (arg1 == 9 || arg1 == 20)) {
			return NO;
		}

		return %orig;
	}
%end



%ctor {
	[Debug Log:[NSString stringWithFormat:@"============== %@ started ==============", TWEAK_NAME]];
}
