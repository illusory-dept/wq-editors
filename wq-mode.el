;;; wq-mode.el --- Major mode for editing wq scripts -*- lexical-binding: t -*-

;; Author: mtx@nekoarch.cc
;; Version: 0.2.0
;; Keywords: languages
;; Package-Requires: ((emacs "24.4"))

;; TODOs:
;; send-region
;; send-buffer

;;; Code:
(require 'cl-lib)
(require 'comint)

(defvar wq-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\( "()" st)
    (modify-syntax-entry ?\) ")(" st)
    (modify-syntax-entry ?\[ "(]" st)
    (modify-syntax-entry ?\] ")[" st)
    (modify-syntax-entry ?\n ">" st)
    st)
  "Syntax table for `wq-mode'.")

(defvar wq-font-lock-keywords
  (let* ((builtins '("abs" "neg" "signum" "sqrt" "exp" "ln"
                     "floor" "ceiling"
                     "count" "first" "last" "reverse" "sum" "max" "min" "avg"
                     "rand" "sin" "cos" "tan" "sinh" "cosh" "tanh"
                     "til" "range" "take" "drop" "where" "distinct" "sort"
                     "cat" "flatten" "load"
                     "and" "or" "not" "xor"
                     "type" "string" "symbol" "echo" "showt" "exec"))
         (constants '("true" "false" "null")))
    `(
      ("\\_<\\([A-Za-z][A-Za-z0-9_]*\\):" 1 font-lock-variable-name-face)
      (,(concat "\\_<" (regexp-opt builtins t) "\\_>") . font-lock-keyword-face)
      (,(concat "\\_<" (regexp-opt constants t) "\\_>") . font-lock-constant-face)
      ("\\_<[+-]?[0-9]+\\(?:\\.[0-9]+\\)?\\_>" . font-lock-constant-face)
      ("`[A-Za-z_][A-Za-z0-9_]*" . font-lock-variable-name-face)
      ("\"[^\"]*\"" . font-lock-string-face)
      ("//.*$" . font-lock-comment-face)
      )))

(defun wq-indent-line ()
  "Indent current line in `wq-mode'."
  (interactive)
  (let ((indent-level 0))
    (save-excursion
      (beginning-of-line)
      (when (looking-at "^[ \t]*[])]")
        (setq indent-level
              (- (current-indentation) default-tab-width)))
      (unless (> indent-level 0)
        (forward-line -1)
        (setq indent-level (current-indentation))))
    (when (< indent-level 0)
      (setq indent-level 0))
    (indent-line-to indent-level)))

(defgroup inferior-wq nil
  "Run an inferior wq REPL in Emacs."
  :group 'applications)

(defcustom inferior-wq-program "wq"
  "Path to the `wq` executable."
  :type 'string
  :group 'inferior-wq)

(defvar inferior-wq-buffer nil
  "The current `*wq*` REPL buffer.")

(defun wq--comint-init ()
  "Hook to run when starting `inferior-wq-mode`."
  (setq comint-process-echoes t))

(define-derived-mode inferior-wq-mode comint-mode "Inferior wq"
  "Major mode for interacting with an inferior wq process."
  :syntax-table wq-mode-syntax-table
  (setq-local comint-prompt-regexp "^\\([0-9]+\\) wq\\$ ")
  (setq-local comint-input-sender-no-newline nil)
  (add-hook 'comint-output-filter-functions #'comint-postoutput-scroll-to-bottom nil t)
  (add-hook 'inferior-wq-mode-hook #'wq--comint-init))

;;;###autoload
(defun wq-run-repl ()
  "Run an inferior wq REPL in Emacs."
  (interactive)
  (unless (comint-check-proc "*wq*")
    (let ((buf (apply 'make-comint
                      "wq" inferior-wq-program nil nil)))
      (with-current-buffer buf
        (inferior-wq-mode))
      (setq inferior-wq-buffer buf)))
  (pop-to-buffer "*wq*"))

;;;###autoload
(define-derived-mode wq-mode prog-mode "wq"
  "Major mode for editing wq (a tiny APL‑like) scripts."
  :syntax-table wq-mode-syntax-table

  (setq-local comment-start   "// ")
  (setq-local comment-end     "")
  (setq-local comment-start-skip "//+\\s-*")

  (setq-local syntax-propertize-function
              (syntax-propertize-rules
               ("//" (0 "<"))))
  (syntax-propertize (point-max))
  (setq-local font-lock-defaults '(wq-font-lock-keywords))
  (setq-local indent-line-function #'wq-indent-line))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.wq\\'" . wq-mode))

(with-eval-after-load 'wq-mode
  (define-key wq-mode-map (kbd "C-c C-z") #'wq-run-repl))

(provide 'wq-mode)
;;; wq-mode.el ends here
