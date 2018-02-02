open Token

type ptn = Str of string | Reg of string (* パターン *)

type lexCallback = (any * any) -> any (* 字句規則マッチ時に呼び出されるコールバック *)
type lexRule = token * ptn * int * lexCallback option (* 単一の字句ルール *)
type lexDefinition = lexRule list(* 字句規則 *)

type grammarCallback = (any list * token) -> any (* 構文のreduce時に呼び出されるコールバック *)
type grammarRule = token * token list * grammarCallback option (* 単一の構文ルール *)
type grammarDefinition = grammarRule list (* 構文規則 *)

type language = Language of lexDefinition * grammarDefinition * token (* 言語定義 *)

let getLexer (Language(lex,_,_)) = lex
let getGrammar (Language(_,grammar,_)) = grammar
let getStart (Language(_,_,token)) = token

let show_ptn = function
| Str(s) -> Printf.sprintf "Str(%S)" s
| Reg(s) -> Printf.sprintf "Reg(%S)" s
let show_lexRule = function
| (token,ptn,int,None) -> Printf.sprintf "(%S,%s,%d,None)"  token (show_ptn ptn) int
| (token,ptn,int,Some(_)) -> Printf.sprintf "(%S,%s,%d,Some(_))" token (show_ptn ptn) int  
let show_lexDef ls = "[" ^ String.concat ";" (List.map show_lexRule ls) ^ "]"
let show_ts ts = "[" ^ String.concat ";" (List.map (fun t -> Printf.sprintf "%S" t) ts) ^ "]"
let show_grammarRule = function
| (token,ts,None) -> Printf.sprintf "(%S,%s,None)"  token (show_ts ts)
| (token,ts,Some(_)) -> Printf.sprintf "(%S,%s,Some(_))" token (show_ts ts)  
let show_grammarDef ls = "[" ^ String.concat ";" (List.map show_grammarRule ls) ^ "]"

let show = function
  | Language(lex,grammar,token) ->
    Printf.sprintf "Language(%s,%s,%S)" (show_lexDef lex) (show_grammarDef grammar) token

(* 字句解析・構文解析時に呼び出されるコールバックを管理するコントローラー *)
(* いわゆるStrategyパターン *)
type callbackController = {
  callLex: int * any -> any;
  callGrammar: int * any list -> any;
}

(* 言語情報に付随するコールバックを呼び出すコントローラ *)
let makeDefaultConstructor (Language(lex,grammer,_)) = {
  callLex = begin fun ((id: int), (value: any)) ->
    match List.nth lex id with
    | (token,_,_,Some(callback)) -> callback(value, Obj.magic token)
    | _ -> value
  end;
  callGrammar = fun ((id: int), (children: any list)) ->
    match List.nth grammer id with
    | (ltoken,_,Some(callback)) -> callback(children, ltoken)
    | _ -> List.nth children 0
}
