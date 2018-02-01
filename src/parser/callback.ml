open Token
open Language

type ast = ASTNode of Token.token * string * ast list

let rec show = function
  | ASTNode(t,s,ls) -> Printf.sprintf "ASTNode(%S,%S,[%s])" t s (show_ls ls)
and show_ls ls = String.concat ";" (List.map show ls)

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

(* ASTを構築するコントローラ *)
let makeASTConstructor (Language(lex,grammer,_)) = {
  callLex = begin fun ((id: int), (value: any)) ->
    let (token,_,_,_) = List.nth lex id in
    Obj.magic(ASTNode(token, Obj.magic value, []))
  end;
  callGrammar = fun ((id: int), (children: any list)) ->
    let (ltoken,_,_) = List.nth grammer id in
    Obj.magic(ASTNode(ltoken, Obj.magic "", Obj.magic children))
}
