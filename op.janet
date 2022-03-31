## 1Password cli wrappers
(import json)
(import ./json-utils :as "ju")
(import ./configs :prefix "")
(import ./secrets :as "s")

(defn token-err? [str]
  (truthy? (or (string/find "session expired" str)
               (string/find "Invalid session token" str))))

(defn signin
  `Sign in with 1password cli. Password is decrypted from a GPG file.
  Returns a new session token`
  [&opt shorthand]
  (default shorthand latest-signin)
  (let [gpg_proc (os/spawn ["gpg" "-qd" pw-file-path] :p {:out :pipe})
        gpg_ret (:wait gpg_proc)]
    (when (zero? gpg_ret)
      (def op_proc (os/spawn
                     ["op" "signin" "--account" shorthand "--raw"]
                     :px
                     {:in (gpg_proc :out) :out :pipe}))
      (:wait op_proc)
      (string/trim (:read (op_proc :out) :all)))))

(defn token-valid?
  "Checks if the token is still valid. Returns a boolean."
  [token shorthand]
  (cond
    (nil? token) false
    (if (< (last-use-duration) 1800) # 30min
      true
      (do
        (s/remove-token shorthand)
        false))))

(defn get-new-token-and-save [&opt shorthand]
  (default shorthand latest-signin)
  (let [token (signin shorthand)]
    (s/save-token shorthand token)
    (os/touch last-use-path)
    token))

(defn maybe-renew-token [token &opt shorthand]
  (default shorthand latest-signin)
  (if (token-valid? token shorthand)
    token
    (get-new-token-and-save shorthand)))

(defn get-token [&opt shorthand]
  (default shorthand latest-signin)
  (maybe-renew-token (s/get-token shorthand) shorthand))

(defn op [token shorthand & args]
  (let [proc (os/spawn ["op" "--cache"
                        "--format" "json"
                        "--session" token
                        "--account" shorthand
                        ;(map string args)]
                       :p
                       {:out :pipe :err :pipe})] 
    (if (zero? (:wait proc))
      (let [out (:read (proc :out) :all)]
        (do
          (os/touch last-use-path)
          (json/decode out)))
      (let [err (:read (proc :err) :all)]
        (if (token-err? err)
          (op (get-new-token-and-save shorthand)
              shorthand
              ;args)
          (do
            (print err)
            (os/exit 1)))))))


(defn list-items [token shorthand]
 (op token shorthand :item :list "--categories=Password,Login"))

(defn get-item [token shorthand name]
  (op token shorthand :item :get name))

(defn get-totp [token shorthand name]
  (ju/get-json-path "totp" (op token shorthand :item :get "--field" "type=otp" name)))

(defn get-password [token shorthand name]
  (ju/item-password (get-item token shorthand name)))

(defn get-username [token shorthand name]
  (ju/username-from-fields (get-item token shorthand name)))

(defn get-titles [token shorthand]
  (sorted (map ju/item-title (list-items token shorthand))))

(defn check-shorthand [shorthand]
  (if (nil? (find (partial = shorthand) shorthands))
    (do (print (string "Account shorthand '" shorthand "' not found."))
      (os/exit 1))))

(defn get-passwords [token &opt shorthand]
    (-?>> (list-items token shorthand)
          (map ju/item-title)
          (sorted)
          (map print)))
