(declare-project
  :name "jopass"
  :description "Janet wrapper for 1password's cli tool"
  :dependencies ["https://github.com/sevanteri/janet-secret"
                 "json"
                 "argparse"])

(declare-executable
  :name "jopass"
  :entry "main.janet")
