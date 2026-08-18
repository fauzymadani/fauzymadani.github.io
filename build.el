;;; build.el --- ponytail:ox-publish build script -*- lexical-binding: t; -*-
(require 'ox-publish)

(defvar my-site-title "Fauzy's Blog")

(defvar my-nav-links
  '(("Home"     . "index.html")
    ("Archive"  . "archive.html")
    ("Projects" . "projects.html")))

(defun my-render-nav ()
  "Generate HTML navigation markup from `my-nav-links`."
  (concat
   (format "<nav class=\"site-nav\"><a href=\"index.html\" class=\"nav-title\">%s</a>" my-site-title)
   (mapconcat (lambda (link)
                (format "<a href=\"%s\">%s</a>" (cdr link) (car link)))
              my-nav-links
              "")
   "</nav>"))

(setq org-publish-project-alist
      `(("blog-content"
         :base-directory "./content"
         :base-extension "org"
         :publishing-directory "./public"
         :recursive t
         :publishing-function org-html-publish-to-html
         :headline-levels 4
         :auto-sitemap t
         :sitemap-filename "archive.org"
         :sitemap-title "Archive"
         :with-author t
         :with-creator nil
         :with-toc nil
         :section-numbers nil
         :time-stamp-file nil
         :html-head-include-default-style nil
         :html-head-include-scripts nil
         :html-head "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\"/>"
         :html-preamble ,(my-render-nav)
         :html-postamble "<div class=\"footer-content\"><p>© %a · Written in Org-mode</p><a href=\"https://notbyai.fyi\" target=\"_blank\" rel=\"noopener\"><img src=\"images/not-by-ai.svg\" alt=\"Written by a Human, Not by AI\" class=\"not-by-ai-badge\" /></a></div>")
        ("blog-static"
         :base-directory "./content"
         :base-extension "css\\|js\\|png\\|jpg\\|gif\\|svg\\|pdf\\|woff2\\|woff\\|ttf"
         :publishing-directory "./public"
         :recursive t
         :publishing-function org-publish-attachment)
        ("blog" :components ("blog-content" "blog-static"))))

(org-publish "blog" t)
