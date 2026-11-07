PAGE := links
HTML_TARGETS := $(HTML_TARGETS) $(OUT_DIR)/$(PAGE).html

TITLE.$(PAGE) = links
OS.$(PAGE) = fauzymadani.github.io
URL.$(PAGE) := /$(PAGE).html

$(OUT_DIR)/links.html: $(SRC_DIR)/mk/links.mk
$(OUT_DIR)/links.raw.html: sites/fauzymadani.github.io/links.1
