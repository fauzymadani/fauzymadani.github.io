PAGE := index
HTML_TARGETS := $(HTML_TARGETS) $(OUT_DIR)/$(PAGE).html

TITLE.$(PAGE) = fauzymadani
OS.$(PAGE) = fauzymadani.github.io
URL.$(PAGE) := /$(PAGE).html

$(OUT_DIR)/index.html: $(SRC_DIR)/mk/index.mk
$(OUT_DIR)/index.raw.html: sites/fauzymadani.github.io/index.1
