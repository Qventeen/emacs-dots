;;; init.el --- Tangled Emacs configuration -*- lexical-binding: t; -*-

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(defvar q/default-gc-cons-threshold (* 128 1024 1024))

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold q/default-gc-cons-threshold
                  gc-cons-percentage 0.1)
            (message "Emacs ready in %.2fs with %d GCs."
                     (float-time (time-subtract after-init-time before-init-time))
                     gcs-done)))

(when (boundp 'native-comp-async-report-warnings-errors)
  (setq native-comp-async-report-warnings-errors 'silent))

;; Larger LSP/AI process chunks.
(setq read-process-output-max (* 1024 1024))

(setq package-enable-at-startup nil
      straight-use-package-by-default t)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(require 'use-package)

(setq use-package-always-ensure nil
      use-package-verbose nil)

(require 'cl-lib)
(require 'subr-x)

(defvar q/home-directory (file-name-as-directory (expand-file-name "~")))
(defvar q/data-directory (file-name-as-directory user-emacs-directory))
(defvar q/cache-directory (expand-file-name ".cache/" q/data-directory))
(defvar q/config-directory (expand-file-name "configs/" q/data-directory))
(defvar q/org-directory (expand-file-name "org/" q/home-directory))
(defvar q/notebase-directory
  (file-name-as-directory
   (expand-file-name
    (or (getenv "EMACS_NOTEBASE_DIRECTORY")
        "notebase/")
    q/home-directory))
  "Trusted root for Notebase Org and MCP filesystem access.")
(defvar q/yas-directory (expand-file-name "yasnippet/" q/data-directory))
(defvar q/autosaves-directory (expand-file-name "autosaves/" q/data-directory))
(defvar q/backups-directory (expand-file-name "backups/" q/data-directory))
(defvar q/org-roam-directory (expand-file-name "roam/" q/notebase-directory))
(defvar q/org-attach-directory (expand-file-name "data/" q/notebase-directory))

(when (eq system-type 'windows-nt)
  (setq q/home-directory (file-name-as-directory (expand-file-name "d:/"))
        q/data-directory (expand-file-name "Emacs/" q/home-directory)
        q/cache-directory (expand-file-name ".cache/" q/data-directory)
        q/config-directory (expand-file-name "configs/" q/data-directory)
        q/org-directory (expand-file-name "org/" q/home-directory)
        q/notebase-directory (expand-file-name "notebase/" q/home-directory)
        q/yas-directory (expand-file-name "yasnippet/" q/data-directory)
        q/autosaves-directory (expand-file-name "autosaves/" q/data-directory)
        q/backups-directory (expand-file-name "backups/" q/data-directory)
        q/org-roam-directory (expand-file-name "roam/" q/notebase-directory)
        q/org-attach-directory (expand-file-name "data/" q/notebase-directory)))

(defun q/notebase-path-p (path)
  "Return non-nil when PATH stays inside `q/notebase-directory'."
  (file-in-directory-p (file-truename path) (file-truename q/notebase-directory)))

(defun q/get-org-file (file-name)
  (expand-file-name file-name q/org-directory))

(defun q/get-notebase-file (file-name)
  (expand-file-name file-name q/notebase-directory))

(defun q/get-config-file (file-name)
  (expand-file-name file-name q/config-directory))

(defun q/ensure-directory (directory)
  (unless (file-directory-p directory)
    (make-directory directory t)))

(defvar q/notes-file-name (q/get-org-file "notes/notes.org"))
(defvar q/bookmarks-file-name (q/get-org-file "bookmarks/bookmarks.org"))
(defvar q/notebase-inbox-file (q/get-notebase-file "inbox.org"))
(defvar q/notebase-notes-file (q/get-notebase-file "notes.org"))

(mapc #'q/ensure-directory
      (list q/cache-directory q/autosaves-directory q/backups-directory q/notebase-directory q/org-directory
            q/org-roam-directory q/org-attach-directory
            (expand-file-name "literature/" q/org-roam-directory)
            (expand-file-name "notebooklm/" q/org-roam-directory)))

(use-package emacs
  :straight nil
  :init
  (setq custom-file (make-temp-file "emacs-custom-"))
  (setq inhibit-startup-message t
        initial-scratch-message ""
        initial-major-mode 'lisp-interaction-mode
        use-dialog-box nil
        ring-bell-function 'ignore
        confirm-kill-processes nil
        read-quoted-char-radix 10
        tab-width 4
        fill-column 79
        require-final-newline t
        sentence-end-double-space nil
        enable-recursive-minibuffers t
        read-extended-command-predicate #'command-completion-default-include-p
        minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (set-language-environment "UTF-8")
  (set-default-coding-systems 'utf-8-unix)
  (prefer-coding-system 'utf-8-unix)
  (defalias 'yes-or-no-p 'y-or-n-p)
  (put 'upcase-region 'disabled nil)
  (put 'downcase-region 'disabled nil)
  (column-number-mode 1)
  (global-auto-revert-mode 1)
  (global-prettify-symbols-mode 1)
  (when (fboundp 'context-menu-mode)
    (context-menu-mode 1))
  (when (executable-find "google-chrome-stable")
    (setq browse-url-browser-function #'browse-url-generic
          browse-url-generic-program "google-chrome-stable")))

(setq auto-save-default t
      auto-save-timeout 60
      auto-save-interval 60
      create-lockfiles nil
      delete-by-moving-to-trash t
      kept-new-versions 10
      delete-old-versions t
      backup-by-copying t
      vc-make-backup-files t
      make-backup-files t
      auto-save-file-name-transforms `((".*" ,q/autosaves-directory t))
      backup-directory-alist `((".*" . ,q/backups-directory)))

(use-package savehist
  :straight nil
  :init (savehist-mode 1))

(use-package recentf
  :straight nil
  :init (recentf-mode 1)
  :custom
  (recentf-max-saved-items 200)
  (recentf-auto-cleanup 'never))

(defun q/wl-copy (text &optional _push)
  (let ((process-connection-type nil))
    (let ((process (make-process :name "wl-copy"
                                 :buffer nil
                                 :command '("wl-copy")
                                 :connection-type 'pipe)))
      (process-send-string process text)
      (process-send-eof process))))

(defun q/wl-paste ()
  (string-trim-right (shell-command-to-string "wl-paste --no-newline")))

;; Terminal Wayland clipboard.
(when (and (not (display-graphic-p))
           (getenv "WAYLAND_DISPLAY")
           (executable-find "wl-copy")
           (executable-find "wl-paste"))
  (setq interprogram-cut-function #'q/wl-copy
        interprogram-paste-function #'q/wl-paste))

(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'menu-bar-mode)
  (menu-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))
(when (fboundp 'tab-bar-mode)
  (tab-bar-mode -1))

(add-to-list 'default-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(font . "JetBrains Mono-16"))

(use-package paren
  :straight nil
  :hook (after-init . show-paren-mode)
  :custom
  (show-paren-delay 0)
  :config
  (set-face-attribute 'show-paren-match nil :weight 'extra-bold))

(use-package elec-pair
  :straight nil
  :hook (after-init . electric-pair-mode))

(use-package doom-themes
  :demand t
  :config
  (load-theme 'doom-dracula t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

(use-package nerd-icons
  :defer t)

(use-package nerd-icons-dired
  :after (dired nerd-icons)
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :custom
  (doom-modeline-buffer-file-name-style 'relative-to-project))

(use-package vertico
  :custom
  (vertico-count 15)
  (vertico-cycle t)
  :init
  (vertico-mode 1))

(use-package vertico-directory
  :straight nil
  :after vertico
  :bind (:map vertico-map
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package marginalia
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle))
  :after vertico
  :init
  (marginalia-mode 1))

(use-package nerd-icons-completion
  :after (marginalia nerd-icons)
  :config
  (nerd-icons-completion-mode 1)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles basic partial-completion))))
  (orderless-matching-styles '(orderless-literal orderless-regexp orderless-flex)))

(use-package consult
  :bind (("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x 5 b" . consult-buffer-other-frame)
         ("M-y" . consult-yank-pop)
         ("C-s" . consult-line)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g f" . consult-flymake)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s r" . consult-ripgrep)
         ("M-s d" . consult-fd)
         ("C-c b" . consult-bookmark)
         ("C-c J" . consult-fd)
         ("C-c k" . consult-ripgrep)
         ("C-c o" . consult-outline)
         ("C-c t" . consult-theme)
         :map minibuffer-local-map
         ("M-r" . consult-history))
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :config
  (consult-customize consult-ripgrep consult-git-grep consult-grep consult-fd consult-find
                     :preview-key '(:debounce 0.3 any)))

(use-package consult-dir
  :after consult
  :bind (("C-x C-d" . consult-dir)
         :map vertico-map
         ("C-x C-d" . consult-dir)
         ("C-x C-j" . consult-dir-jump-file)))

(use-package embark
  :bind (("C-." . embark-act)
         ("M-." . embark-dwim)
         ("C-h b" . embark-bindings)
         ("C-h B" . embark-bindings))
  :init
  ;; Embark makes prefix discovery interactive.
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package corfu
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-quit-no-match 'separator)
  :init
  (global-corfu-mode 1))

(use-package cape
  :init
  (defun q/add-cape-capfs ()
    (add-hook 'completion-at-point-functions #'cape-file 90 t)
    (add-hook 'completion-at-point-functions #'cape-dabbrev 90 t)
    (add-hook 'completion-at-point-functions #'cape-keyword 90 t))
  (add-hook 'prog-mode-hook #'q/add-cape-capfs)
  (add-hook 'text-mode-hook #'q/add-cape-capfs))

(use-package nerd-icons-corfu
  :after (corfu nerd-icons)
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package completion-preview
  :straight nil
  :hook ((prog-mode text-mode) . completion-preview-mode))

(use-package dabbrev
  :straight nil
  :bind (("M-/" . dabbrev-completion)
         ("C-M-/" . dabbrev-expand))
  :config
  (add-to-list 'dabbrev-ignored-buffer-modes 'authinfo-mode)
  (add-to-list 'dabbrev-ignored-buffer-modes 'doc-view-mode))

(use-package which-key
  :straight nil
  :init
  (which-key-mode 1)
  :custom
  (which-key-side-window-max-height 0.4)
  (which-key-sort-order 'which-key-key-order-alpha))

(use-package ace-window
  :bind ("M-o" . ace-window)
  :custom
  (aw-dispatch-always t))

(use-package avy
  :bind (("C-:" . avy-goto-char)
         ("C-'" . avy-goto-char-2)
         ("C-;" . avy-goto-char-timer)
         ("M-g w" . avy-goto-word-1)
         ("M-g e" . avy-goto-word-0)
         ("C-c C-j" . avy-resume)))

(use-package helpful
  :commands (helpful-at-point helpful-command helpful-callable helpful-function helpful-variable helpful-key)
  :bind (("C-c C-d" . helpful-at-point)
         ("C-h C" . helpful-command)
         ("C-h x" . helpful-command)
         ("C-h f" . helpful-callable)
         ("C-h F" . helpful-function)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)))

(use-package discover-my-major
  :commands discover-my-major
  :bind ("C-h C-m" . discover-my-major))

(use-package ibuffer
  :straight nil
  :bind ("C-x C-b" . ibuffer))

(use-package dired
  :straight nil
  :commands dired
  :custom
  (dired-dwim-target t)
  (dired-kill-when-opening-new-dired-buffer t))

(use-package transient
  :straight nil
  :commands q/notebase-menu
  :bind ("C-c n SPC" . q/notebase-menu)
  :config
  (transient-define-prefix q/notebase-menu ()
    "Notebase command menu."
    [["Roam"
      ("f" "Find node" org-roam-node-find)
      ("i" "Insert node" org-roam-node-insert)
      ("b" "Backlinks" org-roam-buffer-toggle)]
     ["Capture"
      ("c" "Roam capture" org-roam-capture)
      ("a" "Attach file" org-attach)]
     ["AI and MCP"
      ("g" "GPTel" gptel)
      ("m" "MCP hub" mcp-hub)]]))

(use-package multiple-cursors
  :bind (("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)
         ("C-S-<mouse-1>" . mc/add-cursor-on-click)))

(use-package yasnippet
  :hook (after-init . yas-global-mode)
  :custom
  (yas-wrap-around-region t)
  (yas-snippet-dirs (list q/yas-directory)))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package wgrep
  :commands wgrep-change-to-wgrep-mode)

(use-package project
  :straight nil
  :bind-keymap ("M-<f1>" . project-prefix-map)
  :custom
  (project-vc-extra-root-markers
   '("README.md" "README.org" "README" "package.json" "pyproject.toml"
     "settings.gradle" "build.gradle" "go.mod" "Cargo.toml")))

(use-package magit
  :bind (("M-9" . magit-status)
         ("C-x g" . magit-status)))

(use-package ediff
  :straight nil
  :custom
  (ediff-keep-variants nil)
  (ediff-make-buffers-readonly-at-startup t)
  (ediff-show-clashes-only nil)
  (ediff-split-window-function 'split-window-vertically)
  (ediff-window-setup-function 'ediff-setup-windows-plain)
  :config
  (defun q/ediff-quit-without-prompt (fn &rest args)
    (cl-letf (((symbol-function 'y-or-n-p) (lambda (_prompt) t)))
      (apply fn args)))
  (advice-add 'ediff-quit :around #'q/ediff-quit-without-prompt))

(use-package treemacs
  :commands (treemacs treemacs-select-window)
  :bind (("M-1" . treemacs-select-window)
         ("C-x t 1" . treemacs-delete-other-windows)
         ("C-x t t" . treemacs)
         ("C-x t B" . treemacs-bookmark)
         ("C-x t C-t" . treemacs-find-file)
         ("C-x t M-t" . treemacs-find-tag))
  :custom
  (treemacs-width 30)
  (treemacs-position 'left)
  (treemacs-indentation 1)
  (treemacs-collapse-dirs 3)
  (treemacs-sorting 'alphabetic-asc)
  (treemacs-follow-after-init t)
  (treemacs-show-hidden-files t)
  (treemacs-space-between-root-nodes nil)
  (treemacs-is-never-other-window nil)
  (treemacs-no-delete-other-windows nil)
  (treemacs-project-follow-cleanup t)
  :config
  (treemacs-resize-icons 15)
  (treemacs-follow-mode 1)
  (treemacs-filewatch-mode 1)
  (treemacs-fringe-indicator-mode 'always)
  (when (executable-find "git")
    (treemacs-git-mode 'deferred)))

(use-package treemacs-nerd-icons
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package treemacs-magit
  :after (treemacs magit))

(use-package treesit
  :straight nil
  :config
  (defun q/remap-mode-if-treesit-ready (language mode ts-mode)
    (when (and (fboundp 'treesit-language-available-p)
               (treesit-language-available-p language))
      (add-to-list 'major-mode-remap-alist (cons mode ts-mode))))
  (q/remap-mode-if-treesit-ready 'python 'python-mode 'python-ts-mode)
  (q/remap-mode-if-treesit-ready 'javascript 'js-mode 'js-ts-mode)
  (q/remap-mode-if-treesit-ready 'typescript 'typescript-mode 'typescript-ts-mode)
  (q/remap-mode-if-treesit-ready 'json 'json-mode 'json-ts-mode)
  (q/remap-mode-if-treesit-ready 'yaml 'yaml-mode 'yaml-ts-mode)
  (q/remap-mode-if-treesit-ready 'bash 'sh-mode 'bash-ts-mode))

(use-package flymake
  :straight nil
  :bind (("C-c e b" . flymake-show-buffer-diagnostics)
         ("C-c e n" . flymake-goto-next-error)
         ("C-c e p" . flymake-goto-prev-error)))

(use-package eglot
  :straight nil
  :commands (eglot eglot-ensure)
  :hook ((python-mode python-ts-mode js-mode js-ts-mode typescript-mode typescript-ts-mode
          tsx-ts-mode yaml-mode yaml-ts-mode sh-mode bash-ts-mode java-mode java-ts-mode)
         . eglot-ensure)
  :bind (:map eglot-mode-map
              ("M-<insert>" . eglot-code-actions)
              ("M-RET" . eglot-code-actions)
              ("C-c e r" . eglot-rename)
              ("C-c e f" . eglot-format)
              ("C-c e a" . eglot-code-actions))
  :custom
  (eglot-autoshutdown t)
  :config
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) . ("pyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((yaml-mode yaml-ts-mode) . ("yaml-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((typescript-mode typescript-ts-mode tsx-ts-mode js-mode js-ts-mode)
                 . ("typescript-language-server" "--stdio")))
  (add-to-list 'eglot-server-programs
               '((sh-mode bash-ts-mode) . ("bash-language-server" "start"))))

(use-package yaml-mode
  :mode ("\\.ya?ml\\'" . yaml-mode))

(use-package typescript-mode
  :mode ("\\.ts\\'" . typescript-mode))

(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode)))

(use-package dockerfile-mode
  :mode ("Dockerfile\\'" . dockerfile-mode))

(use-package org
  :straight nil
  :commands (org-open-at-point org-babel-tangle org-babel-tangle-file)
  :bind (("C-c l" . org-store-link)
         ("C-c a" . org-agenda)
         ("C-c c" . org-capture))
  :hook (org-babel-after-execute . org-redisplay-inline-images)
  :custom
  (org-directory q/org-directory)
  (org-default-notes-file q/notes-file-name)
  (org-startup-indented t)
  (org-startup-folded t)
  (org-hide-block-startup nil)
  (org-startup-with-inline-images nil)
  (org-hide-leading-stars t)
  (org-hide-emphasis-markers t)
  (org-pretty-entities t)
  (org-src-preserve-indentation nil)
  (org-edit-src-content-indentation 0)
  (org-src-tab-acts-natively t)
  (org-src-window-setup 'current-window)
  (org-confirm-babel-evaluate nil)
  (org-image-actual-width nil)
  (org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id)
  :config
  (require 'org-id)
  (require 'org-tempo)
  ;; Agenda scanning is disabled until an agenda workflow is needed.
  (setq org-agenda-files nil
        org-capture-templates
        `(("i" "Inbox" entry
           (file ,q/notebase-inbox-file)
           "* TODO %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n")
          ("n" "Note" entry
           (file ,q/notebase-notes-file)
           "* %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n")))
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (shell . t)
     (sql . t)
     (python . t)))

  (defun q/org-tangle-after-save ()
    (when (and buffer-file-name
               (string-equal (file-name-extension buffer-file-name) "org"))
      (let ((org-confirm-babel-evaluate nil))
        (org-babel-tangle))))

  ;; Keep init.el generated from org sources.
  (add-hook 'after-save-hook #'q/org-tangle-after-save))

(use-package org-attach
  :straight nil
  :after org
  :custom
  (org-attach-id-dir q/org-attach-directory)
  (org-attach-preferred-new-method 'id)
  (org-attach-method 'cp)
  (org-attach-use-inheritance nil)
  (org-attach-store-link-p 'attached)
  :config
  (defun q/org-attach-id-path (id)
    (file-name-as-directory id))
  (add-to-list 'org-attach-id-to-path-function-list #'q/org-attach-id-path))

(use-package org-download
  :after org
  :preface
  (require 'url-handlers)
  :custom
  (org-download-method 'attach)
  (org-download-heading-lvl nil)
  (org-download-timestamp "%Y%m%d-%H%M%S_")
  :config
  (setq org-download-screenshot-method
        (cond
         ((and (executable-find "grim") (executable-find "slurp"))
          "grim -g \"$(slurp)\" %s")
         ((executable-find "flameshot")
          "flameshot gui --raw > %s")
         ((executable-find "gnome-screenshot")
          "gnome-screenshot -a -f %s")
         ((executable-find "import")
          "import %s"))))

(use-package visual-fill-column
  :init
  (defun q/prose-visual-mode ()
    "Use centered soft wrapping for prose buffers."
    (visual-line-mode 1)
    (visual-fill-column-mode 1))
  :hook ((org-mode markdown-mode) . q/prose-visual-mode)
  :custom
  (visual-fill-column-width 100)
  (visual-fill-column-center-text t))

(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :custom
  (org-modern-table nil)
  (org-modern-block-fringe nil)
  (org-modern-todo nil))

(use-package org-appear
  :after org
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-autoemphasis t)
  (org-appear-autolinks t)
  (org-appear-autosubmarkers t))

(use-package org-roam
  :after org
  :custom
  (org-roam-directory (file-truename q/org-roam-directory))
  (org-roam-db-location (expand-file-name "org-roam.db" q/cache-directory))
  (org-roam-database-connector 'sqlite-builtin)
  (org-roam-node-display-template
   (concat "${title:*} " (propertize "${tags:20}" 'face 'org-tag)))
  (org-roam-capture-templates
   '(("d" "Default note" plain "%?"
      :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                         "#+title: ${title}\n#+created: %U\n\n")
      :unnarrowed t)
     ("l" "Literature note" plain "%?"
      :target (file+head "literature/%<%Y%m%d%H%M%S>-${slug}.org"
                         "#+title: ${title}\n#+created: %U\n#+filetags: :literature:\n\n")
      :unnarrowed t)
     ("n" "NotebookLM delta" plain "%?"
      :target (file+head "notebooklm/%<%Y%m%d%H%M%S>-${slug}.org"
                         "#+title: ${title}\n#+created: %U\n#+filetags: :notebooklm:\n\n")
      :unnarrowed t)))
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture))
  :config
  (org-roam-db-autosync-mode 1))

(use-package org-roam-ui
  :straight (:host github :repo "org-roam/org-roam-ui" :branch "main" :files ("*.el" "out"))
  :after org-roam
  :commands org-roam-ui-mode
  :bind ("C-c n u" . org-roam-ui-mode)
  :custom
  (org-roam-ui-sync-theme t)
  (org-roam-ui-follow t)
  (org-roam-ui-update-on-save t)
  (org-roam-ui-open-on-start nil))

(use-package epa-file
  :straight nil
  :config
  (epa-file-enable))

(use-package auth-source
  :straight nil
  :custom
  (auth-sources '("~/.authinfo.gpg")))

(use-package gptel
  :commands (gptel gptel-send gptel-menu)
  :bind (("C-c g g" . gptel)
         ("C-c g s" . gptel-send)
         ("C-c g m" . gptel-menu))
  :config
  ;; ~/.authinfo.gpg entries:
  ;; machine api.openai.com login apikey password <openai-api-key>
  ;; machine api.anthropic.com login apikey password <anthropic-api-key>
  ;; machine generativelanguage.googleapis.com login apikey password <gemini-api-key>
  (setq gptel-api-key #'gptel-api-key-from-auth-source
        gptel-default-mode 'org-mode
        gptel-backend (gptel-make-openai "OpenAI"
                        :stream t
                        :key #'gptel-api-key-from-auth-source))
  (gptel-make-anthropic "Claude"
    :stream t
    :key #'gptel-api-key-from-auth-source)
  (gptel-make-gemini "Gemini"
    :stream t
    :key #'gptel-api-key-from-auth-source)
  (add-to-list
   'gptel-directives
   '(NotebookLM-to-OrgRoam
     . "You convert Google NotebookLM Markdown delta summaries into Org-roam notes. Output Org only. Convert Markdown headings to Org headings, Markdown links to Org links, and lists or tables to idiomatic Org syntax. Start the generated text with a :PROPERTIES: drawer containing a fresh UUID in :ID:, followed by :END:. Do not use code fences.")))

(defvar q/mcp-org-command-allowlist
  '(org-roam-db-sync
    org-roam-node-find
    org-roam-node-insert
    org-id-get-create
    org-attach
    org-store-link)
  "Org commands safe enough for an Emacs MCP server allowlist.")

(defvar q/mcp-notebase-guarded-servers '("notebase-files" "emacs-org" "emacs-mcp")
  "MCP server names guarded by Notebase path and command checks.")

(use-package mcp
  :after gptel
  :commands (mcp-hub mcp-hub-start-all-server mcp-hub-close-all-server)
  :init
  ;; Keep MCP file tools inside Notebase.
  (setq mcp-hub-servers
        `(("notebase-files"
           . (:command "npx"
              :args ("-y" "@modelcontextprotocol/server-filesystem")
              :roots (,q/notebase-directory)))))
  :config
  (require 'mcp-hub)

  (defun q/mcp-notebase--server-name (connection)
    (when (fboundp 'jsonrpc-name)
      (format "%s" (jsonrpc-name connection))))

  (defun q/mcp-notebase--collect-values (value keys)
    (let (values)
      (cond
       ((and (listp value) (keywordp (car value)))
        (while value
          (let ((key (pop value))
                (val (pop value)))
            (when (memq key keys)
              (if (and (listp val) (not (keywordp (car-safe val))))
                  (setq values (append val values))
                (push val values)))
            (setq values (append (q/mcp-notebase--collect-values val keys) values)))))
       ((listp value)
        (dolist (item value)
          (setq values (append (q/mcp-notebase--collect-values item keys) values)))))
      values))

  (defun q/mcp-notebase--allowed-command-p (command)
    (let ((symbol (cond
                   ((symbolp command) command)
                   ((stringp command) (intern-soft command)))))
      (memq symbol q/mcp-org-command-allowlist)))

  (defun q/mcp-notebase--validate-tool-args (connection tool-name args)
    (let ((server (q/mcp-notebase--server-name connection)))
      (when (member server q/mcp-notebase-guarded-servers)
        ;; Reject path arguments outside the Notebase root.
        (dolist (path (q/mcp-notebase--collect-values
                       args '(:path :paths :file :files :directory :directories
                                    :source :destination :src :dst)))
          (when (and (stringp path)
                     (not (q/notebase-path-p (expand-file-name path q/notebase-directory))))
            (error "MCP %s tried to access outside Notebase: %s" tool-name path)))
        ;; Reject arbitrary Emacs command execution when a server exposes it.
        (dolist (command (q/mcp-notebase--collect-values
                          args '(:command :function :symbol :fn)))
          (when (and (or (symbolp command) (stringp command))
                     (not (q/mcp-notebase--allowed-command-p command)))
            (error "MCP %s command is outside Org allowlist: %s" tool-name command))))))

  (defun q/mcp-notebase-call-tool-advice (fn connection tool-name args &rest rest)
    (q/mcp-notebase--validate-tool-args connection tool-name args)
    (apply fn connection tool-name args rest))

  (when (fboundp 'mcp-call-tool)
    (unless (advice-member-p #'q/mcp-notebase-call-tool-advice 'mcp-call-tool)
      (advice-add 'mcp-call-tool :around #'q/mcp-notebase-call-tool-advice)))
  (when (fboundp 'mcp-async-call-tool)
    (unless (advice-member-p #'q/mcp-notebase-call-tool-advice 'mcp-async-call-tool)
      (advice-add 'mcp-async-call-tool :around #'q/mcp-notebase-call-tool-advice))))

(use-package gptel-mcp
  :straight (:host github :repo "lizqwerscott/gptel-mcp.el" :files ("*.el"))
  :after (gptel mcp)
  :commands gptel-mcp-dispatch
  :bind (:map gptel-mode-map
              ("C-c m" . gptel-mcp-dispatch)))

(use-package vterm
  :commands vterm
  :bind ("C-c v" . vterm)
  :custom
  (vterm-max-scrollback 20000)
  :config
  (setq vterm-kill-buffer-on-exit t))

(provide 'init)
;;; init.el ends here
