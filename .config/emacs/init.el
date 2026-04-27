(setq visible-bell t)
(tool-bar-mode 0)
(scroll-bar-mode 0)
(menu-bar-mode 0)
(global-display-line-numbers-mode 1)
;;(meow-global-mode 1)

;;(load-theme 'gruvbox-dark-medium' t)


(org-babel-load-file (expand-file-name "config.org" user-emacs-directory))

