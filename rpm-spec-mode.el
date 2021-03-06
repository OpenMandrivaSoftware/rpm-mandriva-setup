;;; rpm-spec-mode.el --- RPM spec file editing commands for Emacs/XEmacs

;; $Id: rpm-spec-mode.el 232641 2007-12-20 09:58:22Z pixel $

;; Copyright (C) 1997-2002 Stig Bj�rlykke, <stigb@tihlde.org>

;; Author:   Stig Bj�rlykke, <stigb@tihlde.org>
;; Keywords: unix, languages
;; Version:  0.12

;; This file is part of XEmacs.

;; XEmacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; XEmacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with XEmacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
;; MA 02111-1307, USA.

;;; Synched up with: not in GNU Emacs.

;;; Thanx to:

;;     Tore Olsen <toreo@tihlde.org> for some general fixes.
;;     Steve Sanbeg <sanbeg@dset.com> for navigation functions and
;;          some Emacs fixes.
;;     Tim Powers <timp@redhat.com> and Trond Eivind Glomsr�d
;;          <teg@redhat.com> for Red Hat adaptions and some fixes.
;;     Chmouel Boudjnah <chmouel@mandrakesoft.com> for Mandrake fixes.

;;; ToDo:

;; - rewrite function names.
;; - autofill changelog entries.
;; - customize rpm-tags-list and rpm-group-tags-list.
;; - get values from `rpm --showrc'.
;; - ssh/rsh for compile.
;; - finish integrating the new navigation functions in with existing stuff.
;; - use a single prefix consistently (internal)

;;; Commentary:

;; This mode is used for editing spec files used for building RPM packages.
;;
;; Most recent version is available from:
;;  <URL:http://www.tihlde.org/~stigb/rpm-spec-mode.el>
;;
;; Put this in your .emacs file to enable autoloading of rpm-spec-mode,
;; and auto-recognition of ".spec" files:
;;
;;  (autoload 'rpm-spec-mode "rpm-spec-mode.el" "RPM spec mode." t)
;;  (setq auto-mode-alist (append '(("\\.spec" . rpm-spec-mode))
;;                                auto-mode-alist))
;;------------------------------------------------------------
;;

;;; Code:
(require 'cl)

(defconst rpm-spec-mode-version "0.12" "Version of `rpm-spec-mode'.")

