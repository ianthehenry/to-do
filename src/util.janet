(defmacro lazy [expr]
  (with-syms [$result $forced]
  ~(do
    (var ,$result nil)
    (var ,$forced false)
    (fn []
      (if ,$forced
        ,$result
        (do
          (set ,$forced true)
          (set ,$result ,expr)))))))

(defn replace-str [str char]
  (def buf (buffer str))
  (eachk i buf
    (put buf i char))
  buf)

(defn not- [f] (comp not f))

(defn til [arg] ~(* (<- (to ,arg)) ,arg))

(defn first-word [str]
  (take-while |(not= $ (chr " ")) str))

