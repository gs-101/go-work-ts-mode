;;; go-work-ts-mode.el --- tree-sitter support for Go workspace files -*- lexical-binding: t -*-

;; Author: Gabriel Santos
;; Version: 1.0.0
;; Package-Requires: ((emacs "29.1"))
;; URL: https://github.com/gs-101/go-work-ts-mode
;; Keywords: go languages tree-sitter

;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Tree-sitter mode for editing Go workspace files in GNU Emacs.

;;; Code:

(require 'treesit)
(require 'go-ts-mode)

;; go.work support.

(defvar go-work-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?/   ". 124b" table)
    (modify-syntax-entry ?\n  "> b"    table)
    table)
  "Syntax table for `go-work-ts-mode'.")

(defvar go-work-ts-mode--indent-rules
  `((gowork
     ((node-is ")") parent-bol 0)
     ((parent-is "replace_directive") parent-bol go-ts-mode-indent-offset)
     ((parent-is "use_directive") parent-bol go-ts-mode-indent-offset)
     ((go-work-ts-mode--in-directive-p) no-indent go-ts-mode-indent-offset)
     (no-node no-indent 0)))
  "Tree-sitter indent rules for `go-work-ts-mode'.")

(defun go-work-ts-mode--in-directive-p ()
  "Return non-nil if point is inside a directive.
When entering an empty directive or adding a new entry to one, no node
will be present meaning none of the indentation rules will match,
because there is no parent to match against.  This function determines
what the parent of the node would be if it were a node."
  (lambda (node _ _ &rest _)
    (unless (treesit-node-type node)
      (save-excursion
        (backward-up-list)
        (back-to-indentation)
        (pcase (treesit-node-type (treesit-node-at (point)))
          ("replace" t)
          ("use" t))))))

(defvar go-work-ts-mode--keywords
  '("go" "replace" "use")
  "go.work keywords for tree-sitter font-locking.")

(defvar go-work-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'gowork
   :feature 'bracket
   '((["(" ")"]) @font-lock-bracket-face)

   :language 'gowork
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'gowork
   :feature 'keyword
   `([,@go-work-ts-mode--keywords] @font-lock-keyword-face)

   :language 'gowork
   :feature 'operator
   '((["=>"]) @font-lock-warning-face))
  "Tree-sitter font-lock settings for `go-work-ts-mode'.")

;;;###autoload
(define-derived-mode go-work-ts-mode prog-mode "Go Work"
  "Major mode for editing go.work files, powered by tree-sitter."
  :group 'go
  :syntax-table go-work-ts-mode--syntax-table

  (when (treesit-ready-p 'gowork)
    (setq treesit-primary-parser (treesit-parser-create 'gowork))

    ;; Comments.
    (setq-local comment-start "// ")
    (setq-local comment-end "")
    (setq-local comment-start-skip (rx "//" (* (syntax whitespace))))

    ;; Indent.
    (setq-local indent-tabs-mode t
                treesit-simple-indent-rules go-work-ts-mode--indent-rules)

    ;; Font-lock.
    (setq-local treesit-font-lock-settings go-work-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                '((comment)
                  (keyword)
                  (number)
                  (bracket error operator)))

    (treesit-major-mode-setup)))

(if (treesit-ready-p 'gowork)
    (add-to-list 'auto-mode-alist '("/go\\.work\\'" . go-work-ts-mode)))

(provide 'go-work-ts-mode)

;;; go-work-ts-mode.el ends here
