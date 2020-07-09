(import process)
(import argparse :prefix "")
(import configs)
(import op)


(defn copy [pw &opt selection]
  (default selection "clipboard")
  (process/run ["xclip" "-selection" selection]
    :redirects [[stdin (string/trim (string pw))]]))

(defn type-it [pw]
  (process/run ["xdotool" "type" "--clearmodifiers" "--file" "-"]
    :redirects [[stdin (string/trim (string pw))]]))

(defn initialize
  "Create config dir if not present. Guide first steps."
  []
  (os/mkdir configs/config-path)
  (if (nil? (os/stat configs/pw-file-path))
    (do
      (print "Encrypt your 1Password with GPG to " configs/pw-file-path)
      (os/exit 1)))
  (if (nil? (os/stat configs/last-use-path))
    (spit configs/last-use-path "")))

(def- argparse-args
  ["Print/copy/type your 1Password passwords/usernames/TOTPs easily."
   :default {:kind :option}
   "account" {:kind :option
              :short "a"
              :help "Account shorthand"}
   "totp" {:kind :flag
           :short "t"
           :help "Get TOTP code"}
   "username" {:kind :flag
               :short "u"
               :help "Get username"}
   "copy" {:kind :flag
           :short "c"
           :help "Copy to clipboard"}
   "type" {:kind :flag
           :short "T"
           :help "Type it"}])

(defn main [&]
  (initialize)
  (let [args (or (argparse ;argparse-args) @{})
        help (find (fn [a] (or (= a "--help") (= a "-h"))) (dyn :args))
        shorthand (or (args "account") configs/latest-signin)
        query (args :default)
        totp (args "totp")
        username (args "username")
        _copy (args "copy")
        _type-it (args "type")]
    (if (not help)
      (do
        (op/check-shorthand shorthand)
        (let [token (op/get-token shorthand)
              fun (cond
                    _copy copy
                    _type-it type-it
                    print)]
          (cond
            (and totp query) (fun (op/get-totp token shorthand query))
            (and username query) (fun (op/get-username token shorthand query))
            query (fun (op/get-password token shorthand query))
            (op/get-passwords token shorthand)))))))
