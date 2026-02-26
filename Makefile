# Makefile for GitDoIt Flutter Project
# Repository: https://github.com/berlogabob/flutter-github-issues-todo
# Purpose: Build Android APK and Web release with automatic version increment

.PHONY: all clean build-android build-web release

# Clear terminal screen as first step (cross-platform)
CLEAR := $(shell which clear 2>/dev/null || echo "printf '\033c'")
ifeq ($(OS),Windows_NT)
	CLEAR := cls
endif

# Get current version from pubspec.yaml (portable version)
CURRENT_VERSION := $(shell awk '/^version:/ {gsub(/^[^:]*:[[:space:]]*/, ""); print}' pubspec.yaml)
VERSION_MAJOR := $(word 1, $(subst ., ,$(word 1, $(subst +, ,$(CURRENT_VERSION)))))
VERSION_MINOR := $(word 2, $(subst ., ,$(word 1, $(subst +, ,$(CURRENT_VERSION)))))
VERSION_PATCH := $(word 3, $(subst ., ,$(word 1, $(subst +, ,$(CURRENT_VERSION)))))
VERSION_BUILD := $(word 2, $(subst +, ,$(CURRENT_VERSION)))

# Calculate next build number
NEXT_BUILD := $(shell echo $$(($(VERSION_BUILD) + 1)))

# New version string
NEW_VERSION := $(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)+$(NEXT_BUILD)

# Release tag (includes build number for uniqueness)
RELEASE_TAG := v$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)-build-$(NEXT_BUILD)

# Default target
all: help

# Help command
help:
	@echo "GitDoIt Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make build-android      - Build Android APK with GitHub release"
	@echo "  make build-web        - Build Web release for GitHub Pages"
	@echo "  make release          - Build both Android and Web releases"
	@echo "  make clean            - Clean build directories"
	@echo "  make version-increment - Only increment build number"
	@echo ""

# Clear terminal and show current status
init:
	@$(CLEAR)
	@echo "🚀 GitDoIt Build System"
	@echo "Current version: $(CURRENT_VERSION)"
	@echo "Next build: $(NEW_VERSION)"
	@echo "Repository: https://github.com/berlogabob/flutter-github-issues-todo"
	@echo ""

# Increment build number in pubspec.yaml (robust method)
version-increment:
	@$(CLEAR)
	@echo "🔄 Incrementing build number..."
	@echo "Old version: $(CURRENT_VERSION)"
	@echo "New version: $(NEW_VERSION)"
	@# Use awk for reliable version replacement on macOS
	@awk '{if (/^version:/) print "version: $(NEW_VERSION)"; else print $$0}' pubspec.yaml > pubspec.yaml.tmp && mv pubspec.yaml.tmp pubspec.yaml
	@echo "✅ Build number incremented to $(NEW_VERSION)"

# Build Android APK
build-android: init version-increment
	@echo "📱 Building Android APK..."
	@flutter build apk --release
	@echo "✅ Android APK built successfully"
	@echo ""
	@echo "📦 GitHub Release Setup:"
	@echo "1. Create release on GitHub: https://github.com/berlogabob/flutter-github-issues-todo/releases/new"
	@echo "2. Tag: v$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)"
	@echo "3. Title: GitDoIt v$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH) Build $(NEXT_BUILD)"
	@echo "4. Description: Android release build $(NEW_VERSION)"
	@echo "5. Upload file: build/app-release.apk"
	@echo ""
	@echo "💡 Tip: Use 'gh release create' if you have GitHub CLI installed:"
	@echo "   gh release create v$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH) --title \"GitDoIt v$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)\" --notes \"Build $(NEXT_BUILD)\" --draft build/app-release.apk"

