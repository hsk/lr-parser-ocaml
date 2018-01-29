(**
  * トークン名
  *)
type token = string

(**
  * トークン化された入力
  * トークン名と、字句規則にマッチした元々の入力
  *)
type 'n tokenizedInput = (token * 'n)

(**
  * 入力の終端を表す終端記号名
  * @type {symbol}
  *)
let symbol_eof: token = "EOF"

(**
  * `S' -> S $` (Sは開始記号)となるような非終端記号S'を表す非終端記号名
  * @type {symbol}
  *)
let symbol_syntax: token = "S'"

let show (t:token):string = t
