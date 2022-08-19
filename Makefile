VERSION = 1.5
PRODUCT = NetworkWatcher

BINARY = NetworkWatcher
SWIFT_OUT = .build/apple/Products/Release/${PRODUCT}

CODESIGN_IDENTITY = "Developer ID Application: University of Michigan (D9GZK3CLYY)"
BUNDLE_ID = edu.umich.its.${PRODUCT}
NOTARYTOOL_PROFILE = umich-edu

Binaries/${BINARY}:
	-swift build -c release --product ${PRODUCT}  --arch arm64 --arch x86_64
	xcrun codesign -s ${CODESIGN_IDENTITY} \
               --options=runtime \
               --timestamp \
               ${SWIFT_OUT}
	rm -rf out || true
	mkdir -p Binaries
	cp ${SWIFT_OUT} Binaries/${BINARY}

.PHONY: build
build: Binaries/${BINARY}

.PHONY: dmg
dmg: ${BINARY}.dmg

${BINARY}.dmg:
	hdiutil create -volname "${PRODUCT}" -srcfolder "Binaries" -ov -format UDZO "${BINARY}.dmg"
	xcrun notarytool \
		submit \
		--wait \
		--keychain-profile ${NOTARYTOOL_PROFILE} \
		"${BINARY}.dmg"
	xcrun stapler staple "${BINARY}.dmg"

.PHONY: clean
clean:
	rm -rf Packages Binaries .build ${BINARY}.dmg
