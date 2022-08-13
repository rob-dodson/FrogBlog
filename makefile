#
# To build for non app store: make app;make notarize; make staple; make shipit
#
# To build for Mac App Store: make app; make upload # NOT TESTED YET!
#
#    make 
#    make SCHEME=<SCHEME>
#
TEAM_ID = ZYF5X8SV2F
APPNAME = FrogBlog
PROFILENAME = frogradio-notarize
DEVUSER = rad@robdodson.net
SCHEME = ${APPNAME}
EXPORTPATH = ~/Desktop/${SCHEME}-Build
ARCHIVE = ${EXPORTPATH}/${SCHEME}.xcarchive
PROJECT = ${APPNAME}.xcodeproj
ZIPFILE = ${SCHEME}.zip
APP_BUNDLE_ID = Shy-Frog.${APPNAME}
APP = ${EXPORTPATH}/${APPNAME}.app
SDK = `xcodebuild -showsdks | grep macosx | uniq | cut -f3`
ITUNES_CONNECT_ONE_TIME_PASSWORD=`cat ~/Pro/dev/keys/ITUNES_CONNECT_ONE_TIME_PASSWORD`
NOTARYTOOL_PASSWORD=`cat ~/Pro/dev/keys/NOTARYTOOL_PASSWORD`



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
	/usr/bin/ditto -c -k --keepParent ${ARCHIVE} ${ZIPFILE}
	xcrun altool --upload-app --type osx --file ${ZIPFILE} -u ${DEVUSER} -p ${ITUNES_CONNECT_ONE_TIME_PASSWORD}
	rm ${ZIPFILE}

notarize:
	/usr/bin/ditto -c -k --keepParent ${APP} ${ZIPFILE}
	xcrun notarytool store-credentials ${PROFILENAME} --password ${NOTARYTOOL_PASSWORD} --apple-id ${DEVUSER} --team-id ${TEAM_ID}
	xcrun notarytool submit ${ZIPFILE} --keychain-profile ${PROFILENAME}  --wait
	rm ${ZIPFILE}

staple:
	xcrun stapler staple ${APP}

shipit:
	cp ${APP} ~/Desktop
	(cd ~/Pro/dev/devtools/InstallerStuff/${APPNAME};../../bin/shipit)


