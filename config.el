;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Rafael Nicdao"
      user-mail-address "nicdaoraf@gmail.com")

;; --- Appearance -----------------------------------------------------------------

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (load-theme 'doom-dark+ t)
(setq doom-theme 'doom-dark+)
(setq doom-dark+-blue-modeline nil)
(custom-set-faces
 '(default ((t (:background "#000000"
                :foreground "#ffffff"
                :height 90
                :foundry "CTDB"
                :family "Fira Code")))))

(custom-set-faces
  ;; Org
  '(org-code ((t (:foreground "gold")))))

;; (set-face-background 'default "#000000")
;; (set-face-foreground 'default "#ffffff")

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
;; (setq doom-font (font-spec :family "Fira Code" :size 13))

;; --------------------------------------------------------------------------------

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Dropbox/org")

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
  (setq company-idle-delay 0.5
        company-minimum-prefix-length 2)
  (define-key company-active-map (kbd "C-j") 'company-select-next-or-abort)
  (define-key company-active-map (kbd "C-k") 'company-select-previous-or-abort)
  (define-key company-active-map (kbd "C-SPC") 'company-complete-selection))

;; --- Evil stuff ---------------------------------------------------

;; Disable the annoying auto-comment on newline
(setq +evil-want-o/O-to-continue-comments nil)

;; Remove some conflicting keybindings with company-mode
(define-key global-map (kbd "C-j") nil)
(define-key global-map (kbd "C-k") nil)
(define-key evil-insert-state-map (kbd "C-j") nil)
(define-key evil-insert-state-map (kbd "C-k") nil)
(define-key evil-motion-state-map (kbd "TAB") nil)

(define-key evil-motion-state-map (kbd "C-o") 'evil-jump-backward)
(define-key evil-motion-state-map (kbd "C-S-o") 'evil-jump-forward)

;; -------------------------------------------------------------------

;; Modeline
(after! doom-modeline
  (setq
   doom-modeline-height 20
   doom-modeline-major-mode-icon t
   doom-modeline-major-mode-color-icon t
   doom-modeline-buffer-state-icon
   doom-modeline-buffer-modification-icon
   doom-modeline-lsp t))


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

;; Live markdown preview
(custom-set-variables
 '(livedown-autostart nil) ; automatically open preview when opening markdown files
 '(livedown-open t)        ; automatically open the browser window
 '(livedown-port 1337)     ; port for livedown server
 '(livedown-browser "firefox"))  ; browser to use

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

(after! org
  (setq org-todo-keywords '((sequence "TODO(t)" "START(s)" "HOLD(h)" "|" "DONE(d)" "CANCELLED(c)")
                            (sequence "[ ](T)" "[-](S)" "[?](H)" "|" "[X](D)"))
        org-log-done 'time
        org-hide-leading-stars t
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t))

(require 'ob-clojure)
(require 'cider)
(setq org-babel-clojure-backend 'cider)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . nil)
   (Clojure . t)
   (Javascript . t)))

;; --- Clojure stuff --------------------------------------------

(use-package lsp-mode
  :ensure t
  :hook ((clojure-mode . lsp)
         (clojurec-mode . lsp)
         (clojurescript-mode . lsp))
  :config
  (dolist (m '(clojure-mode
               clojurec-mode
               clojurescript-mode
               clojurex-mode))
     (add-to-list 'lsp-language-id-configuration `(,m . "clojure")))
  ;; Optional: In case `clojure-lsp` is not in your PATH
  (setq lsp-clojure-server-command '("bash" "-c" "/home/anonimito/.doom.d/misc/clojure-lsp")
        lsp-enable-indentation nil
        lsp-log-io t))

;; --- E-shell stuff ---------------------------------------------------
;; Company mode in eshell makes it lag
(add-hook 'eshell-mode-hook (lambda () (company-mode -1)))

;; --- Company stuff ---------------------------------------------------

(set-company-backend! 'clojurescript-mode
  'company-capf 'company-dabbrev-code 'company-dabbrev)


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
