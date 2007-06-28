;; Copyright (C) 2007 Vesa Karvonen
;;
;; MLton is released under a BSD-style license.
;; See the file MLton-LICENSE for details.

(require 'cl)
(require 'compat)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Utils

(defun bg-build-cons-once (entry list)
  (cons entry (remove* entry list :test (function equal))))

(defun bg-build-flatmap (fn list)
  (apply (function append) (mapcar fn list)))

(defun bg-build-remove-from-assoc (alist key)
  (remove*
   nil alist
   :test (function
          (lambda (_ key-value)
            (equal key (car key-value))))))

(defun bg-build-replace-in-assoc (alist key value)
  (cons (cons key value)
        (bg-build-remove-from-assoc alist key)))

(defun bg-build-assoc-cdr (key alist)
  "Same as (cdr (assoc key alist)) except that doesn't attempt to call cdr
on nil."
  (let ((key-value (assoc key (cdr alist))))
    (when key-value
      (cdr key-value))))

(defun bg-build-const (value)
  "Returns a function that returns the given value."
  (lexical-let ((value value))
    (lambda (&rest _)
      value)))

(defun bg-build-kill-current-buffer ()
  "Kills the current buffer."
  (interactive)
  (kill-buffer (current-buffer)))

(defun bg-build-make-hash-table ()
  "Makes a hash table with `equal' semantics."
  (make-hash-table :test 'equal :size 1))

(defun bg-build-point-at-current-line ()
  "Returns point at the beginning of the current line."
  (save-excursion
    (beginning-of-line)
    (point)))

(defun bg-build-current-line ()
  "Returns the current line number counting from 1."
  (+ 1 (count-lines 1 (bg-build-point-at-current-line))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'bg-build-util)
