;;;-------------------------------------------------------------------
;;; @author erick@codemonkeylabs.de
;;; @copyright (C) 2014, 2015
;;; @doc
;;;     ETBX - LFE Include Extensions
;;; @end
;;; Created : 17.12.14 by Erick Gonzalez
;;;-------------------------------------------------------------------

(defmacro ::
  args
  "(:: key struct [default]) - Lookup key in associative structure"
  `(: etbx get_value ,@args))

(defmacro ->
  "(-> expr & forms) - Threads expr through the second element of the first"
  "form, repeating the process with the next form and so on"
  ((val)
   `,val)
  ((val . (cons (cons f args) rest))
   `(-> (,f ,val ,@args) ,@rest)))

(defmacro ->>
  "(->> expr & forms) - Threads expr through the trailing element of the first"
  "form, repeating the process with the next form and so on"
  ((val)
   `,val)
  ((val . (cons form rest))
   (let ((nform (++ form (list val))))
     `(->> ,nform ,@rest))))
