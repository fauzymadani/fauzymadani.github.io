SHELL = /bin/sh

SITE ?= fauzymadani.github.io
PORT ?= 8000
SRC_DIR = sites/$(SITE)
OUT_DIR = out/$(SITE)

all: build

include $(SRC_DIR)/manifest.mk

SITE_TITLE ?= $(SITE)
SITE_SUBTITLE ?=

RAW_HTML_TARGETS = $(HTML_TARGETS:.html=.raw.html)
BODY_HTML_TARGETS = $(HTML_TARGETS:.html=.body.html)
# the sidebar tree is generated from the per-page metadata, so it must be
# rebuilt whenever pages are added/renamed/retitled
PAGE_MK = $(wildcard $(SRC_DIR)/mk/*.mk)
HELPER = ./bin/helper

.PHONY: all build serve clean dirs

build: dirs $(HTML_TARGETS) $(STATIC_TARGETS) $(OUT_DIR)/mandoc.css $(OUT_DIR)/pub/style.css
	@echo "mite: built $(SRC_DIR) -> $(OUT_DIR)"

dirs:
	@mkdir -p $(DIRS)

$(OUT_DIR)/%.raw.html: $(HELPER)
	@mkdir -p "$(dir $@)"
	$(HELPER) raw "$(SRC_DIR)" "$*" "$@"

$(OUT_DIR)/%.body.html: $(OUT_DIR)/%.raw.html $(HELPER)
	@mkdir -p "$(dir $@)"
	$(HELPER) body "$<" "$@"

$(OUT_DIR)/sidebar.html: $(SRC_DIR)/manifest.mk $(PAGE_MK) $(HELPER)
	@mkdir -p "$(dir $@)"
	$(HELPER) sidebar "$@" "$(SRC_DIR)"

$(OUT_DIR)/%.html: $(OUT_DIR)/%.body.html $(OUT_DIR)/sidebar.html $(OUT_DIR)/mandoc.css $(OUT_DIR)/pub/style.css $(HELPER)
	@mkdir -p "$(dir $@)"
	$(HELPER) page "$@" "$*" "$(TITLE.$*)" "$(OS.$*)" "$(URL.$*)" "" "$(OUT_DIR)" "$(SITE_TITLE)" "$(SITE_SUBTITLE)" "$(URL.index)" "$(SRC_DIR)"

$(STATIC_TARGETS):
	@mkdir -p "$(dir $@)"
	cp "$(SRC_DIR)/$(@:$(OUT_DIR)/%=%)" "$@"

$(OUT_DIR)/pub/style.css: pub/style.css
	@mkdir -p "$(dir $@)"
	@cat "$<" > "$@"
	@if [ -f "$(SRC_DIR)/_mite/style.css" ]; then printf '\n' >> "$@"; cat "$(SRC_DIR)/_mite/style.css" >> "$@"; fi

$(OUT_DIR)/mandoc.css: pub/mandoc.css
	@mkdir -p "$(dir $@)"
	@if [ -f "$(SRC_DIR)/_mite/mandoc.css" ]; then cp "$(SRC_DIR)/_mite/mandoc.css" "$@"; else cp pub/mandoc.css "$@"; fi

serve: build
	$(HELPER) serve "$(OUT_DIR)" "$(PORT)"

clean:
	rm -rf "$(OUT_DIR)"
