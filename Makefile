SHELL := /bin/bash

.PHONY: help doctor open build test xcode-build release clean

help:
	@echo "SubMergePro commands"
	@echo ""
	@echo "  make doctor       Check local development tools"
	@echo "  make open         Open the Xcode project"
	@echo "  make build        Build with Swift Package Manager"
	@echo "  make test         Run Swift tests"
	@echo "  make xcode-build  Build the Xcode macOS app"
	@echo "  make release      Build zip and dmg release artifacts"
	@echo "  make clean        Remove local build outputs"

doctor:
	@scripts/doctor.sh

open:
	@open SubMergeProMac.xcodeproj

build:
	@swift build

test:
	@swift test

xcode-build:
	@xcodebuild \
		-project SubMergeProMac.xcodeproj \
		-scheme SubMergeProMac \
		-configuration Debug \
		-destination 'platform=macOS' \
		-derivedDataPath build/DerivedData \
		CODE_SIGNING_ALLOWED=NO \
		build

release:
	@scripts/build_release.sh

clean:
	@rm -rf .build build dist
