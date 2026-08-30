;;; build.el --- ox-publish build script -*- lexical-binding: t; -*-
(require 'ox-publish)
(defvar my-site-title "")
(defvar my-nav-links
  '(("Home"     . "index.html")
    ("Blog"     . "blog.html")
    ("Links"    . "links.html")
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

(defvar my-post-exclude '("index" "archive" "projects" "blog" "404" "tags" "links")
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

(defun my-org-file-summary (file)
  "Extract a short summary from the first prose paragraph in FILE."
  (when (file-exists-p file)
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (while (re-search-forward "^#\\+.*$" nil t)
        (replace-match "" nil nil))
      (goto-char (point-min))
      (let* ((text (buffer-substring-no-properties (point-min) (point-max)))
             (text (replace-regexp-in-string "\\\\[a-zA-Z]+{}" "" text))
             (text (replace-regexp-in-string "\\[\\[[^]]+\\]\\[[^]]+\\]\\]" "" text))
             (text (replace-regexp-in-string "\\[\\[[^]]+\\]\\]" "" text))
             (text (replace-regexp-in-string "='\([^=]+\)'=" "\\1" text))
             (text (replace-regexp-in-string "=\\([^=]+\\)=" "\\1" text))
             (text (replace-regexp-in-string "\*\\([^*]+\\)\*" "\\1" text))
             (text (replace-regexp-in-string "/\\([^/]+\\)/" "\\1" text))
             (text (replace-regexp-in-string "~\\([^~]+\\)~" "\\1" text))
             (text (replace-regexp-in-string "{{{[^}]+}}}" "" text))
             (text (replace-regexp-in-string "@@html:.*?@@" "" text t))
             (text (replace-regexp-in-string "\\n\\n+" "\n" text))
             (paragraphs (split-string text "\n" t))
             (first-paragraph (seq-find (lambda (p) (not (string-empty-p (string-trim p)))) paragraphs))
             (clean (replace-regexp-in-string "[[:space:]]+" " " (string-trim (or first-paragraph ""))))
             (clean (if (> (length clean) 160)
                        (concat (substring clean 0 157) "...")
                      clean)))
        clean))))

(defun my-estimate-reading-time (text)
  "Estimate a reading time in minutes from TEXT."
  (let* ((words (split-string (replace-regexp-in-string "[^[:word:]]+" " " (or text "")) "[[:space:]]+" t))
         (word-count (length (seq-filter (lambda (w) (not (string-empty-p w))) words)))
         (minutes (max 1 (/ (+ word-count 199) 200))))
    (format "%d min read" minutes)))

(defun my-slugify (s)
  "Lowercase S and collapse runs of non-alphanumeric chars into a single dash."
  (string-trim (downcase (replace-regexp-in-string "[^a-zA-Z0-9]+" "-" s)) "-" "-"))

(defun my-collect-all-posts ()
  "Return a list of (TITLE DATE HTML-FILE ARCHIVED-P TAGS SUMMARY) for every post."
  (let* ((files (directory-files "./content" t "\\.org$"))
         (files (seq-remove
                 (lambda (f) (member (file-name-base f) my-post-exclude))
                 files)))
    (mapcar (lambda (f)
              (let* ((summary (my-org-file-summary f)))
                (list (my-org-file-title f)
                      (my-org-file-date f)
                      (concat (file-name-base f) ".html")
                      (my-post-archived-p f)
                      (my-org-file-tags f)
                      summary)))
            files)))

(defun my-sort-posts-newest-first (posts)
  "Sort POSTS by date, newest first."
  (sort (copy-sequence posts)
        (lambda (a b) (time-less-p (nth 1 b) (nth 1 a)))))

(defun my-render-post-item (p)
  "Render a single card entry for post P with summary and metadata."
  (let* ((title (nth 0 p))
         (date-str (format-time-string "%Y-%m-%d" (nth 1 p)))
         (summary (or (nth 5 p) ""))
         (tags (nth 4 p))
         (tags-html (my-render-tags-html tags))
         (read-time (my-estimate-reading-time summary)))
    (format "<li class=\"post-card\"><div class=\"post-card-body\"><a href=\"%s\" class=\"post-link\">%s</a><div class=\"post-meta-row\"><span class=\"meta\">%s</span><span class=\"meta\">•</span><span class=\"meta\">%s</span></div>%s%s</div></li>"
            (nth 2 p) title date-str read-time
            (if (and summary (not (string-empty-p summary)))
                (format "<p class=\"post-summary\">%s</p>" summary)
              "")
            tags-html)))

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
  "Year-based archive with a dropdown filter and all years shown by default."
  (let* ((posts (seq-filter (lambda (p) (nth 3 p)) (my-collect-all-posts)))
         (by-year (sort (seq-group-by
                          (lambda (p) (format-time-string "%Y" (nth 1 p)))
                          posts)
                         (lambda (a b) (string> (car a) (car b))))))
    (if (null by-year)
        "<p class=\"muted\">nothing archived yet...</p>"
      (let ((first-year t))
        (concat
         "<label class=\"archive-filter-label\" for=\"archive-year-select\">View year:</label>"
         "<select id=\"archive-year-select\" class=\"archive-filter\">"
         (mapconcat (lambda (group)
                      (let ((selected (if first-year
                                          (progn (setq first-year nil) " selected=\"selected\"") "")))
                        (format "<option value=\"year-%s\"%s>%s</option>"
                                (car group) selected (car group))))
                    by-year
                    "")
         "</select>"
         "<div class=\"archive-groups\">"
         (mapconcat
          (lambda (group)
            (let* ((year (car group))
                   (year-posts (my-sort-posts-newest-first (cdr group))))
              (format "<section class=\"archive-year\" id=\"year-%s\"><h2>%s</h2><ul class=\"mini-post-list\">%s</ul></section>"
                      year year
                      (mapconcat (lambda (p)
                                   (format "<li class=\"mini-post\"><a href=\"%s\">%s</a> <span class=\"meta\">%s</span></li>"
                                           (nth 2 p) (nth 0 p)
                                           (format-time-string "%Y-%m-%d" (nth 1 p))))
                                 year-posts
                                 ""))))
          by-year
          "")
         "</div>"
         "<script>"
         "(function() { const select = document.getElementById('archive-year-select'); const sections = Array.from(document.querySelectorAll('.archive-year')); if (!select || sections.length === 0) return; const show = (value) => { sections.forEach((s) => { s.style.display = (s.id === value) ? 'block' : 'none'; }); }; select.addEventListener('change', (e) => show(e.target.value)); show(select.value || sections[0].id); })();"
         "</script>")))))

(defun my-render-home-meta-html ()
  "Show the actual site build timestamp, which updates whenever the site rebuilds."
  (format "<p class=\"home-meta\">Last build: %s</p>"
          (format-time-string "%Y-%m-%d %H:%M:%S" (current-time))))

(defun my-render-tags-page-html ()
  "A plain tag index: just the available tags, no duplicated tag sections."
  (let* ((posts (my-collect-all-posts))
         (tags (sort (delete-dups (apply #'append (mapcar (lambda (p) (nth 4 p)) posts))) #'string-lessp)))
    (if (null tags)
        "<p class=\"muted\">no tags yet...</p>"
      (concat
       "<ul class=\"tag-cloud plain-list\">"
       (mapconcat (lambda (tag)
                    (format "<li><a href=\"tags.html#tag-%s\" class=\"tag\">%s</a></li>"
                            (my-slugify tag) tag))
                  tags
                  "")
       "</ul>"))))

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
  (my-inject-marker "./public/index.html" "home-meta" #'my-render-home-meta-html)
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
