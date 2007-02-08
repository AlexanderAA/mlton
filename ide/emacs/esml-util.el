;; Copyright (C) 2005 Vesa Karvonen
;;
;; MLton is released under a BSD-style license.
;; See the file MLton-LICENSE for details.

(require 'cl)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SML metadata

(defconst esml-sml-symbolic-chars "-!%&$#+/:<=>?@~`^|*\\"
  "A string of all Standard ML symbolic characters as defined in section
2.4 of the Definition.")

(defconst esml-sml-alphanumeric-chars
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'_"
  "A string of all Standard ML alphanumeric characters as defined in
section 2.4 of the Definition.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Some general purpose Emacs Lisp utility functions

(defun esml-point-preceded-by (regexp)
  "Determines whether point is immediately preceded by the given regexp.
If the result is non-nil, the regexp match data will contain the
corresponding match. As with `re-search-backward' the beginning of the
match is as close to the starting point as possible. The end of the match
is always the same as the starting point."
  (save-excursion
    (let ((limit (point))
          (start (re-search-backward regexp 0 t)))
      (when start
        (re-search-forward regexp limit t)
        (= limit (match-end 0))))))

(defun esml-insert-or-skip-if-looking-at (str)
  "Inserts the specified string unless it already follows the point. The
point is moved to the end of the string."
  (if (string= str
               (buffer-substring (point)
                                 (min (+ (point) (length str))
                                      (point-max))))
      (forward-char (length str))
    (insert str)))

(defun esml-split-string (string separator)
  (remove* "" (split-string string separator) :test 'equal))

;; workaround for incompatibility between GNU Emacs and XEmacs
(if (string-match "XEmacs" emacs-version)
    (defun esml-replace-regexp-in-string (str regexp rep)
      (replace-in-string str regexp rep t))
  (defun esml-replace-regexp-in-string (str regexp rep)
    (replace-regexp-in-string regexp rep str t t)))

;; workaround for incompatibility between GNU Emacs and XEmacs
(if (string-match "XEmacs" emacs-version)
    (defun esml-error (str &rest objs)
      (error 'error (concat "Error: " (apply (function format) str objs) ".")))
  (defalias 'esml-error (function error)))

(defun esml-string-matches-p (regexp str)
  "Non-nil iff the entire string matches the regexp."
  (and (string-match regexp str)
       (= 0 (match-beginning 0))
       (= (length str) (match-end 0))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'esml-util)
