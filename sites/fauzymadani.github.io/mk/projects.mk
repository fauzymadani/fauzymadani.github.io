PAGE := projects/kronos
HTML_TARGETS := $(HTML_TARGETS) $(OUT_DIR)/$(PAGE).html

TITLE.$(PAGE) = kronos
OS.$(PAGE) = fauzymadani.github.io
URL.$(PAGE) := /$(PAGE).html

$(OUT_DIR)/projects/kronos.html: $(SRC_DIR)/mk/projects.mk
$(OUT_DIR)/projects/kronos.raw.html: sites/fauzymadani.github.io/projects/kronos.1
