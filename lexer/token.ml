type token = string (* トークン名 *)
type any = string
type tokenizedInput = token * any (* トークン名と、字句規則にマッチした元々の入力 *)

type lexer = string -> tokenizedInput list

let show_ts ts = "[" ^ String.concat ";" (List.map (fun t -> Printf.sprintf "%S" t) ts) ^ "]"