;Fix for GNU/Emacs
(if (not(featurep 'xemacs))
	(fset 'define-obsolete-variable-alias 'make-obsolete))

(defgroup rpm-spec nil
  "RPM spec mode with Emacs/XEmacs enhancements."
  :prefix "rpm-spec-"
  :group 'languages)

(defcustom rpm-spec-build-command "rpmbuild"
  "Command for building a RPM package."
  :type 'string
  :group 'rpm-spec)

(defcustom rpm-spec-add-attr nil
  "Add \"%attr\" entry for file listings or not."
  :type 'boolean
  :group 'rpm-spec)

(defcustom rpm-spec-short-circuit nil
  "Skip straight to specified stage.
(ie, skip all stages leading up to the specified stage).  Only valid
in \"%build\" and \"%install\" stage."
  :type 'boolean
  :group 'rpm-spec)

(defcustom rpm-spec-no-deps nil
  "Do not verify the dependencies."
  :type 'boolean
  :group 'rpm-spec)

(defcustom rpm-spec-timecheck "0"
  "Set the \"timecheck\" age (0 to disable).
The timecheck value expresses, in seconds, the maximum age of a file
being packaged.  Warnings will be printed for all files beyond the
timecheck age."
  :type 'integer
  :group 'rpm-spec)

(defcustom rpm-spec-buildroot ""
  "Override the BuildRoot tag with directory <dir>."
  :type 'string
  :group 'rpm-spec)

(defcustom rpm-spec-target ""
  "Interpret given string as `arch-vendor-os'.
Set the macros _target, _target_arch and _target_os accordingly"
  :type 'string
  :group 'rpm-spec)

(define-obsolete-variable-alias
  'rpm-completion-ignore-case 'rpm-spec-completion-ignore-case)

(defcustom rpm-spec-completion-ignore-case t
  "*Non-nil means that case differences are ignored during completion.
A value of nil means that case is significant.
This is used during Tempo template completion."
  :type 'boolean
  :group 'rpm-spec)

(defcustom rpm-spec-clean nil
  "Remove the build tree after the packages are made."
  :type 'boolean
  :group 'rpm-spec)

(defcustom rpm-spec-rmsource nil
  "Remove the source and spec file after the packages are made."
  :type 'boolean
  :group 'rpm-spec)

(defcustom rpm-spec-nobuild nil
  "Do not execute any build stages.  Useful for testing out spec files."
  :type 'boolean
  :group 'rpm-spec)

(defcustom rpm-spec-sign-gpg nil
  "Embed a GPG signature in the package.
This signature can be used to verify the integrity and the origin of
the package."
  :type 'boolean
  :group 'rpm-spec)

(defcustom rpm-spec-nodeps nil
  "Do not verify build dependencies."
  :type 'boolean
  :group 'rpm-spec)

(defcustom rpm-spec-old-rpm nil
  "Set if using `rpm' as command for building packages."
  :type 'boolean
  :group 'rpm-spec)

(define-obsolete-variable-alias
  'rpm-initialize-sections 'rpm-spec-initialize-sections)

(defcustom rpm-spec-initialize-sections t
  "Automatically add empty section headings to new spec files."
  :type 'boolean
  :group 'rpm-spec)

(defcustom rpm-spec-use-tabs nil
  "Use tabs instead of a space to indent tags."
  :type 'boolean
  :group 'rpm-spec)

(define-obsolete-variable-alias
  'rpm-insert-version 'rpm-spec-insert-changelog-version)

(defcustom rpm-spec-insert-changelog-version t
  "Automatically add version in a new change log entry."
  :type 'boolean
  :group 'rpm-spec)

(defcustom rpm-spec-insert-changelog-version-with-shell t
  "Automatically add version with shell in a new change log entry."
  :type 'boolean
  :group 'rpm-spec)

(defcustom rpm-spec-user-full-name nil
  "*Full name of the user.
This is used in the change log and the Packager tag.  It defaults to the
value returned by function `user-full-name'."
  :type '(choice (const :tag "Use `user-full-name'" nil)
                 string)
  :group 'rpm-spec)

(defcustom rpm-spec-user-mail-address nil
  "*Email address of the user.
This is used in the change log and the Packager tag.  It defaults to the
value returned by function `user-mail-address'."
  :type '(choice (const :tag "Use `user-mail-address'" nil)
                 string)
  :group 'rpm-spec)

(defgroup rpm-spec-faces nil
  "Font lock faces for `rpm-spec-mode'."
  :group 'rpm-spec
  :group 'faces)

;;------------------------------------------------------------
;; variables used by navigation functions.

(defconst rpm-sections
  '("preamble" "description" "prep" "setup" "build" "install" "clean"
    "changelog" "files")
  "Partial list of section names.")
(defvar rpm-section-list
  '(("preamble") ("description") ("prep") ("setup") ("build") ("install")
    ("clean") ("changelog") ("files"))
  "Partial list of section names.")
(defconst rpm-scripts
  '("pre" "post" "preun" "postun"
    "trigger" "triggerin" "triggerun" "triggerpostun")
  "List of rpm scripts.")
(defconst rpm-section-seperate "^%\\(\\w+\\)\\s-")
(defconst rpm-section-regexp
  (eval-when-compile
    (concat "^%"
            (regexp-opt
             ;; From RPM 4.1 sources, file build/parseSpec.c: partList[].
             '("build" "changelog" "clean" "description" "files" "install"
               "package" "post" "postun" "pre" "prep" "preun" "trigger"
               "triggerin" "triggerpostun" "triggerun" "verifyscript") t)
            "\\b"))
  "Regular expression to match beginning of a section.")

;;------------------------------------------------------------

(defface rpm-spec-tag-face
  '(( ((class color) (background light)) (:foreground "blue") )
    ( ((class color) (background dark)) (:foreground "blue") ))
  "*The face used for tags."
  :group 'rpm-spec-faces)

(defface rpm-spec-macro-face
  '(( ((class color) (background light)) (:foreground "purple") )
    ( ((class color) (background dark)) (:foreground "yellow") ))
  "*The face used for macros."
  :group 'rpm-spec-faces)

(defface rpm-spec-var-face
  '(( ((class color) (background light)) (:foreground "maroon") )
    ( ((class color) (background dark)) (:foreground "maroon") ))
  "*The face used for environment variables."
  :group 'rpm-spec-faces)

(defface rpm-spec-doc-face
  '(( ((class color) (background light)) (:foreground "magenta") )
    ( ((class color) (background dark)) (:foreground "magenta") ))
  "*The face used for document files."
  :group 'rpm-spec-faces)

(defface rpm-spec-dir-face
  '(( ((class color) (background light)) (:foreground "green") )
    ( ((class color) (background dark)) (:foreground "green") ))
  "*The face used for directories."
  :group 'rpm-spec-faces)

(defface rpm-spec-package-face
  '(( ((class color) (background light)) (:foreground "red") )
    ( ((class color) (background dark)) (:foreground "red") ))
  "*The face used for files."
  :group 'rpm-spec-faces)

(defface rpm-spec-ghost-face
  '(( ((class color) (background light)) (:foreground "red") )
    ( ((class color) (background dark)) (:foreground "red") ))
  "*The face used for ghost tags."
  :group 'rpm-spec-faces)

;;; GNU emacs font-lock needs these...
(defvar rpm-spec-macro-face
  'rpm-spec-macro-face "*Face for macros.")
(defvar rpm-spec-var-face
  'rpm-spec-var-face "*Face for environment variables.")
(defvar rpm-spec-tag-face
  'rpm-spec-tag-face "*Face for tags.")
(defvar rpm-spec-package-face
  'rpm-spec-package-face "*Face for package tag.")
(defvar rpm-spec-dir-face
  'rpm-spec-dir-face "*Face for directory entries.")
(defvar rpm-spec-doc-face
  'rpm-spec-doc-face "*Face for documentation entries.")
(defvar rpm-spec-ghost-face
  'rpm-spec-ghost-face "*Face for \"%ghost\" files.")

(defvar rpm-default-umask "-"
  "*Default umask for files, specified with \"%attr\".")
(defvar rpm-default-owner "root"
  "*Default owner for files, specified with \"%attr\".")
(defvar rpm-default-group "root"
  "*Default group for files, specified with \"%attr\".")

;;------------------------------------------------------------

(defvar rpm-no-gpg nil "Tell rpm not to sign package.")

(defvar rpm-tags-list
  ;; From RPM 4.1 sources, file build/parsePreamble.c: preambleList[].")
  '(("AutoProv")
    ("AutoReq")
    ("AutoReqProv")
    ("BuildArch")
    ("BuildArchitectures")
    ("BuildConflicts")
    ("BuildPreReq")
    ("BuildRequires")
    ("BuildRoot")
    ("Conflicts")
    ("License")
    ("%description")
    ("Distribution")
    ("DistURL")
    ("DocDir")
    ("Epoch")
    ("ExcludeArch")
    ("ExcludeOS")
    ("ExclusiveArch")
    ("ExclusiveOS")
    ("%files")
    ("Group")
    ("Icon")
    ("%ifarch")
    ("License")
    ("Name")
    ("NoPatch")
    ("NoSource")
    ("Obsoletes")
    ("%package")
    ("Packager")
    ("Patch")
    ("Prefix")
    ("Prefixes")
    ("PreReq")
    ("Provides")
    ("Release")
    ("Requires")
    ("RHNPlatform")
    ("Serial")
    ("Source")
    ("Summary")
    ("URL")
    ("Vendor")
    ("Version"))
  "List of elements that are valid tags.")

;; echo "(defvar rpm-group-tags-list"
;; echo "      ;; Auto generated from Mandrake linux GROUPS file"
;; printf "\t%s\n" "'("
;; cat /usr/share/doc/*/GROUPS | while read i; do
;;             printf "\t   %s%s%s\n" '("' "$i" '")'
;; done
;; printf "\t%s\n\t%s" ")" '"List of elements that are valid group tags.")'

(defvar rpm-group-tags-list
      ;; Auto generated from Mandrake Linux GROUPS file
	'(
	   ("Accessibility")
	   ("Archiving/Backup")
	   ("Archiving/Cd burning")
	   ("Archiving/Compression")
	   ("Archiving/Other")
	   ("Books/Computer books")
	   ("Books/Faqs")
	   ("Books/Howtos")
	   ("Books/Literature")
	   ("Books/Other")
	   ("Communications")
	   ("Databases")
	   ("Development/C")
	   ("Development/C++")
	   ("Development/Databases")
	   ("Development/GNOME and GTK+")
	   ("Development/Java")
	   ("Development/KDE and Qt")
	   ("Development/Kernel")
	   ("Development/Other")
	   ("Development/Perl")
	   ("Development/PHP")
	   ("Development/Python")
	   ("Development/Ruby")
	   ("Editors")
	   ("Education")
	   ("Emulators")
	   ("File tools")
	   ("Games/Adventure")
	   ("Games/Arcade")
	   ("Games/Boards")
	   ("Games/Cards")
	   ("Games/Other")
	   ("Games/Puzzles")
	   ("Games/Sports")
	   ("Games/Strategy")
	   ("Graphical desktop/Enlightenment")
	   ("Graphical desktop/FVWM based")
	   ("Graphical desktop/GNOME")
	   ("Graphical desktop/Icewm")
	   ("Graphical desktop/KDE")
	   ("Graphical desktop/Other")
	   ("Graphical desktop/Sawfish")
	   ("Graphical desktop/WindowMaker")
	   ("Graphical desktop/Xfce")
	   ("Graphics")
	   ("Monitoring")
	   ("Networking/Chat")
	   ("Networking/File transfer")
	   ("Networking/IRC")
	   ("Networking/Instant messaging")
	   ("Networking/Mail")
	   ("Networking/News")
	   ("Networking/Other")
	   ("Networking/Remote access")
	   ("Networking/WWW")
	   ("Office")
	   ("Publishing")
	   ("Sciences/Astronomy")
	   ("Sciences/Biology")
	   ("Sciences/Chemistry")
	   ("Sciences/Computer science")
	   ("Sciences/Geosciences")
	   ("Sciences/Mathematics")
	   ("Sciences/Other")
	   ("Sciences/Physics")
	   ("Shells")
	   ("Sound")
	   ("System/Base")
	   ("System/Configuration/Boot and Init")
	   ("System/Configuration/Hardware")
	   ("System/Configuration/Networking")
	   ("System/Configuration/Other")
	   ("System/Configuration/Packaging")
	   ("System/Configuration/Printing")
	   ("System/Fonts/Console")
	   ("System/Fonts/True type")
	   ("System/Fonts/Type1")
	   ("System/Fonts/X11 bitmap")
	   ("System/Internationalization")
	   ("System/Kernel and hardware")
	   ("System/Libraries")
	   ("System/Servers")
	   ("System/X11")
	   ("Terminals")
	   ("Text tools")
	   ("Toys")
	   ("Video")
	)
	"List of elements that are valid group tags.")

(defvar rpm-spec-mode-syntax-table nil
  "Syntax table in use in `rpm-spec-mode' buffers.")
(unless rpm-spec-mode-syntax-table
  (setq rpm-spec-mode-syntax-table (make-syntax-table))
  (modify-syntax-entry ?\\ "\\" rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?\n ">   " rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?\f ">   " rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?\# "<   " rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?/ "." rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?* "." rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?+ "." rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?- "." rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?= "." rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?% "_" rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?< "." rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?> "." rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?& "." rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?| "." rpm-spec-mode-syntax-table)
  (modify-syntax-entry ?\' "." rpm-spec-mode-syntax-table))

(defvar rpm-spec-mode-map nil
  "Keymap used in `rpm-spec-mode'.")
(unless rpm-spec-mode-map
  (setq rpm-spec-mode-map (make-sparse-keymap))
  (and (functionp 'set-keymap-name)
       (set-keymap-name rpm-spec-mode-map 'rpm-spec-mode-map))
  (define-key rpm-spec-mode-map "\C-c\C-c"  'rpm-change-tag)
  (define-key rpm-spec-mode-map "\C-c\C-e"  'rpm-add-change-log-entry)
  (define-key rpm-spec-mode-map "\C-c\C-i"  'rpm-insert-tag)
  (define-key rpm-spec-mode-map "\C-c\C-n"  'rpm-forward-section)
  (define-key rpm-spec-mode-map "\C-c\C-o"  'rpm-goto-section)
  (define-key rpm-spec-mode-map "\C-c\C-p"  'rpm-backward-section)
  (define-key rpm-spec-mode-map "\C-c\C-r"  'rpm-increase-release-tag)
  (define-key rpm-spec-mode-map "\C-c\C-u"  'rpm-insert-true-prefix)
  (define-key rpm-spec-mode-map "\C-c\C-ba" 'rpm-build-all)
  (define-key rpm-spec-mode-map "\C-c\C-bb" 'rpm-build-binary)
  (define-key rpm-spec-mode-map "\C-c\C-bc" 'rpm-build-compile)
  (define-key rpm-spec-mode-map "\C-c\C-bi" 'rpm-build-install)
  (define-key rpm-spec-mode-map "\C-c\C-bl" 'rpm-list-check)
  (define-key rpm-spec-mode-map "\C-c\C-bp" 'rpm-build-prepare)
  (define-key rpm-spec-mode-map "\C-c\C-bs" 'rpm-build-source)
  (define-key rpm-spec-mode-map "\C-c\C-dd" 'rpm-insert-dir)
  (define-key rpm-spec-mode-map "\C-c\C-do" 'rpm-insert-docdir)
  (define-key rpm-spec-mode-map "\C-c\C-fc" 'rpm-insert-config)
  (define-key rpm-spec-mode-map "\C-c\C-fd" 'rpm-insert-doc)
  (define-key rpm-spec-mode-map "\C-c\C-ff" 'rpm-insert-file)
  (define-key rpm-spec-mode-map "\C-c\C-fg" 'rpm-insert-ghost)
  (define-key rpm-spec-mode-map "\C-c\C-xa" 'rpm-toggle-add-attr)
  (define-key rpm-spec-mode-map "\C-c\C-xb" 'rpm-change-buildroot-option)
  (define-key rpm-spec-mode-map "\C-c\C-xc" 'rpm-toggle-clean)
  (define-key rpm-spec-mode-map "\C-c\C-xd" 'rpm-toggle-nodeps)
  (define-key rpm-spec-mode-map "\C-c\C-xf" 'rpm-files-group)
  (define-key rpm-spec-mode-map "\C-c\C-xg" 'rpm-toggle-sign-gpg)
  (define-key rpm-spec-mode-map "\C-c\C-xi" 'rpm-change-timecheck-option)
  (define-key rpm-spec-mode-map "\C-c\C-xn" 'rpm-toggle-nobuild)
  (define-key rpm-spec-mode-map "\C-c\C-xo" 'rpm-files-owner)
  (define-key rpm-spec-mode-map "\C-c\C-xp" 'rpm-change-target-option)
  (define-key rpm-spec-mode-map "\C-c\C-xr" 'rpm-toggle-rmsource)
  (define-key rpm-spec-mode-map "\C-cxd"    'rpm-toggle-no-deps)
  (define-key rpm-spec-mode-map "\C-c\C-xs" 'rpm-toggle-short-circuit)
  (define-key rpm-spec-mode-map "\C-c\C-xu" 'rpm-files-umask)
  ;;(define-key rpm-spec-mode-map "\C-q" 'indent-spec-exp)
  ;;(define-key rpm-spec-mode-map "\t" 'sh-indent-line)
  )

(defconst rpm-spec-mode-menu
  (purecopy '("RPM spec"
              ["Insert Tag..."           rpm-insert-tag                t]
              ["Change Tag..."           rpm-change-tag                t]
              "---"
              ["Go to section..."        rpm-mouse-goto-section  :keys "C-c C-o"]
              ["Forward section"         rpm-forward-section           t]
              ["Backward section"        rpm-backward-section          t]
              "---"
              ["Add change log entry..." rpm-add-change-log-entry      t]
              ["Increase release tag"    rpm-increase-release-tag      t]
              "---"
              ("Add file entry"
               ["Regular file..."        rpm-insert-file               t]
               ["Config file..."         rpm-insert-config             t]
               ["Document file..."       rpm-insert-doc                t]
               ["Ghost file..."          rpm-insert-ghost              t]
               "---"
               ["Directory..."           rpm-insert-dir                t]
               ["Document directory..."  rpm-insert-docdir             t]
               "---"
               ["Insert %{prefix}"       rpm-insert-true-prefix        t]
               "---"
               ["Default add \"%attr\" entry" rpm-toggle-add-attr
                :style toggle :selected rpm-spec-add-attr]
               ["Change default umask for files..."  rpm-files-umask   t]
               ["Change default owner for files..."  rpm-files-owner   t]
               ["Change default group for files..."  rpm-files-group   t])
              ("Build Options"
               ["Short circuit" rpm-toggle-short-circuit
                :style toggle :selected rpm-spec-short-circuit]
			   ["No deps" rpm-toggle-no-deps
				:style toggle :selected rpm-spec-no-deps]
               ["Remove source" rpm-toggle-rmsource
                :style toggle :selected rpm-spec-rmsource]
               ["Clean"         rpm-toggle-clean
                :style toggle :selected rpm-spec-clean]
               ["No build"      rpm-toggle-nobuild
                :style toggle :selected rpm-spec-nobuild]
               ["GPG sign"      rpm-toggle-sign-gpg
                :style toggle :selected rpm-spec-sign-gpg]
               ["Ignore dependencies" rpm-toggle-nodeps
                :style toggle :selected rpm-spec-nodeps]
               "---"
               ["Change timecheck value..."  rpm-change-timecheck-option   t]
               ["Change buildroot value..."  rpm-change-buildroot-option   t]
               ["Change target value..."     rpm-change-target-option      t])
              ("RPM Build"
               ["Execute \"%prep\" stage"    rpm-build-prepare             t]
               ["Do a \"list check\""        rpm-list-check                t]
               ["Do the \"%build\" stage"    rpm-build-compile             t]
               ["Do the \"%install\" stage"  rpm-build-install             t]
               "---"
               ["Build binary package"       rpm-build-binary              t]
               ["Build source package"       rpm-build-source              t]
               ["Build binary and source"    rpm-build-all                 t])
              "---"
              ["About rpm-spec-mode"         rpm-about-rpm-spec-mode       t]
              )))

(defvar rpm-spec-font-lock-keywords
  '(
    ("%[a-zA-Z0-9-_]+" 0 rpm-spec-macro-face)
    ("^\\([a-zA-Z0-9]+\\)\\(\([a-zA-Z0-9,]+\)\\):"
     (1 rpm-spec-tag-face)
     (2 rpm-spec-ghost-face))
    ("^\\([a-zA-Z0-9]+\\):" 1 rpm-spec-tag-face)
    ("%\\(de\\(fine\\|scription\\)\\|files\\|package\\)[ \t]+\\([^-][^ \t\n]*\\)"
     (3 rpm-spec-package-face))
    ("%p\\(ost\\|re\\)\\(un\\)?[ \t]+\\([^-][^ \t\n]*\\)"
     (3 rpm-spec-package-face))
    ("%configure " 0 rpm-spec-macro-face)
    ("%dir[ \t]+\\([^ \t\n]+\\)[ \t]*" 1 rpm-spec-dir-face)
    ("%doc\\(dir\\)?[ \t]+\\(.*\\)\n" 2 rpm-spec-doc-face)
    ("%\\(ghost\\|config\\)[ \t]+\\(.*\\)\n" 2 rpm-spec-ghost-face)
    ("^%.+-[a-zA-Z][ \t]+\\([a-zA-Z0-9\.-]+\\)" 1 rpm-spec-doc-face)
    ("^\\(.+\\)(\\([a-zA-Z]\\{2,2\\}\\)):"
     (1 rpm-spec-tag-face)
     (2 rpm-spec-doc-face))
    ("^\\*\\(.*[0-9] \\)\\(.*\\)\\(<.*>\\)\\(.*\\)\n"
     (1 rpm-spec-dir-face)
     (2 rpm-spec-package-face)
     (3 rpm-spec-tag-face)
     (4 font-lock-warning-face))
    ("%{[^{}]*}" 0 rpm-spec-macro-face)
    ("$[a-zA-Z0-9_]+" 0 rpm-spec-var-face)
    ("${[a-zA-Z0-9_]+}" 0 rpm-spec-var-face)
    )
  "Additional expressions to highlight in `rpm-spec-mode'.")

;;Initialize font lock for xemacs
(put 'rpm-spec-mode 'font-lock-defaults '(rpm-spec-font-lock-keywords))

(defvar rpm-spec-mode-abbrev-table nil
  "Abbrev table in use in `rpm-spec-mode' buffers.")
(define-abbrev-table 'rpm-spec-mode-abbrev-table ())

;;------------------------------------------------------------

;;;###autoload
(defun rpm-spec-mode ()
  "Major mode for editing RPM spec files.
This is much like C mode except for the syntax of comments.  It uses
the same keymap as C mode and has the same variables for customizing
indentation.  It has its own abbrev table and its own syntax table.

Turning on RPM spec mode calls the value of the variable `rpm-spec-mode-hook'
with no args, if that value is non-nil."
  (interactive)
  (kill-all-local-variables)
  (condition-case nil
      (require 'shindent)
    (error
     (require 'sh-script)))
  (require 'cc-mode)
  (use-local-map rpm-spec-mode-map)
  (setq major-mode 'rpm-spec-mode)
  (rpm-update-mode-name)
  (setq local-abbrev-table rpm-spec-mode-abbrev-table)
  (set-syntax-table rpm-spec-mode-syntax-table)

  (require 'easymenu)
  (easy-menu-define rpm-spec-call-menu rpm-spec-mode-map
                    "Post menu for `rpm-spec-mode'." rpm-spec-mode-menu)
  (easy-menu-add rpm-spec-mode-menu)

  (if (= (buffer-size) 0)
      (rpm-spec-initialize))

  (if (executable-find "rpmbuild")
      (setq rpm-spec-build-command "rpmbuild")
    (setq rpm-spec-old-rpm t)
    (setq rpm-spec-build-command "rpm"))
  
  (make-local-variable 'paragraph-start)
  (setq paragraph-start (concat "$\\|" page-delimiter))
  (make-local-variable 'paragraph-separate)
  (setq paragraph-separate paragraph-start)
  (make-local-variable 'paragraph-ignore-fill-prefix)
  (setq paragraph-ignore-fill-prefix t)
;  (make-local-variable 'indent-line-function)
;  (setq indent-line-function 'c-indent-line)
  (make-local-variable 'require-final-newline)
  (setq require-final-newline t)
  (make-local-variable 'comment-start)
  (setq comment-start "# ")
  (make-local-variable 'comment-end)
  (setq comment-end "")
  (make-local-variable 'comment-column)
  (setq comment-column 32)
  (make-local-variable 'comment-start-skip)
  (setq comment-start-skip "#+ *")
;  (make-local-variable 'comment-indent-function)
;  (setq comment-indent-function 'c-comment-indent)
  ;;Initialize font lock for GNU emacs.
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(rpm-spec-font-lock-keywords nil t))
  (run-hooks 'rpm-spec-mode-hook))

(defun rpm-command-filter (process string)
  "Filter to process normal output."
  (save-excursion
    (set-buffer (process-buffer process))
    (save-excursion
      (goto-char (process-mark process))
      (insert-before-markers string)
      (set-marker (process-mark process) (point)))))

; insert one space, or the number of tabs if rpm-spec-use-tabs is true
(defun rpm-insert-space-or-tabs (tabs)
  (if rpm-spec-use-tabs
      (if (> tabs 0)
	  (concat "\t" (rpm-insert-space-or-tabs (1- tabs)))
	  "")
      " "))

;;------------------------------------------------------------

(defun rpm-add-change-log-entry (&optional change-log-entry)
  "Find change log and add an entry for today."
  (interactive "P")
  (goto-char (point-min))
    (if (search-forward-regexp "^%changelog[ \t]*$" nil t)
	(let* ((address (or rpm-spec-user-mail-address user-mail-address))
	       (fullname (or rpm-spec-user-full-name user-full-name))
	       (string (concat "* " (substring (current-time-string) 0 11)
			       (substring (current-time-string) -4) " "
			       fullname " <" address "> "
			       (or 
				(and rpm-spec-insert-changelog-version
				     (or (and rpm-spec-insert-changelog-version-with-shell
					      (rpm-find-spec-version-with-shell))
					 (rpm-find-spec-version))))
				"")))
	  (if (not (search-forward string nil t))
	      (insert "\n" string "\n")
	      (progn (next-line 1)
		     (beginning-of-line)))
	  (unless (eq (point) (1- (point-max)))
	    (insert "\n")
	    (previous-line 1))
	  (insert "- ")
	  (if change-log-entry
	      (insert (concat (format "%s." change-log-entry)))))
	(message "No \"%%changelog\" entry found...")))

;;------------------------------------------------------------

(defun rpm-insert-f (&optional filetype filename)
  "Insert new \"%files\" entry."
  (save-excursion
    (and (rpm-goto-section "files") (rpm-end-of-section))
    (if (or (eq filename 1) (not filename))
        (insert (read-file-name
                 (concat filetype "filename: ") "" "" nil) "\n")
      (insert filename "\n"))
    (forward-line -1)
    (if rpm-spec-add-attr
        (let ((rpm-default-mode rpm-default-umask))
          (insert "%attr(" rpm-default-mode ", " rpm-default-owner ", "
                  rpm-default-group ") ")))
    (insert filetype)))

(defun rpm-insert-file (&optional filename)
  "Insert regular file."
  (interactive "p")
  (rpm-insert-f "" filename))

(defun rpm-insert-config (&optional filename)
  "Insert config file."
  (interactive "p")
  (rpm-insert-f "%config " filename))

(defun rpm-insert-doc (&optional filename)
  "Insert doc file."
  (interactive "p")
  (rpm-insert-f "%doc " filename))

(defun rpm-insert-ghost (&optional filename)
  "Insert ghost file."
  (interactive "p")
  (rpm-insert-f "%ghost " filename))

(defun rpm-insert-dir (&optional dirname)
  "Insert directory."
  (interactive "p")
  (rpm-insert-f "%dir " dirname))

(defun rpm-insert-docdir (&optional dirname)
  "Insert doc directory."
  (interactive "p")
  (rpm-insert-f "%docdir " dirname))

;;------------------------------------------------------------
(defun rpm-completing-read (prompt table &optional pred require init hist)
  "Read from the minibuffer, with completion.
Like `completing-read', but the variable `rpm-spec-completion-ignore-case'
controls whether case is significant."
  (let ((completion-ignore-case rpm-spec-completion-ignore-case))
    (completing-read prompt table pred require init hist)))

(defun rpm-insert (&optional what file-completion)
  "Insert given tag.  Use file-completion if argument is t."
  (beginning-of-line)
  (if (not what)
      (setq what (rpm-completing-read "Tag: " rpm-tags-list)))
  (if (string-match "^%" what)
      (setq read-text (concat "Packagename for " what ": ")
            insert-text (concat what " "))
    (setq read-text (concat what ": ")
          insert-text (concat what ": ")))
  (cond
   ((string-equal what "Group")
    (rpm-insert-group))
   ((string-equal what "Source")
    (rpm-insert-n "Source"))
   ((string-equal what "Patch")
    (rpm-insert-n "Patch"))
   (t
    (if file-completion
        (insert insert-text (read-file-name (concat read-text) "" "" nil) "\n")
      (insert insert-text (read-from-minibuffer (concat read-text)) "\n")))))

(defun rpm-topdir ()
  (or
   (getenv "RPM")
   (getenv "rpm")
   (if (file-directory-p "~/rpm") "~/rpm/")
   (if (file-directory-p "~/RPM") "~/RPM/")
   (if (file-directory-p "/usr/src/redhat/") "/usr/src/redhat/")
   "/usr/src/RPM"))

(defun rpm-insert-n (what &optional arg)
  "Insert given tag with possible number."
  (save-excursion
    (goto-char (point-max))
    (if (search-backward-regexp (concat "^" what "\\([0-9]*\\):") nil t)
        (let ((release (1+ (string-to-int (match-string 1)))))
          (forward-line 1)
          (let ((default-directory (concat (rpm-topdir) "/SOURCES/")))
            (insert what (int-to-string release) ": "
                    (read-file-name (concat what "file: ") "" "" nil) "\n")))
      (goto-char (point-min))
      (rpm-end-of-section)
      (insert what ": " (read-from-minibuffer (concat what "file: ")) "\n"))))

(defun rpm-change (&optional what arg)
  "Update given tag."
  (save-excursion
    (if (not what)
        (setq what (rpm-completing-read "Tag: " rpm-tags-list)))
    (cond
     ((string-equal what "Group")
      (rpm-change-group))
     ((string-equal what "Source")
      (rpm-change-n "Source"))
     ((string-equal what "Patch")
      (rpm-change-n "Patch"))
     (t
      (goto-char (point-min))
      (if (search-forward-regexp (concat "^" what ":\\s-*\\(.*\\)$") nil t)
          (replace-match
           (concat what ": " (read-from-minibuffer
                              (concat "New " what ": ") (match-string 1))))
        (message (concat what " tag not found...")))))))

(defun rpm-change-n (what &optional arg)
  "Change given tag with possible number."
  (save-excursion
    (goto-char (point-min))
    (let ((number (read-from-minibuffer (concat what " number: "))))
      (if (search-forward-regexp
           (concat "^" what number ":\\s-*\\(.*\\)") nil t)
          (let ((default-directory (concat (rpm-topdir) "/SOURCES/")))
            (replace-match
             (concat what number ": "
                     (read-file-name (concat "New " what number " file: ")
                                     "" "" nil (match-string 1)))))
        (message (concat what " number \"" number "\" not found..."))))))

(defun rpm-insert-group (group)
  "Insert Group tag."
  (interactive (list (rpm-completing-read "Group: " rpm-group-tags-list)))
  (beginning-of-line)
  (insert "Group:" (rpm-insert-space-or-tabs 2) group "\n"))

(defun rpm-change-group (&optional arg)
  "Update Group tag."
  (interactive "p")
  (save-excursion
    (goto-char (point-min))
    (if (search-forward-regexp "^Group:[ \t]*\\(.*\\)$" nil t)
        (replace-match
         (concat "Group:"
		 (rpm-insert-space-or-tabs 2)
                 (rpm-completing-read "Group: " rpm-group-tags-list
				      nil nil (match-string 1))))
      (message "Group tag not found..."))))

(defun rpm-insert-tag (&optional arg)
  "Insert or change a tag."
  (interactive "p")
  (if current-prefix-arg
      (rpm-change)
    (rpm-insert)))

(defun rpm-change-tag (&optional arg)
  "Change a tag."
  (interactive "p")
  (rpm-change))

(defun rpm-insert-packager (&optional arg)
  "Insert Packager tag."
  (interactive "p")
  (beginning-of-line)
  (insert "Packager:"
	  (rpm-insert-space-or-tabs 1)
	  (or rpm-spec-user-full-name (user-full-name))
          " <" (or rpm-spec-user-mail-address (user-mail-address)) ">\n"))

(defun rpm-change-packager (&optional arg)
  "Update Packager tag."
  (interactive "p")
  (rpm-change "Packager"))

;;------------------------------------------------------------

(defun rpm-current-section nil
  (interactive)
  (save-excursion
    (rpm-forward-section)
    (rpm-backward-section)
    (if (bobp) "preamble"
      (buffer-substring (match-beginning 1) (match-end 1)))))

(defun rpm-backward-section nil
  "Move backward to the beginning of the previous section.
Go to beginning of previous section."
  (interactive)
  (or (re-search-backward rpm-section-regexp nil t)
      (goto-char (point-min))))

(defun rpm-beginning-of-section nil
  "Move backward to the beginning of the current section.
Go to beginning of current section."
  (interactive)
  (or (and (looking-at rpm-section-regexp) (point))
      (re-search-backward rpm-section-regexp nil t)
      (goto-char (point-min))))

(defun rpm-forward-section nil
  "Move forward to the beginning of the next section."
  (interactive)
  (forward-char)
  (if (re-search-forward rpm-section-regexp nil t)
      (progn (forward-line 0) (point))
    (goto-char (point-max))))

(defun rpm-end-of-section nil
  "Move forward to the end of this section."
  (interactive)
  (forward-char)
  (if (re-search-forward rpm-section-regexp nil t)
      (forward-line -1)
    (goto-char (point-max)))
;;  (while (or (looking-at paragraph-separate) (looking-at "^\\s-*#"))
  (while (looking-at "^\\s-*\\($\\|#\\)")
    (forward-line -1))
  (forward-line 1)
  (point))

(defun rpm-goto-section (section)
  "Move point to the beginning of the specified section;
leave point at previous location."
  (interactive (list (rpm-completing-read "Section: " rpm-section-list)))
  (push-mark)
  (goto-char (point-min))
  (or
   (equal section "preamble")
   (re-search-forward (concat "^%" section "\\b") nil t)
   (let ((s (cdr rpm-sections)))
     (while (not (equal section (car s)))
       (re-search-forward (concat "^%" (car s) "\\b") nil t)
       (setq s (cdr s)))
     (if (re-search-forward rpm-section-regexp nil t)
         (forward-line -1) (goto-char (point-max)))
     (insert "\n%" section "\n"))))

(defun rpm-mouse-goto-section (&optional section)
  (interactive
   (x-popup-menu
    nil
    (list "sections"
          (cons "Sections" (mapcar (lambda (e) (list e e)) rpm-sections))
          (cons "Scripts" (mapcar (lambda (e) (list e e)) rpm-scripts))
          )))
  ;; If user doesn't pick a section, exit quietly.
  (and section
       (if (member section rpm-sections)
           (rpm-goto-section section)
         (goto-char (point-min))
         (or (re-search-forward (concat "^%" section "\\b") nil t)
             (and (re-search-forward "^%files\\b" nil t) (forward-line -1))
             (goto-char (point-max))))))

(defun rpm-insert-true-prefix ()
  (interactive)
  (insert "%{prefix}"))

;;------------------------------------------------------------

(defun rpm-build (buildoptions)
  "Build this RPM package."
  (setq rpm-buffer-name
        (concat "*" rpm-spec-build-command " " 
                (file-name-nondirectory buffer-file-name) "*"))
  (rpm-process-check rpm-buffer-name)
  (if (get-buffer rpm-buffer-name)
      (kill-buffer rpm-buffer-name))
  (create-file-buffer rpm-buffer-name)
  (display-buffer rpm-buffer-name)
  (setq buildoptions (list buildoptions buffer-file-name))
  (if (or rpm-spec-short-circuit rpm-spec-nobuild)
      (setq rpm-no-gpg t))
  (if rpm-spec-rmsource
      (setq buildoptions (cons "--rmsource" buildoptions)))
  (if rpm-spec-clean
      (setq buildoptions (cons "--clean" buildoptions)))
  (if rpm-spec-short-circuit
      (setq buildoptions (cons "--short-circuit" buildoptions)))
  (if rpm-spec-no-deps
      (setq buildoptions (cons "--nodeps" buildoptions)))
  (if (and (not (equal rpm-spec-timecheck "0"))
           (not (equal rpm-spec-timecheck "")))
      (setq buildoptions (cons "--timecheck" (cons rpm-spec-timecheck
                                                   buildoptions))))
  (if (not (equal rpm-spec-buildroot ""))
      (setq buildoptions (cons "--buildroot" (cons rpm-spec-buildroot
                                                   buildoptions))))
  (if (not (equal rpm-spec-target ""))
      (setq buildoptions (cons "--target" (cons rpm-spec-target
                                                buildoptions))))
  (if rpm-spec-nobuild
      (setq buildoptions (cons (if rpm-spec-old-rpm "--test" "--nobuild")
			       buildoptions)))
  (if rpm-spec-nodeps
      (setq buildoptions (cons "--nodeps" buildoptions)))
  (if (and rpm-spec-sign-gpg (not rpm-no-gpg))
      (setq buildoptions (cons "--sign" buildoptions)))
  (save-excursion
    (set-buffer (get-buffer rpm-buffer-name))
    (goto-char (point-max)))
  (let ((process
         (apply 'start-process rpm-spec-build-command rpm-buffer-name
		rpm-spec-build-command buildoptions)))
    (if (and rpm-spec-sign-gpg (not rpm-no-gpg))
        (let ((rpm-passwd-cache (read-passwd "GPG passphrase: ")))
          (process-send-string process (concat rpm-passwd-cache "\n"))))
    (set-process-filter process 'rpm-command-filter)))

(defun rpm-build-prepare (&optional arg)
  "Run a `rpmbuild -bp'."
  (interactive "p")
   (setq rpm-no-gpg t)
   (rpm-build "-bp"))

(defun rpm-list-check (&optional arg)
  "Run a `rpmbuild -bl'."
  (interactive "p")
  (setq rpm-no-gpg t)
  (rpm-build "-bl"))

(defun rpm-build-compile (&optional arg)
  "Run a `rpmbuild -bc'."
  (interactive "p")
  (setq rpm-no-gpg t)
  (rpm-build "-bc"))

(defun rpm-build-install (&optional arg)
  "Run a `rpmbuild -bi'."
  (interactive "p")
  (setq rpm-no-gpg t)
  (rpm-build "-bi"))

(defun rpm-build-binary (&optional arg)
  "Run a `rpmbuild -bb'."
  (interactive "p")
  (setq rpm-no-gpg nil)
  (rpm-build "-bb"))

(defun rpm-build-source (&optional arg)
  "Run a `rpmbuild -bs'."
  (interactive "p")
  (setq rpm-no-gpg nil)
  (rpm-build "-bs"))

(defun rpm-build-all (&optional arg)
  "Run a `rpmbuild -ba'."
  (interactive "p")
  (setq rpm-no-gpg nil)
    (rpm-build "-ba"))

(defun rpm-process-check (buffer)
  "Check if BUFFER has a running process.
If so, give the user the choice of aborting the process or the current
command."
  (let ((process (get-buffer-process (get-buffer buffer))))
    (if (and process (eq (process-status process) 'run))
        (if (yes-or-no-p (concat "Process `" (process-name process)
                                 "' running.  Kill it? "))
            (delete-process process)
          (error "Cannot run two simultaneous processes ...")))))

;;------------------------------------------------------------

(defun rpm-toggle-short-circuit (&optional arg)
  "Toggle `rpm-spec-short-circuit'."
  (interactive "p")
  (setq rpm-spec-short-circuit (not rpm-spec-short-circuit))
  (rpm-update-mode-name)
  (message (concat "Turned `--short-circuit' "
                   (if rpm-spec-short-circuit "on" "off") ".")))

(defun rpm-toggle-no-deps (&optional arg)
  "Toggle rpm-spec-no-deps."
  (interactive "p")
  (setq rpm-spec-no-deps (not rpm-spec-no-deps))
  (rpm-update-mode-name)
  (message (concat "Turned `--nodeps' "
                   (if rpm-spec-no-deps "on" "off") ".")))

(defun rpm-toggle-rmsource (&optional arg)
  "Toggle `rpm-spec-rmsource'."
  (interactive "p")
  (setq rpm-spec-rmsource (not rpm-spec-rmsource))
  (rpm-update-mode-name)
  (message (concat "Turned `--rmsource' "
                   (if rpm-spec-rmsource "on" "off") ".")))

(defun rpm-toggle-clean (&optional arg)
  "Toggle `rpm-spec-clean'."
  (interactive "p")
  (setq rpm-spec-clean (not rpm-spec-clean))
  (rpm-update-mode-name)
  (message (concat "Turned `--clean' "
                   (if rpm-spec-clean "on" "off") ".")))

(defun rpm-toggle-nobuild (&optional arg)
  "Toggle `rpm-spec-nobuild'."
  (interactive "p")
  (setq rpm-spec-nobuild (not rpm-spec-nobuild))
  (rpm-update-mode-name)
  (message (concat "Turned `" (if rpm-spec-old-rpm "--test" "--nobuild") "' "
                   (if rpm-spec-nobuild "on" "off") ".")))

(defun rpm-toggle-sign-gpg (&optional arg)
  "Toggle `rpm-spec-sign-gpg'."
  (interactive "p")
  (setq rpm-spec-sign-gpg (not rpm-spec-sign-gpg))
  (rpm-update-mode-name)
  (message (concat "Turned `--sign' "
                   (if rpm-spec-sign-gpg "on" "off") ".")))

(defun rpm-toggle-add-attr (&optional arg)
  "Toggle `rpm-spec-add-attr'."
  (interactive "p")
  (setq rpm-spec-add-attr (not rpm-spec-add-attr))
  (rpm-update-mode-name)
  (message (concat "Default add \"attr\" entry turned "
                   (if rpm-spec-add-attr "on" "off") ".")))

(defun rpm-toggle-nodeps (&optional arg)
  "Toggle `rpm-spec-nodeps'."
  (interactive "p")
  (setq rpm-spec-nodeps (not rpm-spec-nodeps))
  (rpm-update-mode-name)
  (message (concat "Turned `--nodeps' "
                   (if rpm-spec-nodeps "on" "off") ".")))

(defun rpm-update-mode-name ()
  "Update `mode-name' according to values set."
  (setq mode-name "RPM-SPEC")
  (setq modes (concat (if rpm-spec-add-attr      "A")
                      (if rpm-spec-clean         "C")
                      (if rpm-spec-nodeps        "D")
                      (if rpm-spec-sign-gpg      "G")
                      (if rpm-spec-nobuild       "N")
                      (if rpm-spec-rmsource      "R")
                      (if rpm-spec-short-circuit "S")
					  (if rpm-spec-no-deps       "D")
                      ))
  (if (not (equal modes ""))
      (setq mode-name (concat mode-name ":" modes))))

;;------------------------------------------------------------

(defun rpm-change-timecheck-option (&optional arg)
  "Change the value for timecheck."
  (interactive "p")
  (setq rpm-spec-timecheck
        (read-from-minibuffer "New timecheck: " rpm-spec-timecheck)))

(defun rpm-change-buildroot-option (&optional arg)
  "Change the value for buildroot."
  (interactive "p")
  (setq rpm-spec-buildroot
        (read-from-minibuffer "New buildroot: " rpm-spec-buildroot)))

(defun rpm-change-target-option (&optional arg)
  "Change the value for target."
  (interactive "p")
  (setq rpm-spec-target
        (read-from-minibuffer "New target: " rpm-spec-target)))

(defun rpm-files-umask (&optional arg)
  "Change the default umask for files."
  (interactive "p")
  (setq rpm-default-umask
        (read-from-minibuffer "Default file umask: " rpm-default-umask)))

(defun rpm-files-owner (&optional arg)
  "Change the default owner for files."
  (interactive "p")
  (setq rpm-default-owner
        (read-from-minibuffer "Default file owner: " rpm-default-owner)))

(defun rpm-files-group (&optional arg)
  "Change the source directory."
  (interactive "p")
  (setq rpm-default-group
        (read-from-minibuffer "Default file group: " rpm-default-group)))

(defun rpm-increase-release-tag (&optional arg)
  "Increase the release tag by 1."
  (interactive "p")
  (save-excursion
    (goto-char (point-min))
	(if (search-forward-regexp "^Release:\\([ \t]*\\)\\(\\([^.\n]+\\.\\)*\\)\\([0-9]+\\)\\(.*\\)" nil t)
		(let ((release (1+ (string-to-int (match-string 4)))))
		  (setq release (concat (match-string 1) (match-string 2) (int-to-string release) (match-string 5)))
		  (replace-match (concat "Release:" release))
		  (message (concat "Release tag changed to " release ".")))
	  (if (search-forward-regexp "^Release:[ \t]*%{?\\([^}]*\\)}?$" nil t)
		  (rpm-increase-release-with-macros)
		(message "No Release tag found...")))))

;;------------------------------------------------------------

(defun rpm-spec-field-value (field max)
  "Get the value of FIELD, searching up to buffer position MAX.
See `search-forward-regexp'."
  (save-excursion
    (ignore-errors
      (let ((str
             (progn
               (goto-char (point-min))
               (search-forward-regexp (concat
                                       field ":[ \t]*\\(.*?\\)[ \t]*$") max)
               (match-string 1))))
        (if (string-match "%{?\\([^}]*\\)}?$" str)
            (progn
              (goto-char (point-min))
              (search-forward-regexp
               (concat "%define[ \t]+" (substring str (match-beginning 1)
                                                  (match-end 1))
                       "[ \t]+\\(.*\\)"))
              (match-string 1))
          str)))))

(defun rpm-find-spec-version (&optional with-epoch)
  "Get the version string.
If WITH-EPOCH is non-nil, the string contains the Epoch/Serial value,
if one is present in the file."
  (save-excursion
    (goto-char (point-min))
    (let* ((max (search-forward-regexp rpm-section-regexp))
           (version (rpm-spec-field-value "Version" max))
           (release (rpm-spec-field-value "Release" max))
           (epoch   (rpm-spec-field-value "Epoch"   max)) )
      (when (and version (< 0 (length version)))
        (unless epoch (setq epoch (rpm-spec-field-value "Serial" max)))
        (concat (and with-epoch epoch (concat epoch ":"))
                version
                (and release (concat "-" release)))))))

(defun rpm--with-temp-file (prefix f)
  (let ((file (make-temp-file prefix)))
    (unwind-protect
	(funcall f file)
      (delete-file file))))

(defun rpm-find-spec-version-with-shell ()
  "Find the version and release with the rpm command 
   more robust but slower than the lisp version"
  (rpm--with-temp-file "spec" (lambda (tmpfile)
     (write-region (point-min) (point-max) tmpfile nil 1)
  (let ((relver))
	(with-temp-buffer
	  (apply 'call-process "rpm" nil t nil 
			 (list "-q" "--qf" "'%{VERSION}-%{RELEASE}\\n'" "--specfile" tmpfile))
	  (goto-char (point-min))
	  (if (re-search-forward "\\([0-9]+.+\\)" nil t)
	      (setq relver (match-string 1)))
	  )
  relver)
  )))

(defun rpm-increase-release-with-macros ()
  (save-excursion
    (let ((str
           (progn
             (goto-char (point-min))
             (search-forward-regexp (concat "Release:[ \t]*\\(.+\\).*$") nil)
             (match-string 1)))
	  (increase-macro (lambda (macros)
		   (goto-char (point-min))
                   (if (search-forward-regexp
			(concat "%define[ \t]+" macros
				"\\([ \t]+\\)\\(\\([^.\n]+\\.\\)*\\)\\([0-9]+\\)\\(.*\\)") nil t)
		       (let ((dinrel (concat macros (match-string 1) (match-string 2)
			       (int-to-string (1+ (string-to-int
						   (match-string 4))))
			       (match-string 5))))
			 (replace-match (concat "%define " dinrel))
			 (message (concat "Release tag changed to " dinrel "."))
			 t)))))

      (if (string-match "%{?\\([^}]*\\)}?$" str)
	  (let ((macros (substring str (match-beginning 1) (match-end 1))))
	    (or (funcall increase-macro macros)
		(and (search-forward-regexp
		      (concat "%define[ \t]+" macros "[ \t]+%mkrel[ \t]+%{rel}") nil t)
		     (funcall increase-macro "rel"))
		(and (search-forward-regexp "\\(%mkrel[ \t]+\\)\\([0-9]+\\)$" nil t)
		     (replace-match (concat (match-string 1) (int-to-string (1+ (string-to-int (match-string 2)))))))
	    ))))))

;;------------------------------------------------------------

(defun rpm-spec-initialize ()
  "Create a default spec file if one does not exist or is empty."
  (let (file name version (release "1"))
    (setq file (if (buffer-file-name)
                   (file-name-nondirectory (buffer-file-name))
                 (buffer-name)))
    (string-match "\\(.*\\).spec" file)
    (setq name (match-string 1 file))

    (insert
	 "%define name " (or name "")
	 "\n%define version " (or version "")
	 "\n%define release %mkrel " (or release "")
	 "\n\nSummary:" (rpm-insert-space-or-tabs 1)
	 "\nName:" (rpm-insert-space-or-tabs 2) "%{name}"
	 "\nVersion:" (rpm-insert-space-or-tabs 1) "%{version}" 
	 "\nRelease:" (rpm-insert-space-or-tabs 1) "%{release}"
	 "\nSource0:" (rpm-insert-space-or-tabs 1) "%{name}-%{version}.tar.bz2"
	 "\nLicense:" (rpm-insert-space-or-tabs 1)
	 "\nGroup:" (rpm-insert-space-or-tabs 2)
	 "\nUrl:" (rpm-insert-space-or-tabs 2)
	 "\nBuildRoot:" (rpm-insert-space-or-tabs 1) "%{_tmppath}/%{name}-%{version}-%{release}-buildroot\n"
	 "\n\n%description\n"
	 "\n%prep\n%setup -q\n\n%build\n\n%install\nrm -rf %{buildroot}"
	 "\n\n\n%clean\nrm -rf %{buildroot}"
	 "\n\n%files\n%defattr(-,root,root)\n" 
	 "\n\n%changelog\n"))
    (goto-char (point-min)))

;;------------------------------------------------------------

(defun rpm-about-rpm-spec-mode (&optional arg)
  "About `rpm-spec-mode'."
  (interactive "p")
  (message
   (concat "rpm-spec-mode version "
           rpm-spec-mode-version
           " by Stig Bj�rlykke, <stigb@tihlde.org>")))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.spec$" . rpm-spec-mode))

(provide 'rpm-spec-mode)

;;; rpm-spec-mode.el ends here
