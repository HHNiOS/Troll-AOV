#!/bin/sh

XCCONFIG_NAME=TrollFools/Version.xcconfig
VERSION=$(awk -F "=" '/VERSION/ {print $2}' $XCCONFIG_NAME | tr -d ' ')
BUILD_NUMBER=$(awk -F "=" '/BUILD_NUMBER/ {print $2}' $XCCONFIG_NAME | tr -d ' ')

mkdir -p packages $THEOS_STAGING_DIR/Payload

# Trỏ đúng vào thư mục NakotoPanel.app đã đổi tên ở Makefile
cp -rp $THEOS_STAGING_DIR$THEOS_PACKAGE_INSTALL_PREFIX/Applications/NakotoPanel.app $THEOS_STAGING_DIR/Payload
chmod 0644 $THEOS_STAGING_DIR/Payload/NakotoPanel.app/Info.plist

cd $THEOS_STAGING_DIR
# Tự động đóng gói Payload chứa NakotoPanel.app thành file .tipa mang tên NakotoPanel
zip -qr NakotoPanel_$VERSION-$BUILD_NUMBER.tipa Payload
cd -

cp -p $THEOS_STAGING_DIR/NakotoPanel_$VERSION-$BUILD_NUMBER.tipa packages
