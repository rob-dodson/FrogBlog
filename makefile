#
# makefile for FrogBlog
#
# To build for non app store: make app;make notarize; make notarizewatch RequestUUID=XXX ; make staple; make shipit
#
# To build for Mac App Store: make app; make upload # NOT TESTED YET!
#
# To build the app:
#    make SCHEME=FrogBlog
#    make SCHEME=FrogBlogAppStore
#    make SCHEME=FrogBlogiPhone
#
ARCHIVE = ~/Desktop/FrogBlog.xcarchive
WORKSPACE = FrogBlog.xcworkspace
SCHEME = FrogBlog
USER = rad@robdodson.net
ZIPFILE = ${SCHEME}.zip
OSX_APP_BUNDLE_ID = Shy-Frog.FrogBlog
ALTOOL_ONETIME_PASS = jkdn-cjob-evtk-uuey
APP = ~/Desktop/FrogBlog.app
KEYCHAINPASS = ALTOOLPASS
SDK = macosx10.15
RequestUUID = # get from successful notarize output or notarizehistory


all:
	xcodebuild -workspace ${WORKSPACE} -scheme ${SCHEME} -configuration release

clean:
	xcodebuild -workspace ${WORKSPACE} -scheme ${SCHEME} clean

archive:
	xcodebuild -workspace ${WORKSPACE} -scheme ${SCHEME} clean archive -configuration release -sdk ${SDK} -archivePath ${ARCHIVE} 

app: archive
	xcodebuild -exportArchive -archivePath ${ARCHIVE} -exportPath ~/Desktop -exportOptionsPlist ExportOptions.plist 

upload: archive
	xcrun altool --upload-app --type osx --file ${ARCHIVE} --username ${USER} 

notarize: 
	/usr/bin/ditto -c -k --keepParent ${APP} ${ZIPFILE}
	xcrun altool --store-password-in-keychain-item ${KEYCHAINPASS} --username ${USER} --password ${ALTOOL_ONETIME_PASS}
	xcrun altool --notarize-app -f ${ZIPFILE} --primary-bundle-id ${OSX_APP_BUNDLE_ID} --username ${USER} --password @keychain:${KEYCHAINPASS}
	rm ${ZIPFILE}

notarizewatch:
	xcrun altool --notarization-info ${RequestUUID} --username ${USER} --password @keychain:${KEYCHAINPASS}

notarizehistory:
	xcrun altool --notarization-history 0 --username rad@robdodson.net --password @keychain:${KEYCHAINPASS}

staple:
	xcrun stapler staple ${APP}

shipit:
	(cd ~/Pro/dev/InstallerStuff/FrogBlog;~/bin/shipit)

