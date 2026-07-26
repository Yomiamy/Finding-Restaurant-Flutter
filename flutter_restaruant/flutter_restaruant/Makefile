.PHONY: get gen clean assets help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  get          Get dependencies"
	@echo "  gen          Run build_runner build"
	@echo "  watch        Run build_runner watch"
	@echo "  assets       Generate assets and intl"
	@echo "  clean        Clean build artifacts"

get:
	flutter pub get

gen:
	dart run build_runner build --delete-conflicting-outputs

watch:
	dart run build_runner watch --delete-conflicting-outputs

assets:
	dart run flutter_gen
	dart run intl_utils:generate

## Generate intl
intl:
	@dart run intl_utils:generate

## Clean the environment.
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

## Get pub packages.
get: 
	@flutter pub get
	@flutter precache --ios
	@cd ios && pod install

## Run app.
run_debug_all:
	@flutter run --debug -d all

run_profile_all:
	@flutter run --profile -d all

run_prod_all:
	@flutter run --release -d all

# run_dev_debug:
# 	@flutter run --debug --flavor dev --target ./lib/main.dart || (echo "Error in running dev."; exit 99)
#
# run_dev_profile:
# 	@flutter run --profile --flavor dev --target ./lib/main.dart || (echo "Error in running dev."; exit 99)
#
# run_dev_prod:
# 	@flutter run --release --flavor dev --target ./lib/main.dart || (echo "Error in running dev."; exit 99)

## Run build_runner and generate files automatically.
build_runner: 
	@dart run build_runner build -d

## Run build_runner and generate files automatically.
build_watch: 
	@dart run build_runner watch -d

build_clean: 
	@dart run build_runner clean

## Analyze the code and find issues.
analyze_lint: 
	@dart analyze . || (echo "Error in analyzing, some code need to optimize."; exit 99)

## Analyze the code by custom_lint
analyze_custom:
	@dart run custom_lint

## Format the code.
format: 
	@dart format .

## Fix the code.
fix: 
	@dart fix --dry-run
	@dart fix --apply

## Generate new app icon images.
launcher_icon: 
	@dart run flutter_launcher_icons:main -f flutter_launcher_icons*

# Mason Tool
mason_feature:
	@mason make clean_architecture_feature_riverpod

## fluttergen for asset gen
fluttergen:
	@fluttergen -c pubspec.yaml
