;; Copyright (C) 2007 Vesa Karvonen
;;
;; MLton is released under a BSD-style license.
;; See the file MLton-LICENSE for details.

(require 'def-use-mode)
(require 'bg-job)
(require 'esml-util)

;; XXX Keep a set of files covered by a def-use file.  Don't reload unnecessarily.
;; XXX Poll periodically for modifications to def-use files.
;; XXX Detect when the same ref is both a use and a def and act appropriately.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Interface

(defun esml-du-mlton (duf)
  "Gets def-use information from a def-use file produced by MLton."
  (interactive "fSpecify def-use -file: ")
  (let ((ctx (esml-du-ctx (def-use-file-truename duf))))
    (esml-du-parse ctx)
    (def-use-add-dus
      (function esml-du-title)
      (function esml-du-sym-at-ref)
      (function esml-du-sym-to-uses)
      (function esml-du-finalize)
      ctx)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Move to symbol

(defun esml-du-move-to-symbol-start ()
  "Moves to the start of the SML symbol at point."
  (let ((limit (def-use-point-at-current-line)))
    (when (zerop (skip-chars-backward esml-sml-alphanumeric-chars limit))
      (skip-chars-backward esml-sml-symbolic-chars limit))))

(add-to-list 'def-use-mode-to-move-to-symbol-start-alist
             (cons 'sml-mode (function esml-du-move-to-symbol-start)))

(defun esml-du-move-to-symbol-end ()
  "Moves to the end of the SML symbol at point."
  (let ((limit (def-use-point-at-next-line)))
    (when (zerop (skip-chars-forward esml-sml-alphanumeric-chars limit))
      (skip-chars-forward esml-sml-symbolic-chars limit))))

(add-to-list 'def-use-mode-to-move-to-symbol-end-alist
             (cons 'sml-mode (function esml-du-move-to-symbol-end)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Methods

(defun esml-du-title (ctx)
  (concat
   (esml-du-ctx-duf ctx)
   " ["
   (if (esml-du-ctx-buf ctx)
       (concat "parsing: "
               (int-to-string
                (truncate
                 (/ (buffer-size (esml-du-ctx-buf ctx))
                    0.01
                    (nth 7 (esml-du-ctx-attr ctx)))))
               "% left")
     "complete")
   "]"))

(defun esml-du-sym-at-ref (ref ctx)
  (if (def-use-attr-newer?
        (file-attributes (def-use-ref-src ref))
        (esml-du-ctx-attr ctx))
      (esml-du-reparse ctx)
    (unless (let ((buffer (def-use-find-buffer-visiting-file
                            (def-use-ref-src ref))))
              (and buffer (buffer-modified-p buffer)))
      (gethash ref (esml-du-ctx-ref-to-sym-table ctx)))))

(defun esml-du-sym-to-uses (sym ctx)
  (if (def-use-attr-newer?
        (file-attributes (def-use-ref-src (def-use-sym-ref sym)))
        (esml-du-ctx-attr ctx))
      (esml-du-reparse ctx)
    (gethash sym (esml-du-ctx-sym-to-uses-table ctx))))

(defun esml-du-finalize (ctx)
  (let ((buffer (esml-du-ctx-buf ctx)))
    (when buffer
      (kill-buffer buffer))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Context

(defun esml-du-ctx (duf)
  (cons (def-use-make-hash-table)
        (cons (def-use-make-hash-table)
              (cons duf
                    (cons nil nil)))))

(defalias 'esml-du-ctx-buf               (function cddddr))
(defalias 'esml-du-ctx-attr              (function cadddr))
(defalias 'esml-du-ctx-duf               (function caddr))
(defalias 'esml-du-ctx-ref-to-sym-table  (function cadr))
(defalias 'esml-du-ctx-sym-to-uses-table (function car))

(defun esml-du-ctx-set-buf  (buf  ctx) (setcdr (cdddr ctx) buf))
(defun esml-du-ctx-set-attr (attr ctx) (setcar (cdddr ctx) attr))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Parsing

(defun esml-du-read (taking skipping)
  (let ((start (point)))
    (skip-chars-forward taking)
    (let ((result (buffer-substring start (point))))
      (skip-chars-forward skipping)
      result)))

(defconst esml-du-classes ;; XXX Needs customization
  `((,(def-use-intern "variable")    . ,font-lock-variable-name-face)
    (,(def-use-intern "type")        . ,font-lock-variable-name-face)
    (,(def-use-intern "constructor") . ,font-lock-variable-name-face)
    (,(def-use-intern "structure")   . ,font-lock-variable-name-face)
    (,(def-use-intern "signature")   . ,font-lock-variable-name-face)
    (,(def-use-intern "functor")     . ,font-lock-variable-name-face)
    (,(def-use-intern "exception")   . ,font-lock-variable-name-face)))

(defun esml-du-reparse (ctx)
  (cond
   ((not (def-use-attr-newer?
           (file-attributes (esml-du-ctx-duf ctx))
           (esml-du-ctx-attr ctx)))
    nil)
   ((not (esml-du-ctx-buf ctx))
    (esml-du-parse ctx)
    nil)
   (t
    (esml-du-finalize ctx)
    (run-with-idle-timer 0.5 nil (function esml-du-reparse) ctx)
    nil)))

(defun esml-du-parse (ctx)
  "Parses the def-use -file.  Because parsing may take a while, it is
done as a background process.  This allows you to continue working
altough the editor may feel a bit sluggish."
  (esml-du-ctx-set-attr (file-attributes (esml-du-ctx-duf ctx)) ctx)
  (esml-du-ctx-set-buf
   (generate-new-buffer (concat "** " (esml-du-ctx-duf ctx) " **")) ctx)
  (with-current-buffer (esml-du-ctx-buf ctx)
    (buffer-disable-undo)
    (insert-file (esml-du-ctx-duf ctx))
    (setq buffer-read-only t)
    (goto-char 1)
    (def-use-add-local-hook
     'kill-buffer-hook
     (lexical-let ((ctx ctx))
       (function
        (lambda ()
          (esml-du-ctx-set-buf nil ctx))))))
  (clrhash (esml-du-ctx-ref-to-sym-table ctx))
  (clrhash (esml-du-ctx-sym-to-uses-table ctx))
  (garbage-collect)
  (bg-job-start
   (function
    (lambda (ctx)
      (let ((buffer (esml-du-ctx-buf ctx)))
        (or (not buffer)
            (with-current-buffer buffer
              (eobp))))))
   (function
    (lambda (ctx)
      (with-current-buffer (esml-du-ctx-buf ctx)
        (goto-char 1)
        (let* ((ref-to-sym (esml-du-ctx-ref-to-sym-table ctx))
               (sym-to-uses (esml-du-ctx-sym-to-uses-table ctx))
               (class (def-use-intern (esml-du-read "^ " " ")))
               (name (def-use-intern (esml-du-read "^ " " ")))
               (src (def-use-file-truename (esml-du-read "^ " " ")))
               (line (string-to-int (esml-du-read "^." ".")))
               (col (1- (string-to-int (esml-du-read "^\n" "\n"))))
               (pos (def-use-pos line col))
               (ref (def-use-ref src pos))
               (sym (def-use-sym class name ref
                      (cdr (assoc class esml-du-classes))))
               (uses nil))
          (puthash ref sym ref-to-sym)
          (while (< 0 (skip-chars-forward " "))
            (let* ((src (def-use-file-truename (esml-du-read "^ " " ")))
                   (line (string-to-int (esml-du-read "^." ".")))
                   (col (1- (string-to-int (esml-du-read "^\n" "\n"))))
                   (pos (def-use-pos line col))
                   (ref (def-use-ref src pos)))
              (puthash ref sym (esml-du-ctx-ref-to-sym-table ctx))
              (push ref uses)))
          (puthash sym uses sym-to-uses))
        (setq buffer-read-only nil)
        (delete-backward-char (- (point) 1))
        (setq buffer-read-only t))))
   (function
    (lambda (ctx)
      (esml-du-finalize ctx)
      (message "Finished parsing %s." (esml-du-ctx-duf ctx))))
   ctx)
  (message "Parsing %s in the background..." (esml-du-ctx-duf ctx)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'esml-du-mlton)
