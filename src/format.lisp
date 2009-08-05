;;; format.lisp

(in-package :rulisp)

(defun formater-menu ()
  (xfactory:with-element-factory ((E))
    (E :div
       (eid "second-menu")
       (E :ul
          (E :li
             (E :a
                (ehref 'format-main)
                "Все записи"))
          (E :li
             (E :a
                (ehref 'newformat)
                "Создать"))))))

(define-simple-route chrome-formater-menu ("formater/topmenu"
                                           :protocol :chrome)
  (xtree:with-object (el (formater-menu))
    (xtree:serialize el :to-string)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun format-nav-panel (start end all &key (step 20))
  (let ((url (genurl 'format-main)))
    (xfactory:with-element-factory ((E))
      (E :div
         (xfactory:attributes :class "item-nav-panel"
                              :align "right")
         (E :span
            (estrong "~A" (1+ start))         
            " - "
            (estrong "~A" (min end all))
            " из "
            (estrong "~A" all)
            " « "
            (if (> start 0)
                (E :a
                   (if (> start step)
                       (ehref "~A?start=~A" url (- start step))
                       (ehref url))
                   "Позже")
                (xfactory:text "Позже"))
            " | "
            (if (< (+ start step) all)
                (E :a
                   (ehref "~A?start=~A" url (+ start step))
                   "Раньше")
                (xfactory:text "Раньше"))
            " » ")))))

(postmodern:defprepared select-formats*
  "SELECT f.format_id, u.login, f.title, to_char(f.created, 'DD.MM.YYYY HH24:MI') FROM formats AS f
    LEFT JOIN users AS u USING (user_id)
    ORDER BY f.created DESC
    LIMIT $2 OFFSET $1")

(defun select-formats (start &optional (limit 10))
  (select-formats* start limit))

(define-simple-route format-main ("apps/format/all"
                                  :overlay-master *master*)
  (let* ((start* (hunchentoot:get-parameter "start"))
         (start (if start*
                    (parse-integer start*)
                    0))
         (items (with-rulisp-db
                  (select-formats start)))
         (all (with-rulisp-db
                (postmodern:query "SELECT count(*) FROM formats" :single))))
    (in-pool
     (xfactory:with-document-factory ((E))
       (E :overlay
          (E :div
             (eid "content")
             (formater-menu)
             (format-nav-panel start (+ start (length items)) all :step 10)
             (iter (for (format-id author title created) in items)
                   (E :div
                      (eclass "item")
                      (E :a
                         (ehref 'view-format-code :format-id format-id)
                         (xfactory:text (if (string= title "")
                                            "*notitle*"
                                            title)))
                      (E :div
                         (eclass "info")
                         (E :span
                            (eclass "info")
                            "Автор: "
                            (estrong "~A" author)
                            (xfactory:text " - ~A" created)))))))))))
                       


(define-simple-route newformat ("apps/format/"
                               :overlay-master *master*)
  (tmplpath "format.xml"))

(postmodern:defprepared db-new-format-code "SELECT * FROM add_format_code($1, $2, $3)" :single)
  
(define-simple-route newformat/post ("apps/format/"
                                    :method :post
                                    :overlay-master *master*)
  (if (hunchentoot:post-parameter "preview")
      (let* ((doc (in-pool (xtree:parse (tmplpath "format.xml"))))
             (form (xpath:find-single-node doc "//form")))
        (fill-form doc (hunchentoot:post-parameters*))
        (let ((xfactory:*node* (xtree:insert-child-before (xtree:make-element "div")  form)))
          (xfactory:with-element-factory ((E))
            (E :div
               (eclass "preview")
               (E :h3
                  "Предварительный просмотр")
               (E :pre
                  (eclass "code")
                  (e-text2html (code-to-html (hunchentoot:post-parameter "code")))))))
        (when (username)
          (let ((xfactory:*node* form))
            (xfactory:with-element-factory ((E))
              (E :div
                 (eclass "format-save")
                 (estrong "Описание: ")
                 (E :input
                    (xfactory:attributes :type "text"
                                         :name "title"
                                         :size 60))
                 (e-break-line)
                 (e-break-line)
                 (E :input
                    (xfactory:attributes :type "submit"
                                         :value "Сохранить"))))))
        doc)
      (if (username)
          (let ((title (hunchentoot:post-parameter "title"))
                (code (hunchentoot:post-parameter "code")))
            (if (and code
                     (not (string= code "")))
                (redirect 'view-format-code
                          :format-id (with-rulisp-db
                                       (db-new-format-code (username) title code)))
                (tmplpath "format.xml")))
          hunchentoot:+HTTP-FORBIDDEN+)))


(postmodern:defprepared get-format-code
    "SELECT u.login, f.title, f.code, to_char(f.created, 'DD.MM.YYYY HH24:MI') FROM formats AS f
     LEFT JOIN users AS u USING (user_id)
     WHERE format_id = $1"
  :row)

(define-simple-route view-format-code ("apps/format/:(format-id)"
                                       :overlay-master *master*)
  (let ((row (with-rulisp-db (get-format-code format-id))))
    (if row
        (in-pool
         (xfactory:with-document-factory ((E))
           (E :overlay
              (E :head
                 (E :title
                    (xfactory:text "Форматтер: ~A"
                                   (let ((title (second row)))
                                     (if (string= title "")
                                         "Безымянный код"
                                         title)))))
              (E :div
                 (eid "content")
                 (formater-menu)
                 (estrong (second row))
                 (e-break-line)
                 (E :span
                    (eclass "info")
                    "Автор: "
                    (estrong "~A"  (first row))
                    (xfactory:text " - ~A" (fourth row)))
                 (E :pre
                    (eclass "code")
                    (e-text2html (code-to-html (third row))))))))
        hunchentoot:+HTTP-NOT-FOUND+)))