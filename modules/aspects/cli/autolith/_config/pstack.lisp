;;;; pstack.lisp -- trial of the pstack (poteto-mode) workflow inside Autolith.
;;;;
;;;; init.lisp loads this file. Each feature is :on, :shadow or :off.
;;;; :shadow changes nothing and only logs what the feature would have done.
;;;;
;;;;   :catalog  Larger skill catalog budget, so descriptions are not cut short.
;;;;   :core     Request-local pstack routing and Autolith harness mapping for
;;;;             the primary agent, and the poteto-mode worker.md rules for
;;;;             child agents. Nothing enters conversation history.
;;;;   :guards   Refuse shell.run and resource.edit calls that break the
;;;;             workspace rules listed in *guards*.
;;;;
;;;; At the Autolith prompt:
;;;;   (pstack)               modes and event counts
;;;;   (pstack :core :on)     set one feature; saved across restarts
;;;;   (pstack :all :off)     turn everything off now
;;;;   (pstack :report)       the most recent events
;;;;
;;;; Modes:  ~/.local/state/autolith/pstack-modes.sexp
;;;; Events: ~/.local/state/autolith/pstack-events.sexp
;;;; Remove completely: delete the pstack form in init.lisp and restart.

(defpackage #:pstack-autolith
  (:use #:cl)
  (:local-nicknames (#:al #:autolith)))

(in-package #:pstack-autolith)


;;;; Modes and event log

(defparameter *state-directory*
  (merge-pathnames ".local/state/autolith/" (user-homedir-pathname)))

(defparameter *modes-file*  (merge-pathnames "pstack-modes.sexp" *state-directory*))
(defparameter *events-file* (merge-pathnames "pstack-events.sexp" *state-directory*))

(defparameter *default-modes* '(:catalog :on :core :shadow :guards :shadow))

(defvar *modes* nil "Feature modes read from *modes-file*.")
(defvar *lock* (sb-thread:make-mutex :name "pstack"))

(defun mode (feature)
  (or (getf *modes* feature) (getf *default-modes* feature)))

(defun read-modes ()
  (setf *modes*
        (or (ignore-errors
             (with-open-file (in *modes-file* :if-does-not-exist nil)
               (and in (let ((*read-eval* nil)) (read in nil nil)))))
            (copy-list *default-modes*))))

(defun write-modes ()
  (ensure-directories-exist *modes-file*)
  (let ((temporary (make-pathname :type "tmp" :defaults *modes-file*)))
    (with-open-file (out temporary :direction :output :if-exists :supersede)
      (with-standard-io-syntax (prin1 *modes* out)))
    (rename-file temporary *modes-file*)))

(defun clip (string limit)
  (if (and (stringp string) (> (length string) limit))
      (subseq string 0 limit)
      string))

(defun note (feature kind &rest details)
  "Append one event to *events-file*. Never signals."
  (ignore-errors
   (sb-thread:with-mutex (*lock*)
     (ensure-directories-exist *events-file*)
     (with-open-file (out *events-file* :direction :output
                                        :if-exists :append :if-does-not-exist :create)
       (with-standard-io-syntax
         (let ((*print-readably* nil))
           (prin1 (list* :time (get-universal-time) :feature feature
                         :mode (mode feature) :kind kind details)
                  out)
           (terpri out)))))))

(defun read-events ()
  (ignore-errors
   (with-open-file (in *events-file* :if-does-not-exist nil)
     (when in
       (let ((*read-eval* nil))
         (loop for event = (ignore-errors (read in nil :eof))
               until (eq event :eof)
               when (consp event) collect event))))))


;;;; :catalog

(defvar *original-catalog-budget* al::*skill-catalog-character-budget*)

(defparameter *catalog-budget* 16000
  "Fits about 60 skills at the 200-character description limit.")

(defun apply-catalog ()
  (setf al::*skill-catalog-character-budget*
        (if (eq (mode :catalog) :on) *catalog-budget* *original-catalog-budget*)))


;;;; :core

(defparameter *core-instruction*
  "PSTACK CORE (operator setup in ~/.config/autolith/pstack.lisp).
Work in poteto-mode without being asked. For any non-trivial task, call skill.load poteto-mode, pick the matching playbook (Investigation, Bug fix, Feature, Refactoring, Perf issue, Prototype, Session pickup, Shipping, Babysit, Autonomous run, Multi-phase plan, and the others it lists) and follow it. Quick questions and one-line edits skip this.
Read pstack text through these Autolith equivalents:
- Task or subagent: child.spawn, with isolation for children that write. Read-only fan-out: rlm.map with a JSON contract.
- poteto-agent: a child whose task starts with \"Read ~/.agents/skills/poteto-mode/worker.md before anything else.\"
- Model settings: ~/.config/autolith/pstack-models.md. rlm.* accept model and effort. child.spawn always uses the parent model.
- todolist: plan.update. /loop: async jobs or mission.schedule-add, never sleep loops. AskQuestion: none, decide and report.
- Transcripts: channel:current history and ~/.local/share/autolith/conversations/<id>/.
- Skill edits: Autolith-only changes go to ~/.config/autolith/skills/, not the shared ~/.agents/skills/.
Leave state the user can read and edit: keep plan.update current during multi-step work, add an agenda item for work that spans turns, and record reusable decisions as memory:facts with sources. Turn a repeated correction into a procedure, contract or memory rather than more prose.")

(defparameter *worker-file*
  (merge-pathnames ".agents/skills/poteto-mode/worker.md" (user-homedir-pathname)))

(defun worker-instruction ()
  "Return the current worker.md rules for a child agent, or NIL."
  (let ((text (ignore-errors (uiop:read-file-string *worker-file*))))
    (when text
      (format nil "PSTACK WORKER RULES (from ~A). They apply to you as a child agent:~2%~A"
              (namestring *worker-file*) (clip text 4000)))))

(defparameter *conversations-directory*
  (merge-pathnames ".local/share/autolith/conversations/" (user-homedir-pathname)))

(defun child-request-p (request)
  "True when the requesting participant's parent is an agent, not the person.
The primary agent's parent is the human participant, which has no conversation."
  (let* ((participant (ignore-errors (al::request-context-participant request)))
         (parent      (and (typep participant 'al::participant)
                           (al::participant-parent participant))))
    (and (stringp parent)
         (every #'alphanumericp parent)
         (probe-file (merge-pathnames (concatenate 'string parent "/")
                                      *conversations-directory*))
         t)))

(defvar *last-user-text* (make-hash-table :test 'equal :synchronized t)
  "Latest user text seen per conversation, so each message is logged once.")

(defun note-once-per-message (request feature kind &rest details)
  (let* ((conversation (ignore-errors
                        (al::conversation-identifier
                         (al::request-context-conversation request))))
         (text (ignore-errors (al::request-context-latest-user-text request)))
         (key  (princ-to-string conversation)))
    (unless (equal (gethash key *last-user-text*) text)
      (setf (gethash key *last-user-text*) text)
      (apply #'note feature kind :conversation key :user (clip text 80) details))))

(al::define-context-contributor pstack-core-context (request)
  "Contribute pstack routing to primary requests and worker.md rules to children."
  (handler-case
      (unless (or (eq (mode :core) :off)
                  (al::request-context-compaction-p request)
                  ;; Internal calls such as the permission classifier offer no tools.
                  (zerop (length (al::request-context-tool-namespaces request))))
        (let* ((child-p     (child-request-p request))
               (identifier  (if child-p "pstack-worker" "pstack-core"))
               (instruction (if child-p (worker-instruction) *core-instruction*)))
          (when instruction
            (note-once-per-message request :core
                                   (if (eq (mode :core) :on) :injected :would-inject)
                                   :what identifier)
            (when (eq (mode :core) :on)
              (al::make-context-contribution
               :identifier        identifier
               :instruction       instruction
               :priority          20
               :class             :advice
               :deduplication-key identifier)))))
    (error (condition)
      (note :core :error :message (princ-to-string condition))
      nil)))


;;;; :guards

(defparameter *platform* "/platform(\\.[^/]+)?/?$"
  "Working directories of the platform repository and its sibling workspaces.")

(defparameter *guards*
  (list
   (list :id        "nix-develop"
         :tool      "shell.run" :field "command"
         :workspace *platform*
         :pattern   "\\bnix\\s+develop\\b[^;&|]*\\s-c\\b"
         :message   "AGENTS.md: run dev-shell commands as `direnv exec <root> <command>`. `nix develop -c` re-evaluates the flake on every call and hangs on `devenv up`.")
   (list :id        "generated-workflows"
         :tool      "resource.edit" :field "uri"
         :workspace *platform*
         :pattern   "\\.github/workflows/[^/]+\\.ya?ml$|(^|/)cog\\.toml$"
         :message   "AGENTS.md: .github/workflows/*.yaml and cog.toml are generated from nix/default.nix. Edit that and run `nix run .#write-files`.")
   (list :id        "git-mutation"
         :tool      "shell.run" :field "command"
         :workspace *platform*
         :pattern   "(^|[;&|(`]|\\s)(git(\\s+-C\\s+\\S+)?\\s+(commit|stash|reset|revert|push|rebase|merge|cherry-pick|restore|clean|checkout|switch|am)|jj\\s+(commit|describe|new|squash|abandon|rebase|restore|edit|split|git\\s+push))\\b"
         :except    "\\bgit\\s+stash\\s+(list|show)\\b"
         :overridable t
         :message   "AGENTS.md: git or jj commands that change data need an explicit request in the current user message."))
  "Workspace rules enforced at tool-call time. Each matches one argument FIELD of TOOL.")

(defun guard-violation (tool context arguments)
  "Return the first guard that ARGUMENTS of TOOL break, and the offending value."
  (let ((name      (al::tool-canonical-name tool))
        (directory (ignore-errors
                    (namestring
                     (al::config :working-directory
                                 (al::tool-context-configuration context))))))
    (when directory
      (dolist (guard *guards*)
        (let ((value (and (string= name (getf guard :tool))
                          (al::json-get arguments (getf guard :field)))))
          (when (and (stringp value)
                     (cl-ppcre:scan (getf guard :workspace) directory)
                     (cl-ppcre:scan (getf guard :pattern) value)
                     (not (and (getf guard :except)
                               (cl-ppcre:scan (getf guard :except) value)))
                     (not (and (getf guard :overridable)
                               (search (format nil "pstack:allow ~A" (getf guard :id))
                                       value))))
            (return (values guard value))))))))

(defun guarded-execute (original tool context arguments)
  (multiple-value-bind (guard value)
      (handler-case (guard-violation tool context arguments)
        (error (condition)
          (note :guards :error :message (princ-to-string condition))
          nil))
    (cond
      ((null guard)
       (funcall original tool context arguments))
      ((eq (mode :guards) :on)
       (note :guards :refused :guard (getf guard :id) :value (clip value 200))
       (al::tool-failure
        (format nil "pstack guard ~A refused this call; it was not made. ~A~@[ If the user explicitly asked for exactly this in the current message, rerun it with the shell comment `# pstack:allow ~A`.~]"
                (getf guard :id) (getf guard :message)
                (and (getf guard :overridable) (getf guard :id)))
        :code :precondition-unmet))
      (t
       (note :guards :would-refuse :guard (getf guard :id) :value (clip value 200))
       (funcall original tool context arguments)))))

(defun apply-guards ()
  (let ((installed-p (sb-int:encapsulated-p 'al::tool-execute-with-contracts 'pstack-guards)))
    (cond ((and (eq (mode :guards) :off) installed-p)
           (sb-int:unencapsulate 'al::tool-execute-with-contracts 'pstack-guards))
          ((and (not (eq (mode :guards) :off)) (not installed-p))
           (sb-int:encapsulate 'al::tool-execute-with-contracts 'pstack-guards
                               (lambda (original &rest arguments)
                                 (apply #'guarded-execute original arguments)))))))


;;;; Command

(defparameter *feature-names* '(:catalog :core :guards))

(defun apply-modes ()
  (apply-catalog)
  (apply-guards))

(defun event-counts ()
  (let ((counts (make-hash-table :test 'equal)))
    (dolist (event (read-events))
      (incf (gethash (list (getf event :feature) (getf event :kind)) counts 0)))
    (sort (loop for key being the hash-keys of counts using (hash-value count)
                collect (append key (list count)))
          #'string< :key (lambda (row) (format nil "~A ~A" (first row) (second row))))))

(defun al::pstack (&optional feature new-mode)
  "Inspect or change the pstack trial.
(pstack) shows modes and event counts. (pstack :report) shows recent events.
(pstack FEATURE MODE) sets FEATURE (:catalog, :core, :guards or :all) to
:on, :shadow or :off, saves it and applies it at once."
  (cond
    ((null feature)
     (list :modes (loop for f in *feature-names* append (list f (mode f)))
           :events (event-counts)
           :log (namestring *events-file*)))
    ((eq feature :report)
     (last (read-events) 20))
    (t
     (assert (member new-mode '(:on :shadow :off)) (new-mode)
             "Mode must be :on, :shadow or :off.")
     (dolist (f (if (eq feature :all) *feature-names* (list feature)))
       (assert (member f *feature-names*) (f) "Unknown pstack feature ~S." f)
       (setf (getf *modes* f) new-mode)
       (note f :mode-set))
     (write-modes)
     (apply-modes)
     (al::pstack))))


;;;; Load

(read-modes)
(apply-modes)
