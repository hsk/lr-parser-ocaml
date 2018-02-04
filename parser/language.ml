open Token

type grammarCallback = (any list * token) -> any (* 構文のreduce時に呼び出されるコールバック *)
type grammarRule = token * token list * grammarCallback option (* 単一の構文ルール *)
type grammarDefinition = grammarRule list (* 構文規則 *)

type language = lexDefinition * grammarDefinition * token (* 言語定義 *)
let language(lex,grammar,start)=(lex,grammar,start)

let show_grammarRule = function
  | (token,ts,None) -> Printf.sprintf "(%S,%s,None)"  token (show_ts ts)
  | (token,ts,Some(_)) -> Printf.sprintf "(%S,%s,Some(_))" token (show_ts ts)  
let show_grammarDef ls = "[" ^ String.concat ";" (List.map show_grammarRule ls) ^ "]"

let show (lex,grammar,start) =
  Printf.sprintf "language(%s,%s,%S)" (show_lexDef lex) (show_grammarDef grammar) start
