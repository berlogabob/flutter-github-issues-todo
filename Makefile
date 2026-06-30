# Makefile for GitDoIt Flutter Project
# Repository: https://github.com/berlogabob/flutter-github-issues-todo

.PHONY: all help init version-increment validate-env run-with-env \
	build-android build-web release-artifacts tag-release push-release \
	gh-release release clean version

CURRENT_VERSION := $(shell awk '/^version:/ {gsub(/^[^:]*:[[:space:]]*/, ""); print}' pubspec.yaml)
RELEASE_VERSION := $(word 1, $(subst +, ,$(CURRENT_VERSION)))
VERSION_MAJOR := $(word 1, $(subst ., ,$(RELEASE_VERSION)))
VERSION_MINOR := $(word 2, $(subst ., ,$(RELEASE_VERSION)))
VERSION_PATCH := $(word 3, $(subst ., ,$(RELEASE_VERSION)))
VERSION_BUILD := $(word 2, $(subst +, ,$(CURRENT_VERSION)))
NEXT_BUILD := $(shell echo $$(($(VERSION_BUILD) + 1)))
NEW_VERSION := $(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)+$(NEXT_BUILD)

RELEASE_TAG ?= v$(RELEASE_VERSION)-build-$(NEXT_BUILD)
BASE_HREF ?= /flutter-github-issues-todo/
RELEASE_NOTES ?= RELEASE_NOTES_v1.0.0.md

all: help

help:
	@echo "GitDoIt Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make build-android      Build release APK and app bundle"
	@echo "  make build-web          Build Web release under build/web/"
	@echo "  make release-artifacts  Build Android and Web artifacts"
	@echo "  make tag-release        Create annotated RELEASE_TAG on current commit"
	@echo "  make push-release       Push current branch and RELEASE_TAG"
	@echo "  make gh-release         Create GitHub Release for RELEASE_TAG"
	@echo "  make release            Increment, build, tag, push, and publish"
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
		flutter run --dart-define=GITHUB_CLIENT_ID=$${GITHUB_CLIENT_ID}

build-android: init validate-env
	@echo "Building Android release artifacts..."
	@flutter pub get
	@GITHUB_CLIENT_ID=$$(grep "^GITHUB_CLIENT_ID=" .env | cut -d'=' -f2-) && \
		flutter build apk --release --dart-define=GITHUB_CLIENT_ID=$${GITHUB_CLIENT_ID} && \
		flutter build appbundle --release --dart-define=GITHUB_CLIENT_ID=$${GITHUB_CLIENT_ID}
	@echo "Android APK: build/app/outputs/flutter-apk/app-release.apk"
	@echo "Android app bundle: build/app/outputs/bundle/release/app-release.aab"

build-web: init validate-env
	@echo "Building Web release for GitHub Pages..."
	@flutter pub get
	@GITHUB_CLIENT_ID=$$(grep "^GITHUB_CLIENT_ID=" .env | cut -d'=' -f2-) && \
		flutter build web --release --base-href="$(BASE_HREF)" \
			--dart-define=GITHUB_CLIENT_ID=$${GITHUB_CLIENT_ID}
	@echo "Web release built under build/web/"

release-artifacts: build-android build-web
	@echo "Release artifacts built for $(RELEASE_TAG)"

tag-release:
	@if [ -n "$$(git status --porcelain --untracked-files=no)" ]; then \
		echo "Error: tracked changes remain before tagging."; \
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
		--verify-tag \
		--title "GitDoIt $(RELEASE_TAG)" \
		--notes-file "$(RELEASE_NOTES)" \
		build/app/outputs/flutter-apk/app-release.apk \
		build/app/outputs/bundle/release/app-release.aab
	@echo "Created GitHub Release $(RELEASE_TAG)"

release:
	@clear 2>/dev/null || true
	@echo "Preparing $(RELEASE_TAG) from $(CURRENT_VERSION)"
	@if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then \
		echo "Error: authenticate GitHub CLI with 'gh auth login'."; \
		exit 1; \
	fi
	@if [ ! -f "$(RELEASE_NOTES)" ]; then \
		echo "Error: release notes file $(RELEASE_NOTES) is missing."; \
		exit 1; \
	fi
	@if git ls-files --error-unmatch .env >/dev/null 2>&1; then \
		echo "Error: .env must not be tracked."; \
		exit 1; \
	fi
	@if git rev-parse "$(RELEASE_TAG)" >/dev/null 2>&1 || \
		git ls-remote --exit-code --tags origin "refs/tags/$(RELEASE_TAG)" >/dev/null 2>&1 || \
		gh release view "$(RELEASE_TAG)" >/dev/null 2>&1; then \
		echo "Error: tag or release $(RELEASE_TAG) already exists."; \
		exit 1; \
	fi
	@$(MAKE) validate-env
	@$(MAKE) version-increment
	@$(MAKE) release-artifacts RELEASE_TAG="$(RELEASE_TAG)"
	@git add -A -- .
	@git commit -m "release: $(RELEASE_TAG)"
	@$(MAKE) tag-release RELEASE_TAG="$(RELEASE_TAG)"
	@$(MAKE) push-release RELEASE_TAG="$(RELEASE_TAG)"
	@$(MAKE) gh-release RELEASE_TAG="$(RELEASE_TAG)"
	@echo "Release complete for $(RELEASE_TAG)"

clean:
	@echo "Cleaning generated build output..."
	@rm -rf build/
	@echo "Cleaned build/"

version:
	@echo "Current version: $(CURRENT_VERSION)"
	@echo "Next build number: $(NEXT_BUILD)"
	@echo "Release tag: $(RELEASE_TAG)"
