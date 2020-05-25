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

