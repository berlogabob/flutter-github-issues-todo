# Makefile for GitDoIt Flutter Project
# Repository: https://github.com/berlogabob/flutter-github-issues-todo

.PHONY: all help init version-increment validate-env run-with-env \
	build-android build-web release-artifacts tag-release push-release \
	gh-release release clean version generate

CURRENT_VERSION := $(shell awk '/^version:/ {gsub(/^[^:]*:[[:space:]]*/, ""); print}' pubspec.yaml)
RELEASE_VERSION := $(word 1, $(subst +, ,$(CURRENT_VERSION)))
VERSION_MAJOR := $(word 1, $(subst ., ,$(RELEASE_VERSION)))
VERSION_MINOR := $(word 2, $(subst ., ,$(RELEASE_VERSION)))
VERSION_PATCH := $(word 3, $(subst ., ,$(RELEASE_VERSION)))
VERSION_BUILD := $(word 2, $(subst +, ,$(CURRENT_VERSION)))
NEXT_BUILD := $(shell echo $$(($(VERSION_BUILD) + 1)))
NEW_VERSION := $(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)+$(NEXT_BUILD)

RELEASE_TAG ?= v$(RELEASE_VERSION)
BASE_HREF ?= /flutter-github-issues-todo/
RELEASE_NOTES ?= RELEASE_NOTES_v1.0.0.md

all: help

help:
	@echo "GitDoIt Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make build-android      Build release APK and app bundle"
	@echo "  make build-web          Build Web release and copy it to docs/"
	@echo "  make release-artifacts  Build Android and Web artifacts"
	@echo "  make tag-release        Create annotated RELEASE_TAG on current commit"
	@echo "  make push-release       Push current branch and RELEASE_TAG"
	@echo "  make gh-release         Create GitHub Release for RELEASE_TAG"
	@echo "  make release            Build artifacts and create GitHub Release"
	@echo "  make version-increment  Increment pubspec.yaml build number only"
	@echo "  make clean              Remove generated build/ output"
	@echo "  make run-with-env       Run app with variables from .env"
	@echo ""
	@echo "Current version: $(CURRENT_VERSION)"
	@echo "Release tag: $(RELEASE_TAG)"

init:
	@echo "GitDoIt Build System"
	@echo "Current version: $(CURRENT_VERSION)"
	@echo "Next build: $(NEW_VERSION)"
	@echo "Release tag: $(RELEASE_TAG)"
	@echo "Repository: https://github.com/berlogabob/flutter-github-issues-todo"
	@echo ""

version-increment:
	@echo "Incrementing build number..."
	@echo "Old version: $(CURRENT_VERSION)"
	@echo "New version: $(NEW_VERSION)"
	@awk '{if (/^version:/) print "version: $(NEW_VERSION)"; else print $$0}' pubspec.yaml > pubspec.yaml.tmp && mv pubspec.yaml.tmp pubspec.yaml
	@echo "Build number incremented to $(NEW_VERSION)"

validate-env:
	@echo "Validating environment configuration..."
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found."; \
		echo "Copy .env.example to .env and fill in GITHUB_CLIENT_ID."; \
		exit 1; \
	fi
	@if ! grep -q "^GITHUB_CLIENT_ID=" .env; then \
		echo "Error: GITHUB_CLIENT_ID is not set in .env."; \
		exit 1; \
	fi
	@if grep -q "GITHUB_CLIENT_ID=your_client_id_here" .env; then \
		echo "Error: GITHUB_CLIENT_ID still has the placeholder value."; \
		exit 1; \
	fi
	@echo "Environment validation passed"

run-with-env: validate-env
	@echo "Running app with environment variables..."
	@export GITHUB_CLIENT_ID=$$(grep "^GITHUB_CLIENT_ID=" .env | cut -d'=' -f2) && \
		echo "Client ID: $${GITHUB_CLIENT_ID:0:8}..." && \
		flutter run --dart-define=GITHUB_CLIENT_ID=$${GITHUB_CLIENT_ID}

build-android: init
	@echo "Building Android release artifacts..."
	@flutter pub get
	@flutter build apk --release
	@flutter build appbundle --release
	@echo "Android APK: build/app/outputs/flutter-apk/app-release.apk"
	@echo "Android app bundle: build/app/outputs/bundle/release/app-release.aab"

build-web: init
	@echo "Building Web release for GitHub Pages..."
	@flutter pub get
	@flutter build web --release --base-href="$(BASE_HREF)"
	@rm -rf docs
	@mkdir -p docs
	@cp -r build/web/* docs/
	@echo "Web release copied to docs/"

release-artifacts: build-android build-web
	@echo "Release artifacts built for $(RELEASE_TAG)"

tag-release:
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "Error: working tree must be clean before tagging."; \
		exit 1; \
	fi
	@if git rev-parse "$(RELEASE_TAG)" >/dev/null 2>&1; then \
		echo "Error: tag $(RELEASE_TAG) already exists."; \
		exit 1; \
	fi
	@git tag -a "$(RELEASE_TAG)" -m "GitDoIt $(RELEASE_TAG)"
	@echo "Created annotated tag $(RELEASE_TAG)"

push-release:
	@if ! git rev-parse "$(RELEASE_TAG)" >/dev/null 2>&1; then \
		echo "Error: tag $(RELEASE_TAG) does not exist."; \
		exit 1; \
	fi
	@git push origin HEAD
	@git push origin "$(RELEASE_TAG)"
	@echo "Pushed current branch and $(RELEASE_TAG)"

gh-release:
	@if ! command -v gh >/dev/null 2>&1; then \
		echo "Error: GitHub CLI is required for gh-release."; \
		exit 1; \
	fi
	@if ! git rev-parse "$(RELEASE_TAG)" >/dev/null 2>&1; then \
		echo "Error: tag $(RELEASE_TAG) does not exist."; \
		exit 1; \
	fi
	@if [ ! -f build/app/outputs/flutter-apk/app-release.apk ]; then \
		echo "Error: release APK is missing. Run make build-android first."; \
		exit 1; \
	fi
	@if [ ! -f build/app/outputs/bundle/release/app-release.aab ]; then \
		echo "Error: release app bundle is missing. Run make build-android first."; \
		exit 1; \
	fi
	@gh release create "$(RELEASE_TAG)" \
		--title "GitDoIt $(RELEASE_TAG)" \
		--notes-file "$(RELEASE_NOTES)" \
		build/app/outputs/flutter-apk/app-release.apk \
		build/app/outputs/bundle/release/app-release.aab
	@echo "Created GitHub Release $(RELEASE_TAG)"

release: release-artifacts gh-release
	@echo "Release complete for $(RELEASE_TAG)"

clean:
	@echo "Cleaning generated build output..."
	@rm -rf build/
	@echo "Cleaned build/"

version:
	@echo "Current version: $(CURRENT_VERSION)"
	@echo "Next build number: $(NEXT_BUILD)"
	@echo "Release tag: $(RELEASE_TAG)"

generate:
	@echo "Running build_runner..."
	@dart run build_runner build --delete-conflicting-outputs
	@echo "Code generation complete"
