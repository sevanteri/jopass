(import secret)
(import json)
(import process)
(import argparse :prefix "")

(def- schema
  "libsecret schema to save the 1pw cli session token"
  {:name "org.janet1pass.sessiontoken"
   :attributes {"shorthand" :string
                :app :janet1pass}})

(def home-path ((os/environ) "HOME"))

(def config-path
  (string (get (os/environ) "XDG_CONFIG_HOME"
               (string home-path "/.config"))
          "/janet1pass"))

(defn initialize
  "Create config dir at least"
  []
  (os/mkdir config-path))

(def pw-file-path
  (string config-path "/pass.gpg"))

(defn _save-token [shorthand token]
  (if (secret/save-password
        schema
        @{"shorthand" shorthand
          :app :janet1pass}
        :session
        (string "janet1pass " shorthand)
        token)
    token))

(defn _get-token [shorthand]
  (secret/lookup-password
     schema
     @{"shorthand" shorthand
       :app :janet1pass}))

(defn remove-token [shorthand]
  (secret/remove-password
     schema
     @{"shorthand" shorthand
       :app :janet1pass}))


## JSON utils
(defn get-json-path
  "Get a dot separated path from a JSON object / Table"
  [path js]
  (let [path (string/split "." path)]
    (reduce (fn [acc it] (acc it)) js path)))

(defn filter-jsonarray-by-path
  [path what jsonarr]
  (filter
    (fn [item]
      (= (get-json-path path item)
         what))
    jsonarr))

(def get-title (partial get-json-path "overview.title"))
(def get-fields (partial get-json-path "details.fields"))
(def only-passwords (partial filter-jsonarray-by-path "templateUuid" "001"))

## 1PW commands
(defn op [token shorthand & args]
  (def buf @"")
  (if (zero? (process/run ["op" "--session" token ;args]
                          :redirects [[stderr :null] [stdout buf]]))
    (json/decode buf)))

(defn list-items [token shorthand]
 (op token shorthand :list :items))

(defn get-item [token shorthand name]
  (op token shorthand :get :item name))

(defn get-totp [token shorthand name]
  (op token shorthand :get :totp name))

(defn get-password [token shorthand name]
  (->> (get-item token shorthand name)
       (get-fields)
       (filter-jsonarray-by-path "designation" "password")
       (first)
       (get-json-path "value")))

(defn get-username [token shorthand name]
  (->> (get-item token shorthand name)
       (get-fields)
       (filter-jsonarray-by-path "designation" "username")
       (first)
       (get-json-path "value")))

(defn get-titles [token shorthand]
  (sorted (map get-title (list-items token shorthand))))

(def op-config-path
  (string home-path "/.op/config"))
(def opconfig (json/decode (slurp op-config-path)))
(def latest_signin (opconfig "latest_signin"))
(def shorthands (map (partial get-json-path "shorthand") (opconfig "accounts")))

(defn signin
  `Sign in with 1password cli. Password is decrypted from a GPG file.
  Returns a new session token`
  [&opt shorthand]
  (default shorthand latest_signin)
  # TODO: change to process/run
  (if-with [f (file/popen
                (string "gpg -qd "
                        pw-file-path
                        " | op signin " shorthand
                        " --raw")
                :r)]
    (string/trim (file/read f :line))))

(defn check-token
  "Checks if the token is still valid. Returns the token or nil"
  [token shorthand]
  (if (zero? (process/run ["op" "get" "account" "--session" (or token "")]
                          :redirects [[stdout :null] [stderr :null]]))
    token
    (do (remove-token shorthand)
      nil)))


(defn get-new-token-and-save [&opt shorthand]
  (default shorthand latest_signin)
  (let [token (signin shorthand)]
    (_save-token shorthand token)))

(defn maybe-renew-token [token &opt shorthand]
  (default shorthand latest_signin)
  (if (check-token token shorthand)
    token
    (get-new-token-and-save shorthand)))

(defn get-token [&opt shorthand]
  (default shorthand latest_signin)
  (maybe-renew-token (_get-token shorthand) shorthand))

(defn- check-shorthand [shorthand]
  (if (nil? (find (partial = shorthand) shorthands))
    (do (print (string "Account shorthand '" shorthand "' not found."))
      (os/exit 1))))

(defn get-passwords [token &opt shorthand]
    (-?>> (list-items token shorthand)
          (only-passwords)
          (map get-title)
          (sorted)
          (map print)))

(def- argparse-args
  ["Desc"
   :default {:kind :option}
   "account" {:kind :option
              :short "a"
              :help "Account shorthand"}
   "totp" {:kind :flag
           :short "t"
           :help "Get TOTP code"}
   "username" {:kind :flag
               :short "u"
               :help "Get username"}])

(defn main [&]
  (initialize)
  (let [args (argparse ;argparse-args)
        shorthand (or (args "account") latest_signin)
        arg (args :default)
        totp (args "totp")
        username (args "username")]
    (check-shorthand shorthand)
    (let [token (get-token shorthand)]
      (cond
        (and totp arg) (print (get-totp token shorthand arg))
        (and username arg) (print (get-username token shorthand arg))
        arg (print (get-password token shorthand arg))
        (get-passwords token shorthand)))))
