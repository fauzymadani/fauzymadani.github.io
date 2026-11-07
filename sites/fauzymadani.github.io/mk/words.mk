PAGE := words/uniline
HTML_TARGETS := $(HTML_TARGETS) $(OUT_DIR)/$(PAGE).html
TITLE.$(PAGE) = uniline
OS.$(PAGE) = fauzymadani.github.io
URL.$(PAGE) := /$(PAGE).html

$(OUT_DIR)/words/uniline.html: $(SRC_DIR)/mk/words.mk
$(OUT_DIR)/words/uniline.raw.html: sites/fauzymadani.github.io/words/uniline.1

PAGE := words/gwx
HTML_TARGETS := $(HTML_TARGETS) $(OUT_DIR)/$(PAGE).html
TITLE.$(PAGE) = gwx
OS.$(PAGE) = fauzymadani.github.io
URL.$(PAGE) := /$(PAGE).html

$(OUT_DIR)/words/gwx.html: $(SRC_DIR)/mk/words.mk
$(OUT_DIR)/words/gwx.raw.html: sites/fauzymadani.github.io/words/gwx.1

PAGE := words/zotero
HTML_TARGETS := $(HTML_TARGETS) $(OUT_DIR)/$(PAGE).html
TITLE.$(PAGE) = zotero
OS.$(PAGE) = fauzymadani.github.io
URL.$(PAGE) := /$(PAGE).html

$(OUT_DIR)/words/zotero.html: $(SRC_DIR)/mk/words.mk
$(OUT_DIR)/words/zotero.raw.html: sites/fauzymadani.github.io/words/zotero.1
