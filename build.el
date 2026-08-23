;;; build.el --- ox-publish build script -*- lexical-binding: t; -*-
(require 'ox-publish)
(defvar my-site-title "")
(defvar my-nav-links
  '(("Home"     . "index.html")
    ("Blog"     . "blog.html")
    ("Tags"     . "tags.html")
    ("Archive"  . "archive.html")
    ("Projects" . "projects.html")))
(defun my-render-nav ()
  "Generate HTML navigation markup from `my-nav-links` with an image logo."
  (concat
   "<nav class=\"site-nav\"><a href=\"index.html\" class=\"nav-title\"></a>"
   (mapconcat (lambda (link)
                (format "<a href=\"%s\">%s</a>" (cdr link) (car link)))
              my-nav-links
              "")
   "</nav>"))

;; --- post listing (homepage teaser, blog.html, archive.html) ---

(defvar my-recent-posts-count 4
  "Number of recent posts shown on the homepage teaser.")

(defvar my-post-exclude '("index" "archive" "projects" "blog" "404" "tags")
  "Org files that are not posts, skipped from every listing.")

(defun my-org-file-title (file)
  "Get the #+TITLE: value from org FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (if (re-search-forward "^#\\+TITLE:[ \t]*\\(.*\\)$" nil t)
        (string-trim (match-string 1))
      (file-name-base file))))

(defun my-org-file-flag (file keyword)
  "Get the #+KEYWORD: value from FILE, or nil if it's not set."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (when (re-search-forward (format "^#\\+%s:[ \t]*\\(.*\\)$" keyword) nil t)
      (string-trim (match-string 1)))))

(defun my-org-file-date (file)
  "Get #+DATE: from org FILE. Falls back to the file's modification time."
  (let ((v (my-org-file-flag file "DATE")))
    (if v
        (condition-case nil
            (date-to-time v)
          (error (file-attribute-modification-time (file-attributes file))))
      (file-attribute-modification-time (file-attributes file)))))

