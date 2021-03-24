(import json)
(import ./json-utils :prefix "")

(def home-path ((os/environ) "HOME"))

(def config-path
  (string (get (os/environ) "XDG_CONFIG_HOME"
               (string home-path "/.config"))
          "/jopass"))

(def pw-file-path
  (string config-path "/pass.gpg"))

(def last-use-path
  (string config-path "/last_used"))

(def op-config-path
  (string home-path "/.op/config"))
(def opconfig (json/decode (slurp op-config-path)))
(def latest-signin (opconfig "latest_signin"))
(def shorthands (map (partial get-json-path "shorthand") (opconfig "accounts")))

(defn last-use-duration []
  (let [last-use (os/stat last-use-path :changed)]
    (if (not (nil? last-use))
      (- (os/time) last-use))))

