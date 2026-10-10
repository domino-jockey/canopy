# Shortcuts for building, testing and installing Canopy. Run `make` to see the list.
# How it all works, in plain language: docs/HOW-TO-BUILD.md

SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c
.DEFAULT_GOAL := help

XCODEBUILD := xcodebuild -project Canopy.xcodeproj -scheme Canopy -destination "platform=macOS,arch=$(shell uname -m)"
DEBUG_APP := build/Build/Products/Debug/Canopy.app
RELEASE_APP := build/release/Build/Products/Release/Canopy.app

.PHONY: help project build run test install stop xcode clean icon

help: ## Show this list
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  make %-9s %s\n", $$1, $$2}'

project: ## Recreate Canopy.xcodeproj from project.yml (the other commands do this for you)
	@xcodegen --quiet

build: project ## Build the test (Debug) copy into build/
	@$(XCODEBUILD) -quiet -derivedDataPath build build
	@echo "Built $(DEBUG_APP)"

run: build stop ## Build the Debug copy and open it (replaces the running Canopy)
	@open $(DEBUG_APP)

test: project ## Build and run all tests (full log in build/test.log)
	@mkdir -p build
	@$(XCODEBUILD) -derivedDataPath build test 2>&1 | tee build/test.log | grep -v com.apple.linkd | grep -E '✘|error:|Test run with|TEST (SUCCEEDED|FAILED)'

install: project ## Build the Release copy, put it in /Applications and open it
	@$(XCODEBUILD) -quiet -configuration Release -derivedDataPath build/release build
	@$(MAKE) --no-print-directory stop
	@ditto $(RELEASE_APP) /Applications/Canopy.app
	@open /Applications/Canopy.app
	@echo "Installed /Applications/Canopy.app"

stop: ## Quit Canopy if it's running
	@pkill -x Canopy && sleep 1 || true

xcode: project ## Open the project in Xcode
	@open Canopy.xcodeproj

icon: ## Redraw the app icon and menu bar leaf (design/make-icon.swift)
	@swift design/make-icon.swift

clean: ## Delete build output and the generated Xcode project (frees ~500 MB)
	@rm -rf build Canopy.xcodeproj
	@echo "Removed build/ and Canopy.xcodeproj"
