## libsecret stuff
(import secret)

(def- schema
  "libsecret schema to save the 1pw cli session token"
  {:name "jopass.sessiontoken"
   :attributes {"shorthand" :string
                :app :jopass}})

(defn save-token [shorthand token]
  (if (secret/save-password
        schema
        @{"shorthand" shorthand
          :app :jopass}
        :session
        (string "jopass " shorthand)
        token)
    token))

(defn get-token [shorthand]
  (secret/lookup-password
     schema
     @{"shorthand" shorthand
       :app :jopass}))

(defn remove-token [shorthand]
  (secret/remove-password
     schema
     @{"shorthand" shorthand
       :app :jopass}))

