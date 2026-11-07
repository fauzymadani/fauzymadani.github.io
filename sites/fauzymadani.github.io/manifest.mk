SITE_TITLE = fauzymadani
SITE_SUBTITLE = backend & cloud engineering

DIRS = \
	$(OUT_DIR) \
	$(OUT_DIR)/misc \
	$(OUT_DIR)/words

HTML_TARGETS =
# no static assets (the favicon was dropped)
STATIC_TARGETS :=

include sites/fauzymadani.github.io/mk/*.mk
