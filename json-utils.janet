## JSON utils
(defn get-json-path
  "Get a dot separated path from a JSON object / Table"
  [path js]
  (let [path (string/split "." path)]
    (reduce (fn [acc it] (acc it)) js path)))

(defn filter-jsonarray-by-path
  [path needle jsonarr]
  (filter
    (fn [item]
      (= (get-json-path path item)
         needle))
    jsonarr))

(defn item-is-login [item]
  (= (get-json-path "category" item) "LOGIN"))

(defn item-is-password [item]
  (= (get-json-path "category" item) "PASSWORD"))

(defn item-has-password [item]
  (any? ((juxt item-is-password item-is-login) item)))

(def item-title (partial get-json-path "title"))
(def item-fields (partial get-json-path "fields"))
(def details-password (partial get-json-path "details.password"))

(defn field-value-by-purpose [purpose item]
  (-?>> item
    (item-fields)
    (filter-jsonarray-by-path "purpose" purpose)
    (first)
    (get-json-path "value")))

(def password-from-fields (partial field-value-by-purpose "PASSWORD"))
(def username-from-fields (partial field-value-by-purpose "USERNAME"))

(defn item-password [item]
  (password-from-fields item))

