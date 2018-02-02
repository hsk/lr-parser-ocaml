open Token
open Language

type ast = ASTNode of Token.token * string * ast list

let rec show = function
  | ASTNode(t,s,ls) -> Printf.sprintf "ASTNode(%S,%S,[%s])" t s (show_ls ls)
and show_ls ls = String.concat ";" (List.map show ls)

(* ASTを構築するコントローラ *)
let makeASTConstructor {lex;grammar} = {
  callLex = begin fun ((id: int), (value: any)) ->
    let (token,_,_,_) = List.nth lex id in
    Obj.magic(ASTNode(token, Obj.magic value, []))
  end;
  callGrammar = fun ((id: int), (children: any list)) ->
    let (ltoken,_,_) = List.nth grammar id in
    Obj.magic(ASTNode(ltoken, Obj.magic "", Obj.magic children))
}

let createLex lang = Lexer.exec (makeASTConstructor lang) (getLexer lang)
let createParser language parsingtable = (getGrammar language, parsingtable, makeASTConstructor language)
