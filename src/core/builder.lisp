#|
  This file is a part of Clack package.
  URL: http://github.com/fukamachi/clack
  Copyright (c) 2011 Eitarow Fukamachi <e.arrows@gmail.com>

  Clack is freely distributable under the LLGPL License.
|#

(in-package :cl-user)
(defpackage clack.builder
  (:use :cl)
  (:import-from :alexandria
                :ensure-list)
  (:import-from :clack.component
                :call)
  (:import-from :clack.middleware
                :wrap)
  (:import-from :clack.middleware.conditional
                :<clack-middleware-conditional>))
(in-package :clack.builder)

(cl-syntax:use-syntax :annot)

@export
(defvar *builder-lazy-p* nil
  "Flag whether using lazy building.
If t, build up for each HTTP request.
This is useful in development phase.")

(defun %builder (&rest app-or-middleware)
  "Wrap Clack application with middlewares and return it as one function."
  `(reduce #'wrap
           (delete nil
                   (list ,@(loop for item in (butlast app-or-middleware)
                                 for (class . args) = (ensure-list item)
                                 if (eq class :condition)
                                   collect `(make-instance '<clack-middleware-conditional>
                                                           :condition ,@args)
                                 else if (and (symbolp class) (find-class class nil))
                                        collect `(make-instance ',class ,@args)
                                 else
                                   collect `(,class ,@args)))
                   :test #'eq)
           :initial-value ,(car (last app-or-middleware))
           :from-end t))

@export
(defmacro builder (&rest app-or-middleware)
  "Some Middleware and Applications reduce into one function."
  `(if *builder-lazy-p*
       (builder-lazy ,@app-or-middleware)
       ,(apply #'%builder app-or-middleware)))

@export
(defmacro builder-lazy (&rest app-or-middleware)
  "Some Middleware and Applications reduce into one function. This evals given Components in each HTTP request time."
  (let ((env (gensym "ENV")))
    `(lambda (,env) (call (eval ',(apply #'%builder app-or-middleware)) ,env))))

(doc:start)

@doc:NAME "
Clack.Builder - Clack utility to build up from some Middleware and Application into one function.
"

@doc:SYNOPSIS "
    (builder
     <clack-middleware-logger>
     (<clack-middleware-static>
      :path \"/public/\"
      :root #p\"/static-files/\")
     app)
"

@doc:DESCRIPTION "
Clack.Builder allows you to write middlewares inline. It builds up with calling `wrap' of middlewares sequencially and returns a function also as an Application.

The following example is:

    (builder
     <clack-middleware-logger>
     (<clack-middleware-static>
      :path \"/public/\"
      :root #p\"/static-files/\")
     app)

same as below one.

    (wrap (make-instance '<clack-middleware-logger>)
          (wrap (make-instance '<clack-middleware-static>
                   :path \"/public/\"
                   :root #p\"/static-files/\")
                app))

`builder-lazy' is almost same as `builder', but it builds up every time when the Application calls.
"

@doc:AUTHOR "
* Eitarow Fukamachi (e.arrows@gmail.com)
"

@doc:SEE "
* Clack.Middleware
"
