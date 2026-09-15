.PHONY: help get pod clean gen watch build_runner build_watch build_clean assets intl fluttergen launcher_icon format fix analyze analyze_lint test test_coverage run_debug_all run_profile_all run_prod_all

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Dependencies & Environment:"
	@echo "  get             Get Flutter packages"
	@echo "  pod             Install CocoaPods dependencies"
	@echo "  clean           Clean build artifacts, lock files, and caches"
	@echo ""
	@echo "Code Generation & Assets:"
	@echo "  gen             Run build_runner build"
	@echo "  watch           Run build_runner watch"
	@echo "  build_clean     Clean build_runner cache"
	@echo "  assets          Generate assets (flutter_gen) and intl"
	@echo "  intl            Generate localization files"
	@echo "  fluttergen      Generate asset references"
	@echo "  launcher_icon   Generate app icons"
	@echo ""
	@echo "Code Quality & Testing:"
	@echo "  format          Format Dart code"
	@echo "  fix             Apply automated dart fixes"
	@echo "  analyze         Analyze code with dart analyze"
	@echo "  test            Run unit and widget tests"
	@echo "  test_coverage   Run tests and generate coverage report"
	@echo ""
	@echo "Run App:"
	@echo "  run_debug_all   Run debug mode on all devices"
	@echo "  run_profile_all Run profile mode on all devices"
	@echo "  run_prod_all    Run release mode on all devices"

## =============================================================================
## Dependencies & Environment
## =============================================================================

get:
	@flutter pub get

pod:
	@cd ios && pod install

clean:
	@echo "⚡︎Cleaning the project..."
	@rm -rf pubspec.lock
	@rm -rf ios/Podfile.lock
	@rm -rf ios/Pods
	@rm -rf ios/.symlinks
	@rm -rf ios/Flutter/Flutter.framework
	@rm -rf ios/Flutter/Flutter.podspec
	@rm -rf ~/.pub-cache
	@flutter clean
	@echo "⚡︎Project clean successfully!"

## =============================================================================
## Code Generation & Assets
## =============================================================================

gen:
	@dart run build_runner build --delete-conflicting-outputs

watch:
	@dart run build_runner watch --delete-conflicting-outputs

# Aliases for backward compatibility
build_runner: gen
build_watch: watch

build_clean:
	@dart run build_runner clean

assets:
	@dart run flutter_gen
	@dart run intl_utils:generate

intl:
	@dart run intl_utils:generate

fluttergen:
	@fluttergen -c pubspec.yaml

launcher_icon:
	@dart run flutter_launcher_icons:main -f flutter_launcher_icons*

## =============================================================================
## Code Quality & Testing
## =============================================================================

format:
	@dart format .

fix:
	@dart fix --dry-run
	@dart fix --apply

analyze: analyze_lint

analyze_lint:
	@flutter analyze . || (echo "Error in analyzing, some code need to optimize."; exit 99)

test:
	@flutter test

test_coverage:
	@flutter test --coverage
	@if command -v lcov >/dev/null 2>&1; then lcov --summary coverage/lcov.info; else echo "Coverage report generated at coverage/lcov.info"; fi

## =============================================================================
## Run App
## =============================================================================

run_debug_all:
	@flutter run --debug -d all

run_profile_all:
	@flutter run --profile -d all

run_prod_all:
	@flutter run --release -d all
