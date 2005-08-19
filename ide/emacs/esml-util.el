;; Copyright (C) 2005 Vesa Karvonen
;;
;; MLton is released under a BSD-style license.
;; See the file MLton-LICENSE for details.

(eval-when-compile
  (require 'cl))

;; Some general purpose Emacs Lisp utility functions

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;; workaround for incompatibility between GNU Emacs and XEmacs
(if (string-match "XEmacs" emacs-version)
    (defun esml-split-string (string separator)
      (split-string string separator t))
  (defun esml-split-string (string separator)
    (remove* "" (split-string string separator))))

;; workaround for incompatibility between GNU Emacs and XEmacs
(if (string-match "XEmacs" emacs-version)
    (defun esml-replace-regexp-in-string (str regexp rep)
      (replace-in-string str regexp rep t))
  (defun esml-replace-regexp-in-string (str regexp rep)
    (replace-regexp-in-string regexp rep str t t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'esml-util)
