;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

(require 'cl-lib)

(defun kb (bytes) (* bytes 1024))
(defun mb (bytes) (* (kb bytes) 1024))

(defun with-face (str &rest face-plist)
  (propertize str 'face face-plist))

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Rafael Nicdao"
      user-mail-address "nicdaoraf@gmail.com")

;; --- Global configuration -----------------------------------------------------------------

(defvar sync-folder-path "~/Dropbox")

;; --- Appearance -----------------------------------------------------------------

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

(defun my-ascii-banner-ansi-shadow ()
  (mapc (lambda (line)
          (insert (propertize (+doom-dashboard--center +doom-dashboard--width line)
                              'face 'doom-dashboard-banner) " ")
          (insert "\n"))
        '("=================     ===============     ===============   ========  ========"
          "\\\\ . . . . . . .\\\\   //. . . . . . .\\\\   //. . . . . . .\\\\  \\\\. . .\\\\// . . //"
          "||. . ._____. . .|| ||. . ._____. . .|| ||. . ._____. . .|| || . . .\\/ . . .||"
          "|| . .||   ||. . || || . .||   ||. . || || . .||   ||. . || ||. . . . . . . ||"
          "||. . ||   || . .|| ||. . ||   || . .|| ||. . ||   || . .|| || . | . . . . .||"
          "|| . .||   ||. _-|| ||-_ .||   ||. . || || . .||   ||. _-|| ||-_.|\\ . . . . ||"
          "||. . ||   ||-'  || ||  `-||   || . .|| ||. . ||   ||-'  || ||  `|\\_ . .|. .||"
          "|| . _||   ||    || ||    ||   ||_ . || || . _||   ||    || ||   |\\ `-_/| . ||"
          "||_-' ||  .|/    || ||    \\|.  || `-_|| ||_-' ||  .|/    || ||   | \\  / |-_.||"
          "||    ||_-'      || ||      `-_||    || ||    ||_-'      || ||   | \\  / |  `||"
          "||    `'         || ||         `'    || ||    `'         || ||   | \\  / |   ||"
          "||            .===' `===.         .==='.`===.         .===' /==. |  \\/  |   ||"
          "||         .=='   ███████╗███╗   ███╗ █████╗  ██████╗███████╗  `==  \\/  |   ||"
          "||      .=='    _-██╔════╝████╗ ████║██╔══██╗██╔════╝██╔════╝_  /|  \\/  |   ||"
          "||   .=='    _-'  █████╗  ██╔████╔██║███████║██║     ███████╗ `' |. /|  |   ||"
          "||.=='    _-'     ██╔══╝  ██║╚██╔╝██║██╔══██║██║     ╚════██║     `' |  /==.||"
          "=='    _-'        ███████╗██║ ╚═╝ ██║██║  ██║╚██████╗███████║         \\/   `=="
          "\\   _-'           ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝          `-_   /"
          "`''                                                                      ``'")))
(setq +doom-dashboard-ascii-banner-fn #'my-ascii-banner-ansi-shadow)

;; Hide dashboard menu (I know the shortcuts by now :P)
(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-shortmenu)

;; Stolen from https://tecosaur.github.io/emacs-config/config.html#splash-screen
;; Maybe move this stuff into a separate file
(defvar phrase-api-url
  (nth (random 3)
       '(("https://corporatebs-generator.sameerkumar.website/" :phrase)
         ("https://useless-facts.sameerkumar.website/api" :data)
         ("https://dev-excuses-api.herokuapp.com/" :text))))

(defmacro phrase-generate-callback (token &optional format-fn ignore-read-only callback buffer-name)
  `(lambda (status)
     (unless (plist-get status :error)
       (goto-char url-http-end-of-headers)
       (let ((phrase (plist-get (json-parse-buffer :object-type 'plist) (cadr phrase-api-url)))
             (inhibit-read-only ,(when (eval ignore-read-only) t)))
         (setq phrase-last (cons phrase (float-time)))
         (with-current-buffer ,(or (eval buffer-name) (buffer-name (current-buffer)))
           (save-excursion
             (goto-char (point-min))
             (when (search-forward ,token nil t)
               (with-silent-modifications
                 (replace-match "")
                 (insert ,(if format-fn format-fn 'phrase)))))
           ,callback)))))

(defvar phrase-last nil)
(defvar phrase-timeout 5)

(defmacro phrase-insert-async (&optional format-fn token ignore-read-only callback buffer-name)
  `(let ((inhibit-message t))
     (if (and phrase-last
              (> phrase-timeout (- (float-time) (cdr phrase-last))))
         (let ((phrase (car phrase-last)))
           ,(if format-fn format-fn 'phrase))
       (url-retrieve (car phrase-api-url)
                     (phrase-generate-callback ,(or token "\ufeff") ,format-fn ,ignore-read-only ,callback ,buffer-name))
       ;; For reference, \ufeff = Zero-width no-break space / BOM
       ,(or token "\ufeff"))))

(defun doom-dashboard-phrase ()
  (phrase-insert-async
   (progn
     (setq-local phrase-position (point))
     (mapconcat
      (lambda (line)
        (+doom-dashboard--center
         +doom-dashboard--width
         (with-temp-buffer
           (insert-text-button
            line
            'action
            (lambda (_)
              (setq phrase-last nil)
              (+doom-dashboard-reload t))
            'face 'doom-dashboard-menu-title
            'mouse-face 'doom-dashboard-menu-title
            'help-echo "Random phrase"
            'follow-link t)
           (buffer-string))))
      (split-string
       (with-temp-buffer
         (insert phrase)
         (setq fill-column (min 70 (/ (* 2 (window-width)) 3)))
         (fill-region (point-min) (point-max))
         (buffer-string))
       "\n")
      "\n"))
   nil t
   (progn
     (goto-char phrase-position)
     (forward-whitespace 1))
   +doom-dashboard-name))

(defadvice! doom-dashboard-widget-loaded-with-phrase ()
  :override #'doom-dashboard-widget-loaded
  (setq line-spacing 0.2)
  (insert
   "\n\n"
   (propertize
    (+doom-dashboard--center
     +doom-dashboard--width
     (doom-display-benchmark-h 'return))
    'face 'doom-dashboard-loaded)
   "\n"
   (doom-dashboard-phrase)
   "\n"))

;; Some universal colors
(defvar vscode-search-occ-bg "#48240a")
(defvar vscode-search-occ-fg "#cccccc")

(use-package doom-themes
  :config
  ;; Use the colorful treemacs theme
  (setq doom-themes-treemacs-theme "doom-colors"
        doom-themes-enable-bold nil    ; if nil, bold is universally disabled
        doom-themes-enable-italic nil)
  (doom-themes-treemacs-config)
  (doom-themes-org-config)

  ;; Modeline style tweaks
  (after! doom-modeline
    (custom-set-faces!
      '(mode-line :height 0.9 :width condensed)
      '(mode-line-inactive :height 0.9 :width condensed)
      '(mode-line-emphasis :inherit mode-line)
      '(doom-modeline-buffer-file :weight normal))
    ;; TERM (Alacritty)
    (unless (display-graphic-p)
      (custom-set-faces!
        `(mode-line :background "darkred")
        `(mode-line-inactive :background "black"))))

  ;; Custom style tweaks
  ;; See https://github.com/hlissner/emacs-doom-themes/blob/master/themes/doom-one-theme.el#L32
  ;; for the doom-colors
  (custom-set-faces!
    `(swiper-background-match-face-2 :background ,vscode-search-occ-bg
                                     :foreground ,vscode-search-occ-fg)
    `(swiper-match-face-2 :background ,vscode-search-occ-bg
                          :foreground ,vscode-search-occ-fg)
    `(swiper-line-face :background "DodgerBlue4"
                       :foreground ,vscode-search-occ-fg)
    ;; TODO Move the LSP faces out of here?
    `(lsp-ui-peek-peek :background "#000029")
    `(lsp-ui-peek-selection :background ,vscode-search-occ-bg
                            :foreground ,vscode-search-occ-fg)
    `(lsp-ui-peek-list :background "grey7"
                       :height 1.0
                       :width condensed)
    `(lsp-ui-peek-header :background "#000050"
                         :foreground "white"
                         :height 1.0
                         :width condensed)
    `(lsp-ui-peek-filename :foreground "#98be65"
                           :height 0.9
                           :width condensed
                           :box (:line-width (1 . 10)
                                 :color "grey7"))
    `(lsp-ui-peek-line-number :foreground "grey7")
    `(lsp-ui-peek-highlight :background ,vscode-search-occ-bg
                            :foreground ,vscode-search-occ-fg
                            :heght 1.0
                            :box nil
                            :inherit nil))
  ;; GUI
  (if (display-graphic-p)
      (custom-set-faces!
        `(default :background "black")
        `(fill-column-indicator :foreground ,(doom-color 'base1))
        `(window-divider :foreground ,(doom-color 'magenta))
        `(flycheck-posframe-error-face :background "firebrick"
                                       :foreground "white")
        `(flycheck-posframe-warning-face :background "dark goldenrod"
                                         :foreground "white"))
    ;; TERM (Alacritty)
    ;; Weirdly, "black" is more like "dark grey"
    (custom-set-faces!
      `(default :background "color-52")
      `(header-line :background "black"))))

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
(setq doom-font (font-spec :family "Ubuntu Mono" :size (or (string-to-number (getenv "EMACS_FONT_SIZE"))
                                                           16)))
;; (setq doom-variable-pitch-font (font-spec :family "Roboto Mono Light" :size 14))

;; Enable rainbow-mode to visualize hex strings
(defun enable-rainbow-mode ()
  (rainbow-mode +1))
(add-hook 'text-mode-hook #'enable-rainbow-mode)
(add-hook 'prog-mode-hook #'enable-rainbow-mode)

;; Prevent hl-line-mode from overriding rainbow-mode
(add-hook! 'rainbow-mode-hook
  (hl-line-mode (if rainbow-mode -1 +1)))

;; Doom modeline
(setq display-time-default-load-average nil
      display-time-24hr-format t)

;; Header line
;; (defun set-header-line-format ()
;;   (after! doom-modeline
;;     (setq header-line-format (with-face (doom-modeline-buffer-file-name)
;;                                         :box '(:line-width 5
;;                                                ;; HACK I got this colour via using a colour-picker
;;                                                :color "#282c34")))))
;; (add-hook 'text-mode-hook #'set-header-line-format)
;; (add-hook 'prog-mode-hook #'set-header-line-format)

;; --------------------------------------------------------------------------------

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; Disable highlighting of current line
(add-hook 'hl-line-mode-hook (lambda () (setq hl-line-mode nil)))

;; Structural editing
(use-package! evil-lisp-state
  :init (setq evil-lisp-state-global t)
  :config (evil-lisp-state-leader "SPC k"))

;; Company configuration
(after! company
  (setq company-idle-delay 0.2
        company-tooltip-idle-delay 0.2
        company-minimum-prefix-length 2)
  (define-key company-active-map (kbd "C-j") 'company-select-next-or-abort)
  (define-key company-active-map (kbd "C-k") 'company-select-previous-or-abort)
  (if (display-graphic-p)
      (define-key company-active-map (kbd "<tab>") 'company-complete-selection)
    ;; Terminal seems to work with just "TAB"
    (define-key company-active-map (kbd "TAB") 'company-complete-selection))
  (define-key company-mode-map (kbd "C-SPC") 'company-manual-begin))

;; --- Evil stuff ---------------------------------------------------

;; Searching should be done using 2 chars almost all the time
(setq avy-timeout-seconds 1)

;; Disable the annoying auto-comment on newline
(setq +evil-want-o/O-to-continue-comments nil)

;; Remove some conflicting keybindings with company-mode
(define-key global-map (kbd "C-j") nil)
(define-key global-map (kbd "C-k") nil)
;; (define-key global-map (kbd "TAB") nil)

(define-key evil-insert-state-map (kbd "C-j") nil)
(define-key evil-insert-state-map (kbd "C-k") nil)
(define-key evil-motion-state-map (kbd "<tab>") nil)

(define-key evil-motion-state-map (kbd "C-o") 'evil-jump-backward)
(define-key evil-motion-state-map (kbd "C-S-o") 'evil-jump-forward)

;; -------------------------------------------------------------------

;; Modeline
(after! doom-modeline
  (setq doom-modeline-buffer-file-name-style nil
        doom-modeline-height 0
        doom-modeline-major-mode-icon t
        doom-modeline-major-mode-color-icon t
        doom-modeline-buffer-modification-icon t
        doom-modeline-modal-icon nil
        doom-modeline-buffer-state-icon nil
        doom-modeline-enable-word-count nil
        doom-modeline-lsp nil))

;; Centaur Tabs configuration
(after! centaur-tabs
  (setq centaur-tabs-style "rounded"
        centaur-tabs-height 5
        centaur-tabs-set-icons t
        centaur-tabs-set-modified-marker t
        centaur-tabs-show-navigation-buttons t
        centaur-tabs-gray-out-icons 'buffer)
  (centaur-tabs-headline-match)
  (centaur-tabs-enable-buffer-reordering)
  ;; (setq centaur-tabs-adjust-buffer-order t)
  (centaur-tabs-mode t))

;; Lookup to not open browser
(setq +lookup-open-url-fn #'eww)

;; Highlight whole expression, not just the matching paren
(setq show-paren-style 'expression)
(custom-set-faces
 '(show-paren-match ((t (:foreground nil
                         :background "#333"
                         :weight normal)))))

;; org2blog
;; (require 'auth-source)
;; (let* ((credentials (auth-source-user-and-password "blog"))
;;        (username (nth 0 credentials))
;;        (password (nth 1 credentials))
;;        (config `("wordpress"
;;                  :url "http:///anonimitocom.wordpress.com/xmlrpc.php"
;;                  :username ,username
;;                  :password ,password)))
;;   (setq org2blog/wp-blog-alist config))
;; ;; org2blog
(setq org2blog/wp-blog-alist
      '(("blog"
         :url "http://anonimitocom.wordpress.com/xmlrpc.php"
         :username "anonimitoraf")))

;; --- Org-mode stuff ---

;; Auto-export org files to html when saved
(defun org-mode-export-hook()
  "Auto export html"
  (when (and (equal major-mode 'org-mode)
             (boundp 'org-mode-auto-export-html?)
             (equal org-mode-auto-export-html? t))
    (org-html-export-to-html t)))
(add-hook 'after-save-hook 'org-mode-export-hook)

;; Show clock on modeline
(setq org-clock-mode-line-total 'current)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(use-package! org
  :init
  (setq org-directory (concat sync-folder-path "/org")
        org-default-notes-file (concat org-directory "/notes/default.org")
        org-agenda-files (cl-map 'list (lambda (f) (concat org-directory "/" f))
                                 '("life"
                                   "work"
                                   "captures"
                                   "notes")))
  :config
  (setq org-agenda-span 60
        org-agenda-start-on-weekday nil
        org-agenda-start-day "-3d"
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-ellipsis " ▾"
        org-export-with-section-numbers nil
        org-hide-emphasis-markers t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 2
        org-src-preserve-indentation nil
        org-startup-folded 'content
        org-cycle-separator-lines 2
        org-todo-keywords '((sequence "TODO(t)" "ONGOING(o)" "ON HOLD(h)" "|" "DONE(d)" "CANCELLED(c)")
                            (sequence "[ ](T)" "[-](O)" "[?](H)" "|" "[X](D)"))
        org-log-done 'time
        org-hide-leading-stars t
        org-superstar-headline-bullets-list '("▪")
        org-superstar-cycle-headline-bullets 1
        org-superstar-todo-bullet-alist '("▪")
        org-tags-column -120))

;; --- org-download (Allows pasting stuff into org-mode)
(require 'org-download)

;; Drag-and-drop to `dired`
(add-hook 'dired-mode-hook 'org-download-enable)

(setq org-download-method 'attach)
(setq org-image-actual-width nil)

;; --- Recur

;; See https://github.com/m-cat/org-recur
(use-package org-recur
  :hook ((org-mode . org-recur-mode)
         (org-agenda-mode . org-recur-agenda-mode))
  :demand t
  :config
  (define-key org-recur-mode-map (kbd "C-c d") 'org-recur-finish)

  ;; Rebind the 'd' key in org-agenda (default: `org-agenda-day-view').
  (define-key org-recur-agenda-mode-map (kbd "d") 'org-recur-finish)
  (define-key org-recur-agenda-mode-map (kbd "C-c d") 'org-recur-finish)

  (setq org-recur-finish-done t
        org-recur-finish-archive t))

;; Refresh org-agenda after rescheduling a task.
(defun org-agenda-refresh ()
  "Refresh all `org-agenda' buffers."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (derived-mode-p 'org-agenda-mode)
        (org-agenda-maybe-redo)))))

(defadvice org-schedule (after refresh-agenda activate)
  "Refresh org-agenda."
  (org-agenda-refresh))

;; Log time a task was set to Done.
(setq org-log-done (quote time))

;; Don't log the time a task was rescheduled or redeadlined.
(setq org-log-redeadline nil)
(setq org-log-reschedule nil)

;; Prefer rescheduling to future dates and times
(setq org-read-date-prefer-future 'time)

;; --- Habit

(require 'org-habit)
(setq org-habit-show-habits-only-for-today nil)

;; --- Agenda

(setq org-agenda-window-setup 'other-window)

;; --- Babel

;; NodeJS setup
(setenv "NODE_PATH"
        (concat
         (getenv "HOME") "/org/node_modules"  ":"
         (getenv "NODE_PATH")))

;; Clojure setup
(require 'ob-clojure)
(require 'cider)
(setq org-babel-clojure-backend 'cider)

(require 'ob-sql)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . nil)
   (Clojure . t)
   (Javascript . t)
   (sql . t)))

;; --- Capture

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(after! org
  (setq org-capture-templates
        '(("t" "" entry (file "~/Dropbox/org/captures/tasks.org")
           "* TODO %?\n%U"
           :kill-buffer t)
          ("t" "Task" entry (file "~/Dropbox/org/captures/tasks.org")
           "* TODO %?\n%U"
           :kill-buffer t)
          ("e" "From emacs" entry (file "~/Dropbox/org/captures/from-emacs.org")
           "* %i\n%?"
           :empty-lines 1
           :kill-buffer t)
          ("c" "From clipboard" entry (file "~/Dropbox/org/captures/from-clipboard.org")
           "* %x\n%?"
           :empty-lines 1
           :kill-buffer t)
          ("s" "Shopping list" entry (file "~/Dropbox/org/captures/shopping-list.org")
           "* [ ] %?"
           :jump-to-captured t
           :empty-lines 1
           :kill-buffer t))))

;; --- LSP stuff --------------------------------------------

;; Complements `find-defintions' (which is `g d')
(define-key evil-normal-state-map (kbd "g f") 'lsp-ui-peek-find-references)

(use-package! all-the-icons
  :config (setq all-the-icons-scale-factor 0.90))

(after! lsp-mode
  (custom-set-faces!
    '(header-line :height 0.90))
  (setq lsp-lens-enable nil
        lsp-log-io nil
        lsp-completion-no-cache nil
        lsp-completion-enable nil
        lsp-headerline-breadcrumb-enable t
        lsp-headerline-breadcrumb-enable-diagnostics nil
        lsp-completion-sort-initial-results nil
        lsp-completion-use-last-result nil))

(after! lsp-ui
  (define-key lsp-ui-peek-mode-map (kbd "j") 'lsp-ui-peek--select-next)
  (define-key lsp-ui-peek-mode-map (kbd "k") 'lsp-ui-peek--select-prev)
  (define-key lsp-ui-peek-mode-map (kbd "C-k") 'lsp-ui-peek--select-prev-file)
  (define-key lsp-ui-peek-mode-map (kbd "C-j") 'lsp-ui-peek--select-next-file)

  (map! :map lsp-mode-map
        :nv "SPC c m" #'lsp-ui-imenu
        :nv "SPC d" #'lsp-ui-doc-glance)

  (setq lsp-ui-peek-fontify 'always
        lsp-ui-peek-list-width 100
        lsp-ui-peek-peek-height 40

        lsp-ui-doc-enable nil
        ;; Prevents LSP peek to disappear when mouse touches it
        lsp-ui-doc-show-with-mouse nil
        lsp-ui-doc-include-signature t
        lsp-ui-doc-delay 0
        lsp-ui-doc-position 'at-point
        lsp-ui-doc-max-width 120
        lsp-ui-doc-max-height 120
        lsp-ui-doc-header t

        lsp-ui-imenu-enable t

        ;; This is just annoying, really
        lsp-ui-sideline-enable nil)

  ;; Clojure/script stuff to ignore
  (dolist (to-ignore '("[/\\\\]\\.clj-kondo$"
                       "[/\\\\]\\.shadow-cljs$"
                       "[/\\\\]resources$"))
    (add-to-list 'lsp-file-watch-ignored to-ignore)))

;; Copied from https://github.com/emacs-lsp/lsp-ui/issues/441
;;
;; Display lsp-ui-peek in a childframe so that the whole screen is used despite multiple windows.
;; Only on GUI though since TTY doesn't support posframes :(
(when (display-graphic-p)
  (defun lsp-ui-peek--peek-display (src1 src2)
    (-let* ((win-width (frame-width))
            (lsp-ui-peek-list-width (/ (frame-width) 2))
            (string (-some--> (-zip-fill "" src1 src2)
                      (--map (lsp-ui-peek--adjust win-width it) it)
                      (-map-indexed 'lsp-ui-peek--make-line it)
                      (-concat it (lsp-ui-peek--make-footer)))))
      (setq lsp-ui-peek--buffer (get-buffer-create " *lsp-peek--buffer*"))
      (posframe-show lsp-ui-peek--buffer
                     :string (mapconcat 'identity string "")
                     :min-width (frame-width)
                     :poshandler #'posframe-poshandler-frame-center)))

  (defun lsp-ui-peek--peek-destroy ()
    (when (bufferp lsp-ui-peek--buffer)
      (posframe-delete lsp-ui-peek--buffer))
    (setq lsp-ui-peek--buffer nil
          lsp-ui-peek--last-xref nil)
    (set-window-start (get-buffer-window) lsp-ui-peek--win-start))

  (advice-add #'lsp-ui-peek--peek-new :override #'lsp-ui-peek--peek-display)
  (advice-add #'lsp-ui-peek--peek-hide :override #'lsp-ui-peek--peek-destroy))
;; ---

;; Automatically refresh LSP imenu when changing windows
;; (add-hook 'window-state-change-hook (cmd! (when (bound-and-true-p lsp-ui-mode)
;;                                             (let ((curr-window (selected-window)))
;;                                               (lsp-ui-imenu)
;;                                               ;; Otherwise we're stuck in an endless
;;                                               ;; loop of being in the imenu
;;                                               (select-window curr-window)))))

(setq read-process-output-max (mb 1))

;; --- Clojure stuff --------------------------------------------

;; See issue with sayid and nativecomp: https://github.com/clojure-emacs/sayid/pull/59
;; (eval-after-load 'clojure-mode
;;   '(sayid-setup-package))

;; Dash docsets
(add-to-list 'dash-docs-docsets "Clojure")

(add-hook 'clojure-mode-hook
          '(lambda ()
             ;; Set some new syntax-highlighting rules.
             ;; Guardrail's >defn
             ;; Highlight particular macros similar to built-in stuff
             ;; For example, highlight ghostwheel's `>defn' similar
             ;; the same way as built-in `defn'
             (font-lock-add-keywords nil
                                     ;; So many escape codes! But we're really just saying:
                                     ;; Match the '(' character.
                                     ;; Match and group the string '>defn'.
                                     ;; Match some whitespace. \\s-+
                                     ;; Match and group some word characters. \\w+
                                     '(("(\\(>defn\\)\\s-+\\(\\w+\\)"
                                        ;; The first regexp group is a keyword.
                                        (1 font-lock-keyword-face)
                                        ;; The second regexp group is a name.
                                        (2 font-lock-function-name-face))))
             (put '>defn 'clojure-doc-string-elt 2)))

(set-popup-rules!
  '(("^\\*cider-repl"
     :quit nil
     :side bottom
     :size 0.2
     :select t)
    ("^\\*\\(?:cider-doc\\|lsp-help\\)"
     :side right
     :size 0.5)))

;; --- Emacs Lisp stuff ---------------------------------------------------

(setq byte-compile-warnings '(not obsolete))
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (define-key emacs-lisp-mode-map "\C-c\C-v" erefactor-map)))

;; --- (Type|Java)script stuff ---------------------------------------------------

(setq typescript-indent-level 2)
(add-hook 'js2-mode-hook (lambda () (setq js2-basic-offset 2)))

(require 'gherkin-mode)
(add-to-list 'auto-mode-alist '("\\.feature\\'" . gherkin-mode))

;; --- eshell stuff ---------------------------------------------------

;; Company mode in eshell makes it lag
(add-hook 'eshell-mode-hook (lambda () (company-mode -1)))

;; Clear the eshell buffer.
(defun eshell/clear ()
  (let ((eshell-buffer-maximum-lines 0)) (eshell-truncate-buffer)))

;; --- shell stuff ---------------------------------------------------

;; Company mode in shell is just annoying
(add-hook 'shell-mode-hook (lambda () (company-mode -1)))

;; --- Company stuff ---------------------------------------------------

;; (set-company-backend! 'clojurescript-mode
;;   'company-capf 'company-dabbrev-code 'company-dabbrev)

;; --- Treemacs stuff ---------------------------------------------------

(add-hook 'treemacs-mode-hook
          (lambda ()
            (when (display-graphic-p)
              (text-scale-decrease 1.5))))

(with-eval-after-load 'treemacs-icons
  (when (display-graphic-p)
    (treemacs-resize-icons 10)))

(use-package treemacs
  :commands (treemacs)
  :bind (("<f8>" . treemacs)
         ("<f9>" . treemacs-select-window))
  :init
  (progn
    (when window-system
      (setq treemacs-width 30
            treemacs-is-never-other-window t
            treemacs-file-event-delay 1000
            treemacs-show-cursor t
            treemacs--width-is-locked nil
            treemacs-space-between-root-nodes nil
            treemacs-filewatch-mode t
            treemacs-fringe-indicator-mode t))
    (when (not (display-graphic-p))
      (setq treemacs-no-png-images t))))

;; --- Ivy ---------------------------------------------------

(after! ivy-posframe
  (setf (alist-get t ivy-posframe-display-functions-alist)
        #'ivy-posframe-display-at-frame-top-center)
  (setf (alist-get 'swiper ivy-posframe-display-functions-alist)
        #'ivy-posframe-display-at-frame-top-center)
  (setq ivy-posframe-border-width 10
        ivy-posframe-width 120
        ivy-posframe-parameters (append ivy-posframe-parameters '((left-fringe . 3)
                                                                  (right-fringe . 3)))))
(setq posframe-arghandler
      (lambda (_buffer-or-name key value)
        (or (eq key :lines-truncate)
            value)))

;; Get rid of ./ and ../
(setq ivy-extra-directories ())

;; --- Emacs-Anywhere ----------------------------------------

(defun popup-handler (app-name window-title x y w h)
  (set-frame-position (selected-frame) x (+ y (- h 400)))
  (unless (zerop w)
    (set-frame-size (selected-frame) w 400 t)))
(add-hook 'ea-popup-hook 'popup-handler)

;; --- Tramp ---------------------------------------------------

;; (require 'tramp)
;; (setq tramp-default-method "ssh")
;; (setq tramp-syntax 'simplified)

;; --- Kubernetes ---------------------------------------------------

(use-package kubernetes
  :ensure t
  :commands (kubernetes-overview))

(use-package kubernetes-evil
  :ensure t
  :after kubernetes)

;; --- Files ---------------------------------------------------

(map! :nv "SPC f g" #'projectile-find-file-other-window)

(use-package! projectile
  :config
  (setq projectile-files-cache-expire 10))

;; --- Email ---------------------------------------------------

(use-package mu4e
  :ensure nil
  :defer 10 ;; Avoid laggy startup
  ;; Ubuntu
  :load-path "/usr/share/emacs/site-lisp/mu4e"
  :config
  (progn
    (setq mu4e-update-interval 30
          mu4e-get-mail-command "mbsync -a"
          mu4e-maildir "~/.mail"
          mu4e-compose-context-policy 'ask-if-none
          mu4e-compose-format-flowed t
          message-send-mail-function 'smtpmail-send-it
          message-kill-buffer-on-exit t)
    (add-to-list 'mu4e-view-actions
                 '("browser-view" . mu4e-action-view-in-browser) t)
    (setq mu4e-contexts (list
                         (make-mu4e-context
                          :name "cooltrax"
                          :match-func (lambda (msg)
                                        (when msg (string-prefix-p "/cooltrax" (mu4e-message-field msg :maildir))))
                          :vars '((smtpmail-smtp-server   . "smtp.office365.com")
                                  (smtpmail-smtp-service  . 587)
                                  (smtpmail-stream-type   . starttls)
                                  (smtpmail-smtp-user     . "rafael.nicdao@cooltrax.com")
                                  (user-mail-address      . "rafael.nicdao@cooltrax.com")
                                  (user-full-name         . "Rafael Nicdao")
                                  (mu4e-compose-signature . "\nThanks,\nRaf")

                                  (mu4e-drafts-folder     . "/cooltrax/Drafts")
                                  (mu4e-sent-folder       . "/cooltrax/Sent Items")
                                  (mu4e-refile-folder     . "/cooltrax/All")
                                  (mu4e-trash-folder      . "/cooltrax/Trash")

                                  (mu4e-maildir-shortcuts . (("/cooltrax/Inbox" . ?i)
                                                             ("/cooltrax/Sent Items" . ?s)))))
                         (make-mu4e-context
                          :name "gmail-bboynimito"
                          :match-func (lambda (msg)
                                        (when msg (string-prefix-p "/gmail/bboynimito" (mu4e-message-field msg :maildir))))
                          :vars '((smtpmail-smtp-server   . "smtp.gmail.com")
                                  (smtpmail-smtp-service  . 587)
                                  (smtpmail-stream-type   . starttls)
                                  (smtpmail-smtp-user     . "bboynimito@gmail.com")
                                  (user-mail-address      . "bboynimito@gmail.com")
                                  (user-full-name         . "Rafael Nicdao")
                                  (mu4e-compose-signature . "\nRegards,\nRaf")

                                  (mu4e-drafts-folder     . "/gmail/bboynimito/Drafts")
                                  (mu4e-sent-folder       . "/gmail/bboynimito/Sent Items")
                                  (mu4e-refile-folder     . "/gmail/bboynimito/All")
                                  (mu4e-trash-folder      . "/gmail/bboynimito/Trash")

                                  (mu4e-maildir-shortcuts . (("/gmail/bboynimito/Inbox" . ?i)
                                                             ("/gmail/bboynimito/Sent Items" . ?s)))))))))

(defun start-mu4e-background ()
  "Start mu4e in the background."
  (interactive)
  (mu4e t))

(require 'org-mime)

;; --- Webkit ---------------------------------------------------

(use-package webkit)
(use-package webkit-ace) ;; If you want link hinting
(use-package webkit-dark) ;; If you want to use the simple dark mode

;; --- IELM -----------------------------------------------------

(setq ielm-noisy nil
      ielm-prompt "λ> ")

;; --- Documentation -----------------------------------------------------

(unbind-key "K" evil-normal-state-map)
(unbind-key "K" evil-visual-state-map)
(unbind-key "K" evil-motion-state-map)
(map! :leader :desc "Lookup doc" :n "e" #'+lookup/documentation)

;; --- Windows ---------------------------------------------------

(map! :map doom-leader-map "w SPC" #'ace-select-window)

;; --- Local packages ---------------------------------------------------

(require 'helm)
(require 'selectrum)
(add-to-list 'load-path "~/work/open-source/emacs-lisp/gripe")
(use-package gripe
  :config (setq gripe-completion 'ivy))

;; --- Bookmarks ---------------------------------------------------

;; I want to sync bookmarks across my devices
(setq bookmark-default-file (concat sync-folder-path "/emacs/bookmarks"))

;; Save bookmarks immediately (rather than just when Emacs is killed)
(setq bookmark-save-flag 1)

;; --- Databases ---------------------------------------------------

(require 'edbi)

;; --- Sessions ---------------------------------------------------

;; I want to sync sessions across my devices
(setq persp-save-dir (concat sync-folder-path "/emacs/sessions/"))

;; --- Keybindings ---------------------------------------------------
;; TODO Maybe move these to a different file

(map! :leader
      :desc "Query and replace within region" "r" #'query-replace)

;; --- Dictionary/Thesaurus ---------------------------------------------------

(require 'synosaurus)

;; --- Misc ---------------------------------------------------

;; Fix for some keys not working in alacritty (e.g. C-S-up)
;; Source https://github.com/alacritty/alacritty/issues/3569#issuecomment-610558110
(add-to-list 'term-file-aliases '("alacritty" . "xterm"))

(which-key-mode +1)

;; Smooth scrolling
(require 'smooth-scrolling)

;; Line-wrapping, seems badly named
(global-visual-line-mode t)

;; Terminal emacs tends to throw a bunch of extra errors
(when (not (display-graphic-p))
  (setq debug-on-error nil))

(unless (display-graphic-p)
  (setq +format-on-save-enabled-modes
        '(not sql-mode         ; sqlformat is currently broken
              tex-mode         ; latexindent is broken
              org-mode
              latex-mode
              snippet-mode
              text-mode
              typescript-mode
              js-mode
              js2-mode
              gherkin-mode)))

(defun bespoke/load-and-continuously-save (file)
  (interactive
   (let ((session-file (doom-session-file)))
     (list (or (read-file-name "Regularly saving session to: "
                               (file-name-directory session-file)
                               (file-name-nondirectory session-file))
               (user-error "No session selected. Aborting")))))
  (unless file
    (error "No session file selected"))
  ;; Load the session
  (doom/load-session file)
  ;; Clear any previous calls to this fn
  (when (boundp 'bespoke-continuous-saving-timer)
    (cancel-timer bespoke-continuous-saving-timer))
  ;; Save the session every 10 seconds
  (setq bespoke-continuous-saving-timer
        (run-with-timer 1 10 (cmd!
                              ;; (message "Saving '%s' session" file)
                              (let ((message-log-max nil)
                                    (inhibit-message t))
                                (doom-save-session file))))))
(map! :map doom-leader-map "q N" 'bespoke/load-and-continuously-save)

;; Disable *Messages* from popping up when minibuffer is clicked
(define-key minibuffer-inactive-mode-map [mouse-1] #'ignore)

;; Clock on modeline
(display-time-mode +1)

;; TODO: Maybe each mode has to be different
(add-hook 'prog-mode-hook (cmd! (setq indent-tabs-mode nil)
                                (doom/set-indent-width 2)))

;; Fix the ispell dict
(setq ispell-dictionary "en")

;; Smooth scrolling through org-images, etc
(require 'iscroll)
(iscroll-mode +1)

;; Emacs as a WM
;; (require 'exwm)
;; (require 'exwm-config)
;; (exwm-config-default)

;; Flex on Discord that we're using Emacs
(defun start-elcord ()
  (interactive)
  (use-package! elcord
    :config
    (setq elcord-refresh-rate 5
          elcord-use-major-mode-as-main-icon t)
    (elcord-mode +1)
    (message "Started elcord")))

(defun stop-elcord ()
  (interactive)
  (elcord-mode -1)
  (message "Stopped elcord"))

;; See https://github.com/hlissner/doom-emacs/issues/3038
(after! counsel
  (setq counsel-rg-base-command "rg -M 240 --with-filename --no-heading --line-number --color never %s || true"))

;; Line numbers are already displayed in the modeline
(setq display-line-numbers-type nil)

;; --- Godot ---

(require 'gdscript-mode)

;; --- Custom scripts/commands ---

(defun external-gnome-terminal ()
  (interactive "@")
  (setenv "INSIDE_EMACS" nil) ;; We don't want gnome thinking that it's inside emacs
  (shell-command (concat "gnome-terminal"
                         " --working-directory " (file-name-directory (or load-file-name buffer-file-name))
                         " > /dev/null 2>&1 & disown") nil nil))

(defun external-xfce4-terminal ()
  (interactive "@")
  (setenv "INSIDE_EMACS" nil)
  (shell-command (concat "xfce4-terminal"
                         " --working-directory " (file-name-directory (or load-file-name buffer-file-name))
                         " > /dev/null 2>&1 & disown") nil nil))

(setq external-terminal-to-open 'xfce4)
(map! :n "SPC +" (cond ((eq external-terminal-to-open 'gnome) #'external-gnome-terminal)
                       ((eq external-terminal-to-open 'xfce4) #'external-xfce4-terminal)
                       (t (message (concat "Invalid value for variable `external-terminal-to-open:' " external-terminal-to-open)))))

;; --- Temporary stuff ---

;; Uncomment these for testing out Clojure LSP changes
;; (use-package lsp-mode
;;   :ensure t
;;   :hook ((clojure-mode . lsp)
;;          (clojurec-mode . lsp)
;;          (clojurescript-mode . lsp))
;;   :config
;;   ;; add paths to your local installation of project mgmt tools, like lein
;;   (setenv "PATH" (concat
;;                    "/usr/local/bin" path-separator
;;                    (getenv "PATH")))
;;   (dolist (m '(clojure-mode
;;                clojurec-mode
;;                clojurescript-mode
;;                clojurex-mode))
;;      (add-to-list 'lsp-language-id-configuration `(,m . "clojure")))
;;  ;; Optional: In case `clojure-lsp` is not in your PATH
;;   (setq lsp-clojure-server-command '("bash"
;;                                      "-c"
;;                                      "java -Xmx2g -server -Dclojure-lsp.version=2021.01.25-22.56.05 -jar /home/anonimito/work/open-source/clojure/clojure-lsp/target/clojure-lsp")
;;         lsp-enable-indentation nil))

;; ---------------------------------
;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c g k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c g d') to jump to their definition and see how
;; they are implemented.