;; Copyright (c) 2003 Nikodemus Siivola
;; 
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;; 
;; The above copyright notice and this permission notice shall be included
;; in all copies or substantial portions of the Software.
;; 
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
;; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
;; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
;; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

(in-package :osicat-test)

(deftest current-directory.1
    (let ((old (current-directory)))
      (unwind-protect
	   (progn
	     (setf (current-directory) "/tmp/")
	     (equal (current-directory) (truename "/tmp/")))
	(setf (current-directory) old)))
  t)

(deftest delete-directory.1
    (let ((dir (merge-pathnames "delete-directory/" *test-dir*)))
      (ensure-directories-exist dir)
      (and (eq :directory (file-kind dir))
	   (delete-directory dir)
	   (null (file-kind dir))))
  t)

(deftest delete-directory.2
    (let* ((dir (merge-pathnames "delete-directory/" *test-dir*))
	   (file (merge-pathnames "file" dir)))
      (ensure-directories-exist dir)
      (ensure-file file)
      (and (eq :regular-file (file-kind file))
	   (eq :directory (file-kind dir))
	   (eq :error (handler-case (delete-directory dir)
			(error () :error)))))
  t)

(deftest environment.1
    (namestring (osicat::normpath (cdr (assoc "HOME" (environment)
					      :test #'equal))
				  t))
  #.(namestring (user-homedir-pathname)))

(deftest environment.2
    (unwind-protect
	 (progn
	   (setf (environment-variable 'test-variable) "TEST-VALUE")
	   (assoc "TEST-VARIABLE" (environment) :test #'equal))
      (makunbound-environment-variable 'test-variable))
  ("TEST-VARIABLE" . "TEST-VALUE"))

;; No-op test to ensure setf environment actually works.
(deftest environment.3
    (let ((old-env (environment)))
      (prog1 (setf (environment) nil)
	(setf (environment) old-env)))
  nil)

(deftest environment-variable.1
    (environment-variable 'test-variable)
  nil)

(deftest environment-variable.2
    (unwind-protect
	 (progn
	   (setf (environment-variable 'test-variable) 'test-value)
	   (environment-variable 'test-variable))
      (makunbound-environment-variable 'test-variable))
  "TEST-VALUE")

(deftest environment-variable.3
    (unwind-protect
	 (progn
	   (setf (environment-variable "test-variable") "test-value")
	   (environment-variable 'test-variable))
      (makunbound-environment-variable "test-variable"))
  nil)

(deftest environment-variable.4
    (unwind-protect
	 (progn
	   (setf (environment-variable "test-variable") "test-value")
	   (environment-variable "test-variable"))
      (makunbound-environment-variable "test-variable"))
  "test-value")

(deftest file-kind.1
    (file-kind *test-dir*)
  :directory)

(deftest file-kind.2
    (file-kind (make-pathname :name "does-not-exist" :defaults *test-dir*))
  nil)

(deftest file-kind.3
    (let* ((file (ensure-file "tmp-file"))
	   (link (ensure-link "tmp-link" :target file)))
      (unwind-protect
	   (file-kind link)
	(delete-file link)
	(delete-file file)))
  :symbolic-link)

(deftest file-kind.4
    (let ((file (ensure-file "tmp-file")))
      (unwind-protect
	   (file-kind file)
	(delete-file file)))
  :regular-file)

(deftest file-permissions.1
    (and (member :other-read (file-permissions "/tmp/"))
	 t)
  t)

(deftest file-permissions.2
    (let ((file (ensure-file "tmp-exec")))
      (unwind-protect
	   (and (not (member :user-exec (file-permissions file)))
		(push :user-exec (file-permissions file))
		(member :user-exec (file-permissions file))
		t)
	(delete-file file)))
  t)

(deftest make-link.1
    (let ((link (merge-pathnames "make-link-test-link" *test-dir*))
	  (file (ensure-file "tmp-file")))
      (unwind-protect
	   (progn
	     (make-link link :target file)
	     (namestring (read-link link)))
	(delete-file link)
	(delete-file file)))
  #.(namestring (merge-pathnames "tmp-file" *test-dir*)))

(deftest make-link.2
    (let ((link (merge-pathnames "make-link-test-link" *test-dir*))
	  (file (ensure-file "tmp-file")))
      (unwind-protect
	   (progn
	     (make-link link :target file)
	     (file-kind link))
	(delete-file file)
	(delete-file link)))
  :symbolic-link)
	 
(deftest maunbound-environment-variable.1
    (let ((old (environment-variable :path)))
      (unwind-protect
	   (and old
		(makunbound-environment-variable :path)
		(null (environment-variable :path))
		t)
	(setf (environment-variable :path) old)))
  t)

(deftest mapdir.1
    (let* ((dir (ensure-directories-exist 
		 (merge-pathnames "mapdir-test/" *test-dir*)))
	   (file1 (ensure-file "file1" dir))
	   (file2 (ensure-file "file2.txt" dir))
	   (subdir (ensure-directories-exist
		    (merge-pathnames "subdir/" dir))))
      (unwind-protect
	   (remove-if #'null (mapdir #'pathname-name dir))
	(delete-file file1)
	(delete-file file2)
	(delete-directory subdir)
	(delete-directory dir)))
  ("file1" "file2"))

(deftest mapdir.2
    (let* ((dir (ensure-directories-exist 
		 (merge-pathnames "mapdir-test/" *test-dir*)))
	   (file1 (ensure-file "file1" dir))
	   (file2 (ensure-file "file2.txt" dir))
	   (subdir (ensure-directories-exist
		    (merge-pathnames "subdir/" dir))))
      (unwind-protect
	   (mapdir #'namestring dir)
	(delete-file file1)
	(delete-file file2)
	(delete-directory subdir)
	(delete-directory dir)))
  ("file1" "file2.txt" "subdir/"))

(deftest mapdir.3
    (let* ((dir (ensure-directories-exist 
		 (merge-pathnames "mapdir-test/" *test-dir*)))
	   (file (ensure-file "foo" dir)))
      (unwind-protect
	   (let ((*default-directory-defaults* (truename "/tmp/")))
	     (mapdir (lambda (x) 
		       (pathname-directory (merge-pathnames x))) 
		     dir))
	(delete-file file)
	(delete-directory dir)))
  (#.(pathname-directory (merge-pathnames "mapdir-test/" *test-dir*))))

;; Test that directories of form foo.bar/ don't become foo/bar/.
(deftest mapdir.4
    (let* ((dir (ensure-directories-exist 
		 (merge-pathnames "mapdir-test.type/" *test-dir*))))
      (unwind-protect
	   (dolist (list (remove-if
			  #'null
			  (osicat:mapdir
			   (lambda (x) (pathname-directory x))
			   *test-dir*)))
	     (when (/= (length list) 2) (error "too many path elements.")))
	(delete-directory dir)))
  nil)

;; Test behavior in the case of an obviously incorrect username.
(deftest user-info.1
    (user-info "definitely_not_a_user!")
  nil)

;; Does this test still work in the case of su/sudo?  It should, I
;; think.
#+sbcl
(deftest user-info.2
    (let ((user-id (cdr (assoc :user-id (user-info (sb-posix:getuid))))))
      (equal user-id (sb-posix:getuid)))
  t)

;; Just get our home directory, and see if it exists.  I don't
;; think this will work 100% of the time, but it should for most
;; people testing the package; given that, would it be even better
;; to compare the value to (user-homedir-pathname)?
#+sbcl
(deftest user-info.3
    (let ((home (cdr (assoc :home (user-info (sb-posix:getuid))))))
      (file-kind home))
  :directory)

;; We'll go out on a limb and assume that not only does the root
;; account exist, but its home directory exists, as well.  Note
;; that this is unfortunately not always true.
(deftest user-info.4
    (let ((home (cdr (assoc :home (user-info "root")))))
      (file-kind home))
  :directory)
