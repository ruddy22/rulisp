;;; packages.lisp

;; (restas:define-plugin :rulisp
;;   (:use :cl :iter :rulisp.preferences)
;;   (:basepath (asdf:component-pathname (asdf:find-system :rulisp))))

(restas:defsite :rulisp
  (:use #:cl #:iter #:restas.optional #:rulisp.preferences)
  (:export #:code-to-html           
           #:substring
           #:username

           #:with-rulisp-db
           #:*re-email-check*

           #:send-mail
           #:send-noreply-mail
           
           #:form-error-message
           #:form-field-value
           #:form-field-empty-p
           #:fill-form
           
           #:staticpath
           #:user-theme
           #:skinpath
           #:tmplpath
           #:*rulisp-path*

           #:image

           #:rulisp-start
           ))

(restas:define-plugin #:rulisp.forum
  (:use #:cl #:iter #:restas.optional #:rulisp #:rulisp.preferences))

(restas:define-plugin #:rulisp.wiki
  (:use #:cl #:iter #:restas.optional #:rulisp #:rulisp.preferences))

(restas:define-plugin :rulisp.pcl
  (:use #:cl #:iter #:restas.optional #:rulisp #:rulisp.preferences))

(restas:define-plugin :rulisp.planet
  (:use #:cl #:iter #:restas.optional #:rulisp #:rulisp.preferences))

(restas:define-plugin :rulisp.format
  (:use :cl :iter #:restas.optional :rulisp))
