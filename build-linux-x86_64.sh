#!/bin/bash

set -e

RUNELITE_LAUNCHER_VERSION="2.7.7"
RUNELITE_LAUNCHER_CHKSUM="85a0d34abef6c08561018c3600c94db113125d69318fe71fc1fe4a7ea2d49c6c"

umask 022

source .jdk-versions.sh

rm -rf build/linux-x64
mkdir -p build/linux-x64

mkdir -p bin

if ! [ -f bin/RuneLite.AppImage ] ; then
    curl -Lo bin/RuneLite.AppImage \
        https://github.com/runelite/launcher/releases/download/${RUNELITE_LAUNCHER_VERSION}/RuneLite.AppImage
    chmod +x bin/RuneLite.AppImage
fi

echo "$RUNELITE_LAUNCHER_CHKSUM bin/RuneLite.AppImage" | sha256sum -c

if ! [ -f linux64_jre.tar.gz ] ; then
    curl -Lo linux64_jre.tar.gz $LINUX_AMD64_LINK
fi

echo "$LINUX_AMD64_CHKSUM linux64_jre.tar.gz" | sha256sum -c

pushd bin
./RuneLite.AppImage --appimage-extract
popd

# Note: Host umask may have checked out this directory with g/o permissions blank
chmod -R u=rwX,go=rX appimage

mkdir -p build/linux-x64/
cp bin/squashfs-root/RuneLite build/linux-x64/
cp bin/squashfs-root/RuneLite.jar build/linux-x64/
cp packr/linux-x64-config.json build/linux-x64/config.json
cp bin/squashfs-root/runelite.desktop build/linux-x64/
cp appimage/runelite.png build/linux-x64/
mkdir -p build/linux-x64/usr/share/icons/hicolor/128x128/apps/
cp appimage/runelite.png build/linux-x64/usr/share/icons/hicolor/128x128/apps/

tar zxf linux64_jre.tar.gz
mv $LINUX_AMD64_RELEASE-jre build/linux-x64/jre

pushd build/linux-x64/
mkdir -p jre/lib/amd64/server/
ln -s ../../server/libjvm.so jre/lib/amd64/server/ # packr looks for libjvm at this hardcoded path

# Symlink AppRun -> RuneLite
ln -s RuneLite AppRun

# Ensure RuneLite is executable to all users
chmod 755 RuneLite
popd

curl -z appimagetool-x86_64.AppImage -o appimagetool-x86_64.AppImage -L https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
curl -z runtime-x86_64 -o runtime-x86_64 -L https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64

chmod +x appimagetool-x86_64.AppImage

./appimagetool-x86_64.AppImage \
	--runtime-file runtime-x86_64 \
	build/linux-x64/ \
	RuneLite.AppImage

./RuneLite.AppImage --help
