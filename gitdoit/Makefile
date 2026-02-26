# Wrapper Makefile - delegates to project root Makefile
# Usage: make <target> from anywhere in gitdoit/

# Search for project root
PROJECT_ROOT := $(shell d="$(CURDIR)"; while [ "$$d" != "/" ]; do [ -f "$$d/Makefile" ] && { echo "$$d"; break; }; d="$$(dirname "$$d")"; done; [ -z "$(PROJECT_ROOT)" ] && d="$$d" && [ -f "$$d/Makefile" ] && echo "$$d")

# Make all targets phony and pass through
.PHONY: $(shell cd $(PROJECT_ROOT) 2>/dev/null && make -qp | grep -E '^[a-zA-Z0-9][^ ]*:' | cut -d: -f1 | grep -v '^\.')

# Catch-all rule
$(shell cd $(PROJECT_ROOT) 2>/dev/null && make -qp | grep -E '^[a-zA-Z0-9][^ ]*:' | cut -d: -f1 | grep -v '^\.'):
	@$(MAKE) -C $(PROJECT_ROOT) $@
