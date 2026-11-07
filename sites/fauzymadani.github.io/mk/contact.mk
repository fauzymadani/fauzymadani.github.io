PAGE := contact
HTML_TARGETS := $(HTML_TARGETS) $(OUT_DIR)/$(PAGE).html

TITLE.$(PAGE) = contact
OS.$(PAGE) = fauzymadani.github.io
URL.$(PAGE) := /$(PAGE).html

$(OUT_DIR)/contact.html: $(SRC_DIR)/mk/contact.mk
$(OUT_DIR)/contact.raw.html: sites/fauzymadani.github.io/contact.1
