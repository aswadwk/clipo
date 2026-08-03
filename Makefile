PROJECT     := Clipo.xcodeproj
SCHEME      := Clipo
CONFIG      := Debug
DEST        := platform=macOS,arch=arm64
BUILD_DIR   := build
APP         := $(BUILD_DIR)/Build/Products/$(CONFIG)/Clipo.app

RELEASE_APP := $(BUILD_DIR)/Build/Products/Release/Clipo.app
DMG         := $(BUILD_DIR)/Clipo.dmg
DMG_STAGE   := $(BUILD_DIR)/dmg

.PHONY: gen build run release dmg clean

## gen: regenerate the Xcode project from project.yml
gen:
	xcodegen generate

## build: compile the app into ./build
build: gen
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIG) -destination '$(DEST)' -derivedDataPath $(BUILD_DIR) build

## run: build then launch the app
run: build
	open "$(APP)"

## release: compile a Release build into ./build
release: gen
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -destination '$(DEST)' -derivedDataPath $(BUILD_DIR) build

## dmg: package the Release build into a distributable ./build/Clipo.dmg
dmg: release
	rm -rf "$(DMG_STAGE)" "$(DMG)"
	mkdir -p "$(DMG_STAGE)"
	cp -R "$(RELEASE_APP)" "$(DMG_STAGE)/"
	ln -s /Applications "$(DMG_STAGE)/Applications"
	hdiutil create -volname "Clipo" -srcfolder "$(DMG_STAGE)" -ov -format UDZO "$(DMG)"
	rm -rf "$(DMG_STAGE)"
	@echo "Created $(DMG)"

## clean: remove build artifacts
clean:
	rm -rf $(BUILD_DIR)
