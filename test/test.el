;;; test.el --- tests for org-linkotron   -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'org-linkotron)

(defun stage-tests ()
  (find-file "test/test.org")
  (goto-char 0))

(defun group-compare (heading-name should-find)
  (should (search-forward heading-name nil t))
  (let ((found (org-linkotron--get-positions)))
    (should (cl-every '= found should-find))))

(ert-deftest org-linkotron-test-group-0 ()
  (stage-tests)
  (group-compare "* group 0" '(23 62 101 140)))

(ert-deftest org-linkotron-test-group-1 ()
  (stage-tests)
  (group-compare "* group 1" '(190 229 268)))

(ert-deftest org-linkotron-test-group-2 ()
  (stage-tests)
  (group-compare "* group 2" '(319 358 397)))