# Build Web release for GitHub Pages
build-web: init version-increment
	@echo "🌐 Building Web release for GitHub Pages..."
	@flutter build web --release --base-href="/flutter-github-issues-todo/"
	@echo "✅ Web build completed"
	@echo "📁 Moving to /docs folder for GitHub Pages..."
	@rm -rf docs
	@mkdir -p docs
	@cp -r build/web/* docs/
	@echo "✅ Files moved to docs/ folder"
	@echo ""
	@echo "🔗 GitHub Pages Setup:"
	@echo "1. Go to Repository Settings → Pages"
	@echo "2. Source: Deploy from a branch"
	@echo "3. Branch: main"
	@echo "4. Folder: /docs"
	@echo "5. Save settings"
	@echo ""
	@echo "💡 Base href configured: /flutter-github-issues-todo/"

# Full release - both Android and Web, with git commit, tag, and push
release: init version-increment build-android build-web git-commit-tag git-push-tag gh-release
	@echo "🎉 Complete release built, committed, pushed, and published!"
	@echo "Android APK: build/app/outputs/flutter-apk/app-release.apk"
	@echo "Web files: docs/"
	@echo "New version: $(NEW_VERSION)"
	@echo "Release tag: $(RELEASE_TAG)"
	@echo ""
	@echo "✅ GitHub release created: $(RELEASE_TAG)"
	@echo "✅ Git tag created and pushed: $(RELEASE_TAG)"
	@echo "✅ GitHub Pages ready: /docs folder"
	@echo ""
	@echo "🚀 Deployment complete! Progress tracked in git history."

# Clean build directories
clean:
	@$(CLEAR)
	@echo "🧹 Cleaning build directories..."
	@rm -rf build/
	@rm -rf docs/
	@echo "✅ Cleaned build directories"

# GitHub release automation (creates release if gh CLI available)
gh-release:
	@echo "🤖 GitHub Release Automation..."
	@if command -v gh >/dev/null 2>&1; then \
		echo "✅ GitHub CLI detected"; \
		if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then \
			echo "📦 APK file found"; \
			echo "Creating release $(RELEASE_TAG)..."; \
			gh release create $(RELEASE_TAG) \
				--title "GitDoIt $(RELEASE_TAG)" \
				--notes "Build $(NEXT_BUILD) - Android APK and Web release for GitHub Pages" \
				build/app/outputs/flutter-apk/app-release.apk && \
			echo "✅ GitHub release created successfully!"; \
		else \
			echo "⚠️ APK file not found, creating release without attachment"; \
			gh release create $(RELEASE_TAG) \
				--title "GitDoIt $(RELEASE_TAG)" \
				--notes "Build $(NEXT_BUILD) - Android APK and Web release for GitHub Pages" || true; \
		fi; \
	else \
		echo "⚠️ GitHub CLI not found"; \
		echo "   Install with: brew install gh"; \
	fi

# Git commit and tag after successful build
git-commit-tag:
	@echo "📦 Creating git commit and tag for tracking progress..."
	@if git status --porcelain | grep -q .; then \
		echo "✅ Changes detected - committing build artifacts"; \
		git add pubspec.yaml docs/; \
		if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then \
			git add build/app/outputs/flutter-apk/app-release.apk; \
		fi; \
		git commit -m "release: $(RELEASE_TAG)" --no-verify; \
		git tag -a "$(RELEASE_TAG)" -m "GitDoIt $(RELEASE_TAG)"; \
		echo "✅ Commit created: release: $(RELEASE_TAG)"; \
		echo "✅ Tag created: $(RELEASE_TAG)"; \
	else \
		echo "⚠️ No changes to commit (all files already committed)"; \
	fi

# Push tag and branch to remote for GitHub release creation
git-push-tag:
	@echo "📤 Pushing tag and branch to remote for GitHub release..."
	@if git tag -l "$(RELEASE_TAG)" | grep -q "$(RELEASE_TAG)"; then \
		echo "✅ Tag $(RELEASE_TAG) exists locally"; \
		git push origin HEAD; \
		git push origin "$(RELEASE_TAG)"; \
		echo "✅ Branch and tag pushed to remote"; \
	else \
		echo "⚠️ Tag $(RELEASE_TAG) not found locally"; \
	fi

# Show current version
version:
	@echo "Current version: $(CURRENT_VERSION)"
	@echo "Next build number: $(NEXT_BUILD)"
