include $(THEOS)/makefiles/common.mk


ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
	ARCHS = arm64 arm64e
	TARGET = iphone:clang:15.5:15.0
else
	ARCHS = armv7 armv7s arm64 arm64e
	TARGET = iphone:clang:14.2:8.0
endif


BUNDLE_NAME = FlashlightSettingsPrefs

FlashlightSettingsPrefs_FILES = FSPRootListController.m
FlashlightSettingsPrefs_FRAMEWORKS = UIKit
FlashlightSettingsPrefs_PRIVATE_FRAMEWORKS = Preferences
FlashlightSettingsPrefs_INSTALL_PATH = /Library/PreferenceBundles
FlashlightSettingsPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
