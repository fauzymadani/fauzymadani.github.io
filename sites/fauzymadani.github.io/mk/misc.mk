PAGE := misc/notes
HTML_TARGETS := $(HTML_TARGETS) $(OUT_DIR)/$(PAGE).html

TITLE.$(PAGE) = notes
OS.$(PAGE) = fauzymadani.github.io
URL.$(PAGE) := /$(PAGE).html

$(OUT_DIR)/misc/notes.html: $(SRC_DIR)/mk/misc.mk
$(OUT_DIR)/misc/notes.raw.html: sites/fauzymadani.github.io/misc/notes.1
