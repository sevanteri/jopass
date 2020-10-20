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
  (= (get-json-path "templateUuid" item) "001"))

(defn item-is-password [item]
  (= (get-json-path "templateUuid" item) "005"))

(defn item-has-password [item]
  (any? ((juxt item-is-password item-is-login) item)))

(def overview-title (partial get-json-path "overview.title"))
(def details-fields (partial get-json-path "details.fields"))
(def details-password (partial get-json-path "details.password"))

(defn field-by-designation [designation item]
  (-?>> item
    (details-fields)
    (filter-jsonarray-by-path "designation" designation)
    (first)
    (get-json-path "value")))

(def password-from-fields (partial field-by-designation "password"))
(def username-from-fields (partial field-by-designation "username"))

(defn get-password [item]
  (cond
    (item-is-password item) (details-password item)
    (item-is-login item) (password-from-fields item)))

