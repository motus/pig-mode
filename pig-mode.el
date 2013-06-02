;;; pig-mode.el -- Major mode for Pig files

;; Software License Agreement (BSD License)
;;
;; Copyright (c) 2009 Sergei Matusevich <sergei.matusevich@gmail.com>
;; All rights reserved.
;;
;; Maintainer: David A. Shamma
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;; 3. The name of the author may not be used to endorse or promote products
;;    derived from this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
;; IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
;; OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
;; IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
;; INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
;; NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
;; THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:

;; pig-mode is an Emacs major mode for editing Pig scripts. Currently it
;; supports syntax highlighting and indentation for Pig versions 0.2 to
;; 0.10. We track the changes to Pig syntax and try to support new Pig
;; features ASAP.

;;; Installation:

;; Put this file into your Emacs lisp path (eg. site-lisp)
;; and add the following line to your ~/.emacs file:
;;
;;   (require 'pig-mode)

;;; Code:

(require 'font-lock)
(require 'comint)

(defgroup pig nil
  "Syntax highlighting and inferior-process interaction for Apache Pig"
  :link '(url-link "https://github.com/motus/pig-mode")
  :prefix "pig-"
  :group 'external)

(defcustom pig-executable "pig"
  "Process to invoke.  May be fully-qualified."
  :group 'pig
  :type '(string))

(defcustom pig-executable-options '("-x" "local")
  "Command line options to pass to the executable."
  :group 'pig
  :type '(list string))

(defcustom pig-executable-prompt-regexp "^grunt> "
  "Regular expression for the inferior-process prompt"
  :group 'pig
  :type '(regexp))

(defcustom pig-inferior-process-buffer "*pig*"
  "Name of the buffer containing the running process."
  :group 'pig
  :type '(string))


(defvar pig-mode-hook nil)

(defvar pig-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "RET") 'newline-and-indent)
    keymap)
  "Keymap for pig major mode")

(add-to-list 'auto-mode-alist '("\\.pig\\'" . pig-mode))

(defconst pig-font-lock-keywords
  `((,(regexp-opt
       '("COGROUP"
         "CROSS"
         "DEFINE"
         "DISTINCT"
         "FILTER"
         "FOREACH"
         "GROUP"
         "IMPORT"
         "JOIN"
         "LIMIT"
         "LOAD"
         "MAPREDUCE"
         "ORDER" "BY"
         "SAMPLE"
         "SPLIT"
         "STORE"
         "STREAM" "THROUGH"
         "UNION"
         "ARRANGE"
         "INTO"
         "IF" "ALL" "ANY" "AS"  "USING" "INNER" "OUTER" "PARALLEL"
         "CONTINUOUSLY" "WINDOW" "TUPLES" "GENERATE" "EVAL"
         "INPUT" "OUTPUT" "SHIP" "CACHE" "FLATTEN"
         "SECONDS" "MINUTES" "HOURS" "ASC" "DESC" "LEFT" "RIGHT"
         "FULL"  "NULL" "AND" "OR" "NOT" "MATCHES" "IS"
         "DESCRIBE" "ILLUSTRATE" "DUMP")
       'words)
     (1 font-lock-keyword-face))

    ("^ *\\(REGISTER\\) *\\([^;]+\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-string-face))
    (,(concat
       (regexp-opt
        '(;; Eval Functions
          "AVG"
          "CONCAT"
          "COUNT"
          "COUNT_STAR"
          "DIFF"
          "IsEmpty"
          "MAX"
          "MIN"
          "SIZE"
          "SUM"
          "TOKENIZE"
          ;; Load/Store Functions
          "BinStorage"
          "JsonLoader"
          "JsonStorage"
          "PigDump"
          "PigStorage"
          "TextLoader"
          ;; Math Functions
          "ABS"
          "ACOS"
          "ASIN"
          "ATAN"
          "CBRT"
          "CEIL"
          "COS"
          "COSH"
          "EXP"
          "FLOOR"
          "LOG"
          "LOG10"
          "RANDOM"
          "ROUND"
          "SIN"
          "SINH"
          "SQRT"
          "TAN"
          "TANH"
          ;; String Functions
          "INDEXOF"
          "LAST_INDEX_OF"
          "LCFIRST"
          "LOWER"
          "REGEX_EXTRACT"
          "REGEX_EXTRACT_ALL"
          "REPLACE"
          "STRSPLIT"
          "SUBSTRING"
          "TRIM"
          "UCFIRST"
          "UPPER"
          ;; Tuple, Bag, Map Functions
          "TOTUPLE"
          "TOBAG"
          "TOMAP"
          "TOP")
        'words)
       "(")
     (1 font-lock-function-name-face))
    ("\\<\\([0-9]+[lL]\\|\\([0-9]+\\.?[0-9]*\\|\\.[0-9]+\\)\\([eE][-+]?[0-9]+\\)?[fF]?\\)\\>"
     . font-lock-constant-face)
    ("\\<$[0-9]+\\>" . font-lock-variable-name-face)
    (,(regexp-opt
       '(;; Simple Types
         "int" "long" "float" "double" "chararray" "bytearray" "boolean"
         ;; Complex Types
         "tuple" "bag" "map")
       'words)
     (1 font-lock-type-face)))
  "regexps to highlight in pig mode")

(defvar pig-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?_  "w"      st)
    (modify-syntax-entry ?-  ". 56"   st)
    (modify-syntax-entry ?-  ". 12b"  st)
    (modify-syntax-entry ?/  ". 1456" st)
    (modify-syntax-entry ?*  ". 23"   st)
    (modify-syntax-entry ?\n "> b"    st)
    (modify-syntax-entry ?\" "\""     st)
    (modify-syntax-entry ?\' "\""     st)
    (modify-syntax-entry ?\` "\""     st)
    st)
  "Syntax table for pig mode")

(defcustom pig-indent-level default-tab-width
  "*Indentation of pig statements."
  :type 'integer :group 'pig)
(put 'pig-indent-level 'safe-local-variable 'integerp)

(defun pig-indent-line ()
  "Indent current line as Pig code"
  (interactive)
  (indent-line-to (save-excursion
    (beginning-of-line)
    (if (looking-at ".*}[ \t]*;[ \t]*$")
        (pig-statement-indentation)
      (forward-line -1)
      (while (and (not (bobp)) (looking-at "^[ \t]*$"))
        (forward-line -1))
      (cond
       ((bobp) 0)
       ((looking-at "^[ \t]*--") (current-indentation))
       ((looking-at ".*;[ \t]*$") (pig-statement-indentation))
       (t (+ (pig-statement-indentation) pig-indent-level)))))))

(defun pig-statement-indentation ()
  (save-excursion
    (beginning-of-line)
    (cond
     ((bobp) 0)
     ((looking-at ".*\\(}[ \t]*;\\|)\\)[ \t]*$")
      (end-of-line)
      (backward-list)
      (pig-statement-indentation) )
     ((search-backward-regexp "[{;][ \t]*$" nil t)
      (forward-line 1)
      (beginning-of-line)
      (while (and (looking-at "^[ \t]*\\(--.*\\)?$")
                  (save-excursion (end-of-line) (not (eobp))))
        (forward-line 1))
      (current-indentation))
     (t 0))))

(define-derived-mode pig-mode fundamental-mode "pig"
  "Major mode for editing Yahoo! .pig files"
  :syntax-table pig-mode-syntax-table
  (set (make-local-variable 'font-lock-defaults)
       '(pig-font-lock-keywords nil t))
  (set (make-local-variable 'indent-line-function) 'pig-indent-line)
  (set (make-local-variable 'comment-start) "-- ")
  (set (make-local-variable 'comment-end) ""))

;;; Interaction:

(defun pig-is-running-p ()
  (comint-check-proc pig-inferior-process-buffer))

(defun pig-pop-to-buffer ()
  "Switch to the running pig process associated with the current buffer."
  (interactive)
  (pop-to-buffer pig-inferior-process-buffer))

(defun pig-eval-region (start end)
   "Evaluate the region between START and END with pig."
   (interactive "r")
   (unless (pig-is-running-p)
     (pig-run-pig))
   (comint-send-region pig-inferior-process-buffer start end)
   (comint-send-string pig-inferior-process-buffer "\n"))

(defun pig-eval-line ()
  "Evaluate the current line with pig."
  (interactive)
  (pig-eval-region (save-excursion (move-beginning-of-line nil) (point))
                   (save-excursion (move-end-of-line nil) (point))))

(defun pig-eval-buffer ()
  "Evaluate the current buffer with pig."
  (interactive)
  (pig-eval-region (point-min) (point-max)))

(define-derived-mode inferior-pig-mode comint-mode "Pig"
  "Interact with a PIG process through Emacs."
  (setq comint-prompt-regexp "^grunt>")
  (setq comint-use-prompt-regexp t)
  (setq comint-prompt-read-only t))

(defun pig-run-pig ()
  "Start an inferior pig REPL."
  (interactive)
  (unless (pig-is-running-p)
    (with-current-buffer
        (apply 'make-comint-in-buffer "Pig" pig-inferior-process-buffer
               pig-executable nil
               pig-executable-options)
      (inferior-pig-mode)))
  (when (called-interactively-p 'any)
    (pig-pop-to-buffer)))

(defvar pig-interaction-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-r") 'pig-eval-region)
    (define-key map (kbd "C-l") 'pig-eval-line)
    (define-key map (kbd "C-b") 'pig-eval-buffer)
    (define-key map (kbd "C-z") 'pig-run-pig)
    map))

(define-key pig-mode-map (kbd "C-c") pig-interaction-map)

(provide 'pig-mode)

;;; end of pig-mode.el
