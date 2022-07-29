#
# To build for non app store: make app;make notarize; make staple; make shipit
#
# To build for Mac App Store: make app; make upload # NOT TESTED YET!
#
#    make 
#    make SCHEME=<SCHEME>
#
APPNAME = FrogBlog

EXPORTPATH = ~/Desktop/${APPNAME}-Build
ARCHIVE = ${EXPORTPATH}/${APPNAME}.xcarchive
SCHEME = ${APPNAME}
PROJECT = ${APPNAME}.xcodeproj
DEVUSER = rad@robdodson.net
ZIPFILE = ${SCHEME}.zip
APP_BUNDLE_ID = Shy-Frog.${APPNAME}
APP = ${EXPORTPATH}/${APPNAME}.app
SDK = `xcodebuild -showsdks | grep macosx | cut -f3`
PROFILENAME = frogradio-notarize
NOTARYTOOL_PASSWORD = tsze-wegl-vsfj-wakd
TEAM_ID = ZYF5X8SV2F


all:
	echo Using: ${SDK}
	xcodebuild  -project ${PROJECT} -scheme ${SCHEME} -configuration release

clean:
	xcodebuild -project ${PROJECT} -scheme ${SCHEME} clean

archive:
	xcodebuild -project ${PROJECT} -scheme ${SCHEME} clean archive -configuration release ${SDK} -archivePath ${ARCHIVE} 

app: archive
	rm -rf ${APP}
	xcodebuild -exportArchive -archivePath ${ARCHIVE} -exportPath ${EXPORTPATH} -exportOptionsPlist ExportOptions.plist 

upload: archive
	xcrun altool --upload-app --type osx --file ${ARCHIVE} --username ${DEVUSER} 

notarize:
	/usr/bin/ditto -c -k --keepParent ${APP} ${ZIPFILE}
	xcrun notarytool store-credentials ${PROFILENAME} --password ${NOTARYTOOL_PASSWORD} --apple-id ${DEVUSER} --team-id ${TEAM_ID}
	xcrun notarytool submit ${ZIPFILE} --keychain-profile ${PROFILENAME}  --wait

staple:
	xcrun stapler staple ${APP}

shipit:
	cp ${APP} ~/Desktop
	(cd ~/Pro/dev/devtools/InstallerStuff/${APPNAME};../../bin/shipit)

