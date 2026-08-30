#!/bin/bash
set -e

emacs --batch -Q -l build.el

if [ -f "public/index.html" ]; then
  xdg-open "file://$PWD/public/index.html" >/dev/null 2>&1 || true
fi
