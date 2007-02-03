;; Copyright (C) 2007 Vesa Karvonen
;;
;; MLton is released under a BSD-style license.
;; See the file MLton-LICENSE for details.

(require 'def-use-util)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Data records

(defalias 'def-use-pos (function cons))
(defalias 'def-use-pos-line (function car))
(defalias 'def-use-pos-col  (function cdr))
(defun def-use-pos< (lhs rhs)
  (or (< (def-use-pos-line lhs) (def-use-pos-line rhs))
      (and (equal (def-use-pos-line lhs) (def-use-pos-line rhs))
           (< (def-use-pos-col lhs) (def-use-pos-col rhs)))))

(defalias 'def-use-ref (function cons))
(defalias 'def-use-ref-src (function car))
(defalias 'def-use-ref-pos (function cdr))
(defun def-use-ref< (lhs rhs)
  (or (string< (def-use-ref-src lhs) (def-use-ref-src rhs))
      (and (equal (def-use-ref-src lhs) (def-use-ref-src rhs))
           (def-use-pos< (def-use-ref-pos lhs) (def-use-ref-pos rhs)))))

(defun def-use-sym (kind name ref &optional face)
  "Symbol constructor."
  (cons ref (cons name (cons kind face))))
(defalias 'def-use-sym-face (function cdddr))
(defalias 'def-use-sym-kind (function caddr))
(defalias 'def-use-sym-name (function cadr))
(defalias 'def-use-sym-ref (function car))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Def-use sources

(defun def-use-add-dus (title sym-at-ref sym-to-uses finalize &rest args)
  (push (cons args (cons sym-at-ref (cons sym-to-uses (cons title finalize))))
        def-use-dus-list)
  (def-use-show-dus-update))

(defun def-use-rem-dus (dus)
  (setq def-use-dus-list
        (remove dus def-use-dus-list))
  (def-use-dus-finalize dus)
  (def-use-show-dus-update))

(defun def-use-dus-sym-at-ref (dus ref)
  (apply (cadr dus) ref (car dus)))

(defun def-use-dus-sym-to-uses (dus sym)
  (apply (caddr dus) sym (car dus)))

(defun def-use-dus-title (dus)
  (apply (cadddr dus) (car dus)))

(defun def-use-dus-finalize (dus)
  (apply (cddddr dus) (car dus)))

(defvar def-use-dus-list nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Def-Use Sources -mode

(defconst def-use-show-dus-buffer-name "<:Def-Use Sources:>")

(defconst def-use-dus-mode-map
  (let ((result (make-sparse-keymap)))
    (mapc (function
           (lambda (key-command)
             (define-key result
               (read (car key-command))
               (cdr key-command))))
          `(("[(q)]"
             . ,(function def-use-kill-current-buffer))
            ("[(k)]"
             . ,(function def-use-show-dus-del))))
    result))

(define-derived-mode def-use-dus-mode fundamental-mode "Def-Use-DUS"
  "Major mode for browsing def-use sources."
  :group 'def-use-dus)

(defun def-use-show-dus ()
  "Show a list of def-use sources."
  (interactive)
  (let ((buffer (get-buffer-create "<:Def-Use Sources:>")))
    (with-current-buffer buffer
      (buffer-disable-undo)
      (setq buffer-read-only t)
      (def-use-dus-mode))
    (switch-to-buffer buffer))
  (def-use-show-dus-update))

(defun def-use-show-dus-update ()
  (let ((buffer (get-buffer def-use-show-dus-buffer-name)))
    (when buffer
      (with-current-buffer buffer
        (save-excursion
          (setq buffer-read-only nil)
          (goto-char 1)
          (delete-char (buffer-size))
          (insert "Def-Use Sources\n"
                  "\n")
          (mapc (function
                 (lambda (dus)
                   (insert (def-use-dus-title dus) "\n")))
                def-use-dus-list)
          (setq buffer-read-only t))))))

(defun def-use-show-dus-del ()
  "Kill the def-use source on the current line."
  (interactive)
  (let ((idx (- (count-lines 1 (point)) 3)))
    (when (and (<= 0 idx)
               (< idx (length def-use-dus-list)))
      (def-use-rem-dus (nth idx def-use-dus-list)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Queries

(defun def-use-sym-at-ref (ref)
  (when ref
    (loop for dus in def-use-dus-list do
      (let ((it (def-use-dus-sym-at-ref dus ref)))
        (when it (return it))))))

(defun def-use-sym-to-uses (sym)
  (when sym
    (loop for dus in def-use-dus-list do
      (let ((it (def-use-dus-sym-to-uses dus sym)))
        (when it (return it))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'def-use-data)
