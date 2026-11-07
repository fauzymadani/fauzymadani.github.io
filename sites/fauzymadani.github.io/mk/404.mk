PAGE := 404
HTML_TARGETS := $(HTML_TARGETS) $(OUT_DIR)/$(PAGE).html

TITLE.$(PAGE) = not found
OS.$(PAGE) = fauzymadani.github.io
URL.$(PAGE) := /$(PAGE).html

$(OUT_DIR)/404.html: $(SRC_DIR)/mk/404.mk
$(OUT_DIR)/404.raw.html: sites/fauzymadani.github.io/404.1
