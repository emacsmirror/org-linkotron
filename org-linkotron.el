;;; org-linkotron.el --- Org-mode link selector   -*- lexical-binding: t; -*-

;; Author: Per Weijnitz <per.weijnitz@gmail.com>
;; Keywords: hypermedia, Org
;; URL: https://gitlab.com/perweij/org-linkotron
;; Version: 0.9
;; Package-Requires: ((emacs "26.1") (org "9.0"))

;; Copyright (C) 2019, Per Weijnitz, all rights reserved.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;
;;
;;
;;; Commentary:
;;
;; The purpose of this package is to provide a way to open a group of
;; org-links at once.  A group is defined as all org-links under a
;; heading/sub heading, no need to use any special layout or formatting.
;;
;; The motivation is that I usually have at least a couple of sites I need
;; to visit for any specific task, so opening them all at once saves me time.
;;
;; Links are opened via the standard org funktion ~org-open-at-point~.
;;
;;
;;; Installation:
;;
;; Evaluate the elisp source file in some manner.  If you like quelpa,
;; this line would also work in your init.el:
;;
;;   (when (not (require 'org-linkotron nil 'noerror))
;;     (quelpa '(org-linkotron :repo "perweij/org-linkotron" :fetcher gitlab)))
;;   (require 'org-linkotron)
;;
;;
;;; Usage:
;;
;; In an org-file, create a heading with some links in the text
;; below, for example:
;;
;;  ** Some links about something
;;  Here is a text with two links, here: [[https://www.fsf.org/][fsf]] and
;;  here: [[https://fsfe.org/][fsfe]].
;;  A final one: [[https://www.gnu.org/][gnu]].
;;  ** Another interesting link collection
;;   - [[https://en.wikipedia.org/wiki/Amiga_500][Amiga 500]]
;;   - [[https://en.wikipedia.org/wiki/Commodore_64][Commodore 64]]
;;
;; Now, just place the cursor on the relevant header or its text, and
;; invoke
;; org-linkotron-open-group
;;
;;
;;; Notes:
;;
;; Much of the project scaffolding was borrowed from alphapapa's org-super-agenda.
;;
;;
;;; License:
;;
;; Copyright (C) 2020, Per Weijnitz, all rights reserved.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/gpl-3.0.txt>
;;
;;
;;; Code:

(require 'org)

(defgroup org-linkotron nil "Org link batch opener"
  :prefix "org-linkotron-"
  :group 'convenience)

(defcustom org-linkotron-pause 1.0 "Sleep between each link opening.
Especially for web links, it seems nice to give
Firefox some time between each call, especially for slower
computers.  Specify the number of seconds to sleep here."
  :type '(float)
  :group "org-linkotron")

;; Borrowed most of this from https://orgmode.org/worg/org-hacks.html
(defun org-linkotron--back-to-heading ()
  "Go back to the current heading."
  (interactive)
  (forward-char) ; to get a match on the same line, if on a header
  (cond
   ((re-search-backward "^\*" nil t) (forward-line 1))
   (t (goto-char (point-min)))))

;; Borrowed most of this from https://orgmode.org/worg/org-hacks.html
(defun org-linkotron--forward-to-heading ()
  "Go forward to the next heading."
  (interactive)
  (cond
   ((re-search-forward "^\*" nil t) (end-of-line 0))
   (t (goto-char (point-max)))))

(defun org-linkotron--find-region ()
  "Return a region to search for links.
The region is returned as a list of the start point and the end point."
  (save-excursion
    (org-linkotron--back-to-heading)
    (let ((start (point)))
      (org-linkotron--forward-to-heading)
      (list start (point)))))

(defun org-linkotron--next-link ()
  "Search for the next org-link.
Returns nil if none is found."
  (if (re-search-forward "\\(\\[\\[.*?\\]\\[.*?\\]\\]\\)" nil t)
      (match-beginning 1)))

(defun org-linkotron--get-link-on-line (&rest may-step-line)
  "Return the nearest link following the current position.
If MAY-STEP-LINE is t, then allow search on the following line."
  (save-restriction
    (narrow-to-region (point) (line-end-position))
    (let ((link-pos (org-linkotron--next-link)))
      (or link-pos
          (if may-step-line
              (progn
                (widen)
                (forward-line);; FIXME: add error check
                (beginning-of-line)
                (org-linkotron--get-link-on-line)))))))

(defun org-linkotron--get-group ()
  "Return a list of points to the org-links found in the current (sub) heading region."
  (save-excursion
    (let ((region (org-linkotron--find-region)))
      (save-restriction
        (narrow-to-region (car region) (nth 1 region))
        (goto-char (car region))
        (let ((result '())
              (link (org-linkotron--get-link-on-line)))
          (while link
            (setq result (nconc result (list link)))
            (setq link (org-linkotron--get-link-on-line t)))
          result)))))

;;;###autoload
(defun org-linkotron-open-group ()
  "Open the org-links found in the current (sub) heading region."
  (interactive)
  (save-excursion
    (let* ((group (org-linkotron--get-group))
           (progress-reporter
            (make-progress-reporter "Opening links...")))
      (mapc (lambda (link)
              (progress-reporter-update progress-reporter)
              (goto-char link)
              (org-open-at-point)
              (sit-for org-linkotron-pause))
            group)
      (progress-reporter-done progress-reporter))))

(provide 'org-linkotron)

;; Local Variables:
;; coding: utf-8
;; End:

;;; org-linkotron.el ends here