(defun my-post-archived-p (file)
  "Non-nil if FILE has #+ARCHIVE: 1 (or t/yes/true)."
  (let ((v (my-org-file-flag file "ARCHIVE")))
    (and v (member (downcase v) '("1" "t" "yes" "true")))))

(defun my-org-file-tags (file)
  "Get a list of tags from FILE's #+TAGS: keyword, or nil if absent.
Expects a comma-separated list, e.g. #+TAGS: some, tags"
  (let ((v (my-org-file-flag file "TAGS")))
    (when v
      (mapcar #'string-trim (split-string v ",")))))

(defun my-slugify (s)
  "Lowercase S and collapse runs of non-alphanumeric chars into a single dash."
  (string-trim (downcase (replace-regexp-in-string "[^a-zA-Z0-9]+" "-" s)) "-" "-"))

(defun my-collect-all-posts ()
  "Return a list of (TITLE DATE HTML-FILE ARCHIVED-P TAGS) for every post."
  (let* ((files (directory-files "./content" t "\\.org$"))
         (files (seq-remove
                 (lambda (f) (member (file-name-base f) my-post-exclude))
                 files)))
    (mapcar (lambda (f)
              (list (my-org-file-title f)
                    (my-org-file-date f)
                    (concat (file-name-base f) ".html")
                    (my-post-archived-p f)
                    (my-org-file-tags f)))
            files)))

(defun my-sort-posts-newest-first (posts)
  "Sort POSTS by date, newest first."
  (sort (copy-sequence posts)
        (lambda (a b) (time-less-p (nth 1 b) (nth 1 a)))))

(defun my-render-post-item (p)
  "Render a single <li> entry for post P."
  (format "<li><a href=\"%s\">%s</a> <span class=\"meta\">%s</span></li>"
          (nth 2 p) (nth 0 p) (format-time-string "%Y-%m-%d" (nth 1 p))))

(defun my-render-tags-html (tags)
  "Render TAGS (a list of strings) as a row of clickable .tag chips
linking to their section on tags.html, with a label prefix. \"\" if none."
  (if tags
      (concat "<div class=\"tag-row\"><span class=\"tag-label\">Tags:</span>"
              (mapconcat (lambda (tag)
                           (format "<a href=\"tags.html#tag-%s\" class=\"tag\">%s</a>"
                                   (my-slugify tag) tag))
                         tags
                         "")
              "</div>")
    ""))

(defun my-render-recent-posts-html ()
  "Teaser of the N most recent active (non-archived) posts, for the homepage."
  (let* ((active (seq-remove (lambda (p) (nth 3 p)) (my-collect-all-posts)))
         (sorted (my-sort-posts-newest-first active))
         (posts (seq-take sorted (min my-recent-posts-count (length sorted)))))
    (if (null posts)
        "<p class=\"muted\">nothing for now...</p>"
      (concat "<ul class=\"post-list\">"
              (mapconcat #'my-render-post-item posts "")
              "</ul>"))))

(defun my-render-blog-list-html ()
  "Every post that has not been archived, newest first."
  (let ((posts (my-sort-posts-newest-first
                (seq-remove (lambda (p) (nth 3 p)) (my-collect-all-posts)))))
    (if (null posts)
        "<p class=\"muted\">nothing for now...</p>"
      (concat "<ul class=\"post-list\">"
              (mapconcat #'my-render-post-item posts "")
              "</ul>"))))

(defun my-render-archive-list-html ()
  "Archived posts, grouped and sorted by year (newest year first)."
  (let* ((posts (seq-filter (lambda (p) (nth 3 p)) (my-collect-all-posts)))
         (by-year (sort (seq-group-by
                          (lambda (p) (format-time-string "%Y" (nth 1 p)))
                          posts)
                         (lambda (a b) (string> (car a) (car b))))))
    (mapconcat
     (lambda (group)
       (format "<div class=\"archive-year\"><h2>%s</h2><ul class=\"post-list\">%s</ul></div>"
               (car group)
               (mapconcat #'my-render-post-item
                          (my-sort-posts-newest-first (cdr group))
                          "")))
     by-year
     "")))

(defun my-render-tags-page-html ()
  "A visible cloud of tag names up top; each tag's post list is hidden
by default and revealed via CSS :target when its anchor is visited."
  (let* ((posts (my-collect-all-posts))
         (pairs (seq-mapcat
                 (lambda (p) (mapcar (lambda (tag) (cons tag p)) (nth 4 p)))
                 posts))
         (by-tag (sort (seq-group-by #'car pairs)
                        (lambda (a b) (string-lessp (downcase (car a)) (downcase (car b)))))))
    (if (null by-tag)
        "<p class=\"muted\">no tags yet...</p>"
      (concat
       "<div class=\"tag-cloud\">"
       (mapconcat (lambda (group)
                    (format "<a href=\"tags.html#tag-%s\" class=\"tag\">%s</a>"
                            (my-slugify (car group)) (car group)))
                  by-tag
                  "")
       "</div>"
       (mapconcat
        (lambda (group)
          (let* ((tag (car group))
                 (tag-posts (my-sort-posts-newest-first (mapcar #'cdr (cdr group)))))
            (format "<div class=\"tag-group\" id=\"tag-%s\"><a href=\"tags.html\" class=\"tag-back\">[close]</a><h2>%s</h2><ul class=\"post-list\">%s</ul></div>"
                    (my-slugify tag)
                    tag
                    (mapconcat #'my-render-post-item tag-posts ""))))
        by-tag
        "")))))

(defun my-inject-marker (file marker-id render-fn)
  "Replace <div id=\"MARKER-ID\"></div> in FILE with the output of RENDER-FN."
  (when (file-exists-p file)
    (let ((rendered-content (funcall render-fn)))
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (when (re-search-forward (format "<div id=\"%s\"></div>" marker-id) nil t)
          (replace-match rendered-content t t))
        (write-region (point-min) (point-max) file)))))

(defun my-inject-all ()
  (my-inject-marker "./public/index.html" "recent-posts" #'my-render-recent-posts-html)
  (my-inject-marker "./public/blog.html" "blog-list" #'my-render-blog-list-html)
  (my-inject-marker "./public/archive.html" "archive-list" #'my-render-archive-list-html)
  (my-inject-marker "./public/tags.html" "tags-list" #'my-render-tags-page-html)
  (my-inject-post-meta))

(defun my-inject-post-meta ()
  "Insert a small date line, and a tag row if any, right under the title
on every post page."
  (dolist (post (my-collect-all-posts))
    (let* ((html-file (concat "./public/" (nth 2 post)))
           (date-str (format-time-string "%Y-%m-%d" (nth 1 post)))
           (tags-html (my-render-tags-html (nth 4 post))))
      (when (file-exists-p html-file)
        (with-temp-buffer
          (insert-file-contents html-file)
          (goto-char (point-min))
          (when (re-search-forward "<h1 class=\"title\">.*?</h1>" nil t)
            (goto-char (match-end 0))
            (insert (format "\n<p class=\"meta post-date\">%s</p>%s" date-str tags-html)))
          (write-region (point-min) (point-max) html-file))))))

;; --- publish config ---

(setq org-publish-project-alist
      `(("blog-content"
         :base-directory "./content"
         :base-extension "org"
         :publishing-directory "./public"
         :recursive t
         :publishing-function org-html-publish-to-html
         :headline-levels 4
         :with-author t
         :with-creator nil
         :with-toc nil
         :section-numbers nil
         :time-stamp-file nil
         :html-head-include-default-style nil
         :html-head-include-scripts nil
         :html-head "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n<link rel=\"icon\" type=\"image/png\" href=\"favicon.png\"/>\n<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\"/>\n<script src=\"toc.js\" defer></script>"
         :html-preamble ,(my-render-nav)
         :html-postamble "<div class=\"footer-content\"><p>© %a · Written in Org-mode</p><a href=\"https://notbyai.fyi\" target=\"_blank\" rel=\"noopener\"><img src=\"images/not-by-ai.svg\" alt=\"Written by a Human, Not by AI\" class=\"not-by-ai-badge\" /></a></div><p class=\"footer-note\">All aspect in this page is written by a human.</p>")
        ("blog-static"
         :base-directory "./content"
         :base-extension "css\\|js\\|png\\|jpg\\|gif\\|svg\\|pdf\\|woff2\\|woff\\|ttf\\|ico\\|cur"
         :publishing-directory "./public"
         :recursive t
         :publishing-function org-publish-attachment)
        ("blog" :components ("blog-content" "blog-static"))))

(org-publish "blog" t)
(my-inject-all)
