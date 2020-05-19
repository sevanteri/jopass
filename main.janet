
(defn get-home-path []
  ((os/environ) "HOME"))

(defn get-config-path []
  (string (get (os/environ) "XDG_CONFIG_HOME"
               (string (get-home-path) "/.config"))
          "/janet1pass"))

(defn initialize
  "Create config dir at least"
  []
  (os/mkdir (get-config-path)))


(defn get-op-config-path []
  (string (get-home-path) "/.op/config"))

(defn get-token-from-file []
  (if-with [f (file/open (string (get-config-path) "/token") :r)]
    (let [token (file/read f :line)]
      (string/trim token))))

(defn get-pw-file-path []
  (string (get-config-path) "/pass.gpg"))

(defn save-token-to-file [token]
  (if-with [f (file/open (string (get-config-path) "/token"))]
    (file/write f token)))

(defn signin []
  (if-with [f (file/popen (string "gpg -qd " (get-pw-file-path) " | op signin --raw") :r)]
    (string/trim (file/read f :line))))

(defn check-login [token]
  (os/execute string("op get account --session " token)))

(defn get-token []
  (var token "foo"))

(defn main [&]
  (let [token (get-token)]
    (print token)))
  

