;;; ui/modeline/config.el -*- lexical-binding: t; -*-

(use-package! doom-modeline
  :hook (after-init . doom-modeline-mode)
  :init
  (unless after-init-time
    ;; prevent flash of unstyled modeline at startup
    (setq-default mode-line-format nil))
  ;; We display project info in the modeline ourselves
  (setq projectile-dynamic-mode-line nil)
  ;; Set these early so they don't trigger variable watchers
  (setq doom-modeline-bar-width 3
        doom-modeline-github nil
        doom-modeline-mu4e nil
        doom-modeline-persp-name nil
        doom-modeline-minor-modes nil
        doom-modeline-major-mode-icon nil
        doom-modeline-buffer-file-name-style 'relative-from-project)

  ;; Fix modeline icons in daemon-spawned graphical frames. We have our own
  ;; mechanism for disabling all-the-icons, so we don't need doom-modeline to do
  ;; it for us. However, this may cause unwanted padding in the modeline in
  ;; daemon-spawned terminal frames. If it bothers you, you may prefer
  ;; `doom-modeline-icon' set to `nil'.
  (when (daemonp)
    (setq doom-modeline-icon t))
  :config
  ;; Fix an issue where these two variables aren't defined in TTY Emacs on MacOS
  (defvar mouse-wheel-down-event nil)
  (defvar mouse-wheel-up-event nil)

  (size-indication-mode +1) ; filesize in modeline
  (column-number-mode +1)   ; cursor column in modeline

  (add-hook 'doom-change-font-size-hook #'+modeline-resize-for-font-h)
  (add-hook 'doom-load-theme-hook #'doom-modeline-refresh-bars)

  (add-hook '+doom-dashboard-mode-hook #'doom-modeline-set-project-modeline)

  (when (or (featurep! :ui pretty-code +fira)
            (featurep! :ui pretty-code +iosevka))
    ;; Fix #1216 and seagle0128/doom-modeline#69: wrong icon displayed for
    ;; 'save' icon in modeline.
    (defadvice! +modeline-fix-font-conflict-with-ligatures-a (&rest args)
      :override #'doom-modeline-icon-material
      (when doom-modeline-icon
        (pcase (car args)
          ("save" (apply 'all-the-icons-faicon (cons "floppy-o" (plist-put (cdr args) :v-adjust -0.0575))))
          (other (apply 'all-the-icons-material args))))))

  (add-hook! 'magit-mode-hook
    (defun +modeline-hide-in-non-status-buffer-h ()
      "Show minimal modeline in magit-status buffer, no modeline elsewhere."
      (if (eq major-mode 'magit-status-mode)
          (doom-modeline-set-project-modeline)
        (hide-mode-line-mode))))

  ;; Remove unused segments & extra padding
  (doom-modeline-def-modeline 'main
    '(bar window-number matches buffer-info remote-host buffer-position selection-info)
    '(objed-state misc-info persp-name irc mu4e github debug input-method buffer-encoding lsp major-mode process vcs checker))

  (doom-modeline-def-modeline 'special
    '(bar window-number matches buffer-info-simple buffer-position selection-info)
    '(objed-state misc-info persp-name debug input-method irc buffer-encoding lsp major-mode process checker))

  (doom-modeline-def-modeline 'project
    '(bar window-number buffer-default-directory)
    '(misc-info mu4e github debug battery " " major-mode process))

  ;; Some functions modify the buffer, causing the modeline to show a false
  ;; modified state, so force them to behave.
  (defadvice! +modeline--inhibit-modification-hooks-a (orig-fn &rest args)
    :around #'ws-butler-after-save
    (with-silent-modifications (apply orig-fn args))))


;;
;; Extensions

(use-package! anzu
  :after-call isearch-mode)

(use-package! evil-anzu
  :when (featurep! :editor evil)
  :after-call evil-ex-start-search evil-ex-start-word-search evil-ex-search-activate-highlight)
