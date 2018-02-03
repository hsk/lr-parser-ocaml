type token = string (* トークン名 *)
type any = string
type tokenizedInput = token * any (* トークン名と、字句規則にマッチした元々の入力 *)

let show (t:token):string = t

type ptn = Str of string | Reg of string (* パターン *)
type lexCallback = (any * any) -> any (* 字句規則マッチ時に呼び出されるコールバック *)
type lexRule = token * ptn * int * lexCallback option (* 単一の字句ルール *)
type lexDefinition = lexRule list(* 字句規則 *)
type lexer = string -> tokenizedInput list

let show_ptn = function
  | Str(s) -> Printf.sprintf "Str(%S)" s
  | Reg(s) -> Printf.sprintf "Reg(%S)" s
let show_lexRule = function
  | (token,ptn,int,None) -> Printf.sprintf "(%S,%s,%d,None)"  token (show_ptn ptn) int
  | (token,ptn,int,Some(_)) -> Printf.sprintf "(%S,%s,%d,Some(_))" token (show_ptn ptn) int  
let show_lexDef ls = "[" ^ String.concat ";" (List.map show_lexRule ls) ^ "]"
let show_ts ts = "[" ^ String.concat ";" (List.map (fun t -> Printf.sprintf "%S" t) ts) ^ "]"

module S = Set.Make(struct
  type t=token
  let compare=String.compare
end)
module M = struct
  module M = Map.Make(struct
    type t=token
    let compare=String.compare
  end)
  include M
  let fold_left f v t = List.fold_left f v (M.bindings t)
end

module MI = struct
  module MI = Map.Make(struct
    type t=int
    let compare i ii = i - ii
  end)
  include MI
  let fold_left f v t = List.fold_left f v (M.bindings t)
end
