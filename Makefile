ARCHS := arm64
TARGET := iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES += TrollFools
INSTALL_TARGET_PROCESSES += trollfoolscli

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = TrollFools
TrollFools_XCODE_SCHEME = TrollFools

include $(THEOS_MAKE_PATH)/xcodeproj.mk

SUBPROJECTS += TrollFoolsTweak

include $(THEOS_MAKE_PATH)/aggregate.mk

before-all::
	chmod +x devkit/standardize-entitlements.sh
	devkit/standardize-entitlements.sh

before-package::
	mv $(THEOS_STAGING_DIR)/Applications/TrollFools.app $(THEOS_STAGING_DIR)/Applications/TrollAOV.app
	mv $(THEOS_STAGING_DIR)/Applications/TrollAOV.app/TrollFools $(THEOS_STAGING_DIR)/Applications/TrollAOV.app/TrollAOV
	plutil -replace CFBundleDisplayName -string "Troll AOV" $(THEOS_STAGING_DIR)/Applications/TrollAOV.app/Info.plist
    plutil -replace CFBundleName -string "Troll AOV" $(THEOS_STAGING_DIR)/Applications/TrollAOV.app/Info.plist
	plutil -replace CFBundleIdentifier -string "com.Nakoto.TrollAOV" $(THEOS_STAGING_DIR)/Applications/TrollAOV.app/Info.plist
	plutil -replace CFBundleExecutable -string "TrollAOV" $(THEOS_STAGING_DIR)/Applications/TrollAOV.app/Info.plist
	plutil -replace CFBundleShortVersionString -string "0.1" $(THEOS_STAGING_DIR)/Applications/TrollAOV.app/Info.plist
	plutil -replace CFBundleVersion -string "0.1" $(THEOS_STAGING_DIR)/Applications/TrollAOV.app/Info.plist
	$(ECHO_NOTHING)ldid -STrollFools/TrollFools.entitlements $(THEOS_STAGING_DIR)/Applications/TrollAOV.app/TrollAOV$(ECHO_END)
	$(ECHO_NOTHING)ldid -STrollFools/TrollFools.entitlements $(THEOS_STAGING_DIR)/usr/local/bin/trollfoolscli$(ECHO_END)

export THEOS_PACKAGE_INSTALL_PREFIX
export THEOS_STAGING_DIR
after-package::
	chmod +x devkit/tipa.sh
	devkit/tipa.sh
