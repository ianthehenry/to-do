(use sh)
(import cmd)
(import ./fmt)
(import ./date)
(use ./util)

(def todo-file (lazy
  (or (os/getenv "TODO")
    (string (os/getenv "HOME") "/todo"))))

(def terminal-width (lazy (scan-number ($<_ tput cols))))

(def char-to-state {" " :todo "x" :done "-" :skip ">" :defer})
(def state-to-char (invert char-to-state))

(defn parse-state [state-str]
  (def char (string/slice state-str 0 1))
  (def arg (string/trim (string/slice state-str 1)))
  (def state
    (assert (char-to-state (string/slice char 0 1))
      (string/format "unknown state %q" char)))
  (if (empty? arg)
    state
    [state (date/parse arg)]))

(defn print-state [state]
  (def state-code (case (type state)
    :keyword state
    :tuple (first state)))
  (def state-char
    (assert (state-to-char state-code)
      (string/format "unknown state %q" state)))
  (match state
    [_ arg] (string/format "%s %s" state-char (date/to-string arg))
    state-char))

(defn trim-lines [str]
  (as-> str $
    (string/split "\n" $)
    (map string/trim $)
    (drop-while empty? $)
    (take-while (not- empty?) $)
    (string/join $ "\n")))

(def task-peg (peg/compile
  ~{:main (any (* :task (+ "\n" -1)))
    :state (/ (* "- [" ,(til "]")) ,parse-state)
    :text (/ (<- (to (+ "\n- [" -1))) ,trim-lines)
    :task (/ (* :state :text) ,|@{:state $0 :text $1})}))

(defn parse-tasks []
  (peg/match task-peg (slurp (todo-file))))

(defn print-task [{:state state :text text :highlight highlight}]
  (def decorate-text
    (case state
      :done fmt/strikethrough
      identity))
  (def color (if highlight
    (case state
      :skip fmt/yellow
      :defer fmt/yellow
      fmt/green)
    identity))
  (def decorate-all
    (comp color (cond
      (= state :todo) identity
      highlight identity
      fmt/dim)))

  (def leader (if highlight "*" "-"))

  (def prefix (string/format "%s [%s] " leader (print-state state)))
  (def indent (replace-str prefix (chr " ")))
  (def wrap-width (- (terminal-width) (length prefix)))
  (def wrapped-text ($< <,text fold -s -w ,wrap-width))
  (def lines (string/split "\n" wrapped-text))
  (eachp [i line] lines
    (printf "%s%s"
      (decorate-all (if (= i 0) prefix indent))
      (decorate-all (decorate-text line)))))

(defn defer? [state]
  (match state
    :defer true
    [:defer _] true
    false))

(defn should-print [{:state state :highlight highlight}]
  (or highlight (not (defer? state))))

(defn print-tasks [tasks]
  (each task (sort-by |(in $ :state) tasks)
    (if (should-print task)
      (print-task task))))

(defn save-tasks [tasks]
  (def output @"")
  (each {:state state :text text} tasks
    (buffer/push-string output
      (string/format "- [%s] %s\n" (print-state state) text)))
  (def temp-file (string (todo-file) ".bup"))
  (spit temp-file output)
  (os/rename temp-file (todo-file)))

(defn change-state [old-state new-state]
  (def tasks (parse-tasks))
  (def input @"")

  (def old-state-pred
    (case (type old-state)
      :keyword |(= $ old-state)
      :tuple |(index-of $ old-state)
      :function old-state
      (error "unknown state predicate")))

  (var any-todos false)
  (loop [[i {:state state :text text}] :pairs tasks
         :when (old-state-pred state)]
    (set any-todos true)
    (buffer/push-string input (string i))
    (buffer/push-string input " ")
    (buffer/push-string input text)
    (buffer/push-byte input 0))
  (unless any-todos
    (print "nothing to do!")
    (os/exit 0))

  (def output @"")
  (def [exit-code] (run fzf --height 10 --multi --print0 --with-nth "2.." --read0 <,input >,output))
  (def selections
    (case exit-code
      0 (drop -1 (string/split "\0" output))
      1 []
      2 (error "fzf error")
      130 []
      (error "unknown error")))

  (each selection selections
    (def task-index (scan-number (first-word selection)))
    (def task (in tasks task-index))
    (set (task :state) new-state)
    (set (task :highlight) true))
  (print-tasks tasks)
  (unless (empty? selections)
    (save-tasks tasks)))

(defn append-task [state text]
  (with [f (file/open (todo-file) :a)]
    (file/write f (string/format "- [%s] %s\n" (print-state state) text)))
  (print-task {:state state :text text}))

(def task/arg ["<task>" :string])

(cmd/defn to-do
  "add or list tasks"
  [task (optional task/arg)]
  (if task
    (append-task :todo task)
    (print-tasks (parse-tasks))))

(cmd/defn to-edit "open the task list" []
  (def editor (string/split " " (or (os/getenv "VISUAL") (os/getenv "EDITOR") "vim")))
  ($ ,;editor ,(todo-file)))

(cmd/main (cmd/group
  "A very simple task manager."
  do to-do
  undo (cmd/fn "mark a task todo" [] (change-state |(not= $ :todo) :todo))
  done (cmd/fn "finish a task" [] (change-state :todo :done))
  did (cmd/fn "add a finished task" [task (required task/arg)] (append-task :done task))
  dont (cmd/fn "skip a task" [] (change-state :todo :skip))
  defer (cmd/fn "schedule a task for later" [date (required date/arg)] (change-state :todo [:defer date]))
  edit to-edit))
