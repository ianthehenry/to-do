(declare-project
  :name "todo"
  :description "a very simple todo list"
  :dependencies [
    {:url "https://github.com/ianthehenry/cmd.git"
     :tag "v1.1.0"}
     {:url "https://github.com/andrewchambers/janet-sh.git"
      :tag "221bcc869bf998186d3c56a388c8313060bfd730"}
  ])

(declare-executable
  :name "to"
  :entry "src/main.janet")
