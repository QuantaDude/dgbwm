;; Remove help from C-h
(keymap-global-unset "C-h")

(global-set-key (kbd "C-h") #'windmove-left)
(global-set-key (kbd "C-l") #'windmove-right)
(global-set-key (kbd "C-k") #'windmove-up)
(global-set-key (kbd "C-j") #'windmove-down)


(global-set-key (kbd "C-c h") #'help-command)

(setq package-enable-at-startup nil)
