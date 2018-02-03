type token = string (* トークン名 *)
type any = string
type tokenizedInput = token * any (* トークン名と、字句規則にマッチした元々の入力 *)

type ptn = Str of string | Reg of string (* パターン *)
type lexCallback = (any * any) -> any (* 字句規則マッチ時に呼び出されるコールバック *)
type lexRule = token * ptn * lexCallback option (* 単一の字句ルール *)
type lexDefinition = lexRule list(* 字句規則 *)
type lexer = string -> tokenizedInput list

let show_ptn = function
  | Str(s) -> Printf.sprintf "Str(%S)" s
  | Reg(s) -> Printf.sprintf "Reg(%S)" s
let show_lexRule = function
  | (token,ptn,None) -> Printf.sprintf "(%S,%s,None)"  token (show_ptn ptn)
  | (token,ptn,Some(_)) -> Printf.sprintf "(%S,%s,Some(_))" token (show_ptn ptn)
let show_lexDef ls = "[" ^ String.concat ";" (List.map show_lexRule ls) ^ "]"
let show_ts ts = "[" ^ String.concat ";" (List.map (fun t -> Printf.sprintf "%S" t) ts) ^ "]"
