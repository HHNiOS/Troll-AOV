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
	mv $(THEOS_STAGING_DIR)/Applications/TrollFools.app $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app
	mv $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/TrollFools $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/NakotoPanel
	plutil -replace CFBundleDisplayName -string "Nakoto Panel FF" $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/Info.plist
	plutil -replace CFBundleName -string "Nakoto Panel FF" $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/Info.plist
	plutil -replace CFBundleIdentifier -string "com.Nakoto.NakotoPanelFF" $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/Info.plist
	plutil -replace CFBundleExecutable -string "NakotoPanelFF" $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/Info.plist
	plutil -replace CFBundleShortVersionString -string "0.1" $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/Info.plist
	plutil -replace CFBundleVersion -string "0.1" $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/Info.plist
	
	# === ĐOẠN XÓA URL SCHEME (DẤU TRỪ ĐỂ BỎ QUA LỖI NẾU KEY KHÔNG TỒN TẠI) ===
	-plutil -remove CFBundleDocumentTypes $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/Info.plist
	-plutil -remove UTImportedTypeDeclarations $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/Info.plist
	-plutil -remove UTExportedTypeDeclarations $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/Info.plist
	-plutil -remove CFBundleURLTypes $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/Info.plist
	
	# Xóa sạch các file ngôn ngữ InfoPlist.strings để nó không đè tên app nữa
	find $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app -name "InfoPlist.strings" -delete
	
	$(ECHO_NOTHING)ldid -STrollFools/TrollFools.entitlements $(THEOS_STAGING_DIR)/Applications/NakotoPanel.app/NakotoPanel$(ECHO_END)
	$(ECHO_NOTHING)ldid -STrollFools/TrollFools.entitlements $(THEOS_STAGING_DIR)/usr/local/bin/trollfoolscli$(ECHO_END)

export THEOS_PACKAGE_INSTALL_PREFIX
export THEOS_STAGING_DIR
after-package::
	chmod +x devkit/tipa.sh
	devkit/tipa.sh
