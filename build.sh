#!/bin/sh

date=`date '+%Y%m%d'`

base_sdk_dir="~/Desktop/unity-ads-builds"
base_sdk_dir=`eval "echo $base_sdk_dir"`

prefix=$(cd "$(dirname "$0")"; pwd)
cd $prefix

unity_app="/Applications/Unity-3.5.7/Unity.app/Contents/MacOS/Unity"

ios_repo="ios"
ios_build="unknown"

android_repo="android/sources"
android_build="unknown"

if [ -e $ios_repo/UnityAds/UnityAdsProperties/UnityAdsProperties.m ]; then
    ios_build=`grep "kUnityAdsVersion = " $ios_repo/UnityAds/UnityAdsProperties/UnityAdsProperties.m | sed 's/[^0-9]*//g'`
fi

if [ -e $android_repo/src/com/unity3d/ads/android/properties/UnityAdsConstants.java ]; then
    android_build=`grep "UNITY_ADS_VERSION = " $android_repo/src/com/unity3d/ads/android/properties/UnityAdsConstants.java | sed 's/[^0-9]*//g'`
fi

set -e
# set -v

unity_sdk_date="$date-$ios_build-$android_build"
unity_sdk_dir="$base_sdk_dir/unity/$unity_sdk_date"

rm -rf $unity_sdk_dir
mkdir -p $unity_sdk_dir
(cd $unity_sdk_dir/.. ; ln -sfh $unity_sdk_date latest)

android_sdk_date="$date-$android_build"
android_sdk_dir="$base_sdk_dir/android/$android_sdk_date"
android_sdk_zip="$base_sdk_dir/android/UnityAds-android-$android_sdk_date.zip"

rm -rf $android_sdk_dir
rm -f $android_sdk_zip

mkdir -p $android_sdk_dir
(cd $android_sdk_dir/.. ; ln -sfh $android_sdk_date latest)

rm -rf unity/unityads-project/Assets/Plugins/Android
mkdir -p unity/unityads-project/Assets/Plugins/Android

mkdir -p unity/unityads-project/Assets/Plugins/UnityAds/iOS

#rm -rf unity/unityads-project/Assets/Plugins/UnityAds/Resources
#rm -f unity/unityads-project/Assets/Plugins/UnityAds/Resources.meta

rm -rf temp
mkdir temp

cp -R unity/unityads-project/Assets temp/

echo "Building iOS project (build $ios_build)"
(cd $ios_repo ; ./build.sh ; cp -rp build/Release-iphoneos/UnityAds.bundle $prefix/temp/Assets/Plugins/UnityAds/iOS ; cp -rp build/Release-iphoneos/UnityAds.framework $prefix/temp/Assets/Plugins/UnityAds/iOS )

echo "Building Android project (build $android_build)"
(cd $android_repo && make clean && make prepare debug && cp -rp build/. $prefix/temp/Assets/Plugins/Android/unityads ; cp -rp build/. $android_sdk_dir ; cd build/. ; zip -9 -r -y $android_sdk_zip .)

echo "Building Unity plugin"
$unity_app -quit -batchmode -projectPath $prefix/temp  -executeMethod UnityAdsPackageGenerator.CreatePackage
mv temp/UnityAds.unitypackage $unity_sdk_dir

rm -rf temp

open $unity_sdk_dir
