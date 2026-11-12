#!/bin/bash
set -e
cd "$(dirname "$0")"
AJ=~/tc/android.jar
rm -rf build && mkdir -p build/{compiled,gen,classes,apk/assets}
aapt2 compile --dir res -o build/compiled/res.zip
aapt2 link -o build/base.apk -I $AJ --manifest AndroidManifest.xml --java build/gen build/compiled/res.zip --min-sdk-version 24 --target-sdk-version 34 --version-code ${VC:-1} --version-name ${VN:-1.0} -A assets_root
javac -nowarn --release 8 -cp $AJ -d build/classes $(find src build/gen -name '*.java') 2>&1 | grep -v "^warning\|JAVA_TOOL" || true
dalvik-exchange --dex --min-sdk-version=24 --output=build/apk/classes.dex build/classes
cp build/base.apk build/unaligned.apk
(cd build/apk && zip -q -0 ../unaligned.apk classes.dex)
zipalign -f -p 4 build/unaligned.apk build/aligned.apk
[ -f ~/tc/debug.keystore ] || keytool -genkeypair -keystore ~/tc/debug.keystore -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Iron Arena,O=Mahad,C=US" >/dev/null 2>&1
apksigner sign --ks ~/tc/debug.keystore --ks-pass pass:android --key-pass pass:android --out build/IronArena.apk build/aligned.apk
apksigner verify -v build/IronArena.apk | head -5
ls -la build/IronArena.apk
