(import cmd)

(defn to-string [{:year year :month month :day day}]
  (string/format "%04d-%02d-%02d" year month day))

(def peg (peg/compile
  ~{:main (/ (* :year "-" :month "-" :day)
             ,|{:year $0  :month $1  :day $2})
      :year (number (4 :d))
      :month (number (2 :d))
      :day (number (2 :d))}))

(def arg (cmd/peg "<date>" peg))

(defn parse [str]
  (def [date] (peg/match peg str))
  date)

(defn today []
  (def {:year year :month month :month-day day} (os/date))
  {:year year :month (+ month 1) :day day})
