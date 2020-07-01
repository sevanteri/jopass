## 1Password cli wrappers
(import process)
(import json)
(import json-utils :prefix "")
(import configs :prefix "")
(import secrets :prefix "")

(defn token-err? [str]
  (truthy? (or (string/find "session expired" str)
               (string/find "Invalid session token" str))))

(defn signin
  `Sign in with 1password cli. Password is decrypted from a GPG file.
  Returns a new session token`
  [&opt shorthand]
  (default shorthand latest-signin)
  # TODO: change to process/run
  (if-with [f (file/popen
                (string "gpg -qd "
                        pw-file-path
                        " | op signin " shorthand
                        " --raw")
                :r)]
    (string/trim (file/read f :line))))

(defn token-valid?
  "Checks if the token is still valid. Returns a boolean."
  [token shorthand]
  (cond
    (nil? token) false
    (if (< (last-use-duration) 1800) # 30min
      true
      (do
        (_remove-token shorthand)
        false))))

(defn get-new-token-and-save [&opt shorthand]
  (default shorthand latest-signin)
  (let [token (signin shorthand)]
    (_save-token shorthand token)
    (os/touch last-use-path)
    token))

(defn maybe-renew-token [token &opt shorthand]
  (default shorthand latest-signin)
  (if (token-valid? token shorthand)
    token
    (get-new-token-and-save shorthand)))

(defn get-token [&opt shorthand]
  (default shorthand latest-signin)
  (maybe-renew-token (_get-token shorthand) shorthand))

(defn op [token shorthand & args]
  (def out @"")
  (def err @"")
  (if (zero? (process/run ["op" "--session" token
                           "--account" shorthand
                           ;args]
                          :redirects [[stderr err] [stdout out]]))
    (do
      (os/touch last-use-path)
      (json/decode out))
    (if (token-err? err)
      (op (get-new-token-and-save shorthand)
          shorthand
          ;args))))


(defn list-items [token shorthand]
 (op token shorthand :list :items))

(defn get-item [token shorthand name]
  (op token shorthand :get :item name))

(defn get-totp [token shorthand name]
  (op token shorthand :get :totp name))

(defn get-password [token shorthand name]
  (-?>> (get-item token shorthand name)
       (get-fields)
       (filter-jsonarray-by-path "designation" "password")
       (first)
       (get-json-path "value")))

(defn get-username [token shorthand name]
  (-?>> (get-item token shorthand name)
       (get-fields)
       (filter-jsonarray-by-path "designation" "username")
       (first)
       (get-json-path "value")))

(defn get-titles [token shorthand]
  (sorted (map get-title (list-items token shorthand))))

(defn check-shorthand [shorthand]
  (if (nil? (find (partial = shorthand) shorthands))
    (do (print (string "Account shorthand '" shorthand "' not found."))
      (os/exit 1))))

(defn get-passwords [token &opt shorthand]
    (-?>> (list-items token shorthand)
          (only-passwords)
          (map get-title)
          (sorted)
          (map print)))
