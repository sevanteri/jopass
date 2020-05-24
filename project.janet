(declare-project
  :name "janet1pass"
  :description "Janet wrapper for 1password's cli tool"
  :dependencies ["https://github.com/sevanteri/janet-secret"
                 "json"
                 "process"
                 "argparse"])

(declare-executable
  :name "j1pass"
  :entry "main.janet")
