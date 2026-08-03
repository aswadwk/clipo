PROJECT   := Clipo.xcodeproj
SCHEME    := Clipo
CONFIG    := Debug
DEST      := platform=macOS,arch=arm64
BUILD_DIR := build
APP       := $(BUILD_DIR)/Build/Products/$(CONFIG)/Clipo.app

.PHONY: gen build run clean

## gen: regenerate the Xcode project from project.yml
gen:
	xcodegen generate

## build: compile the app into ./build
build: gen
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIG) -destination '$(DEST)' -derivedDataPath $(BUILD_DIR) build

## run: build then launch the app
run: build
	open "$(APP)"

## clean: remove build artifacts
clean:
	rm -rf $(BUILD_DIR)
