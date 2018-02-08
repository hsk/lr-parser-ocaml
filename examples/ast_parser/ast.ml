open Token
open Language

type ast = ASTNode of Token.token * string * ast list

let rec show = function
  | ASTNode(t,s,ls) -> Printf.sprintf "ASTNode(%S,%S,[%s])" t s (show_ls ls)
and show_ls ls = String.concat ";" (List.map show ls)

let createLex lex = Lexer.exec lex (fun (id, value) ->
  let (token,_,_) = List.nth lex id in
  Obj.magic(ASTNode(token, value, []))
)

let createParser grammar (_,parsingtable) =
  Parser.parse grammar parsingtable (fun (id, children) ->
    let (ltoken,_,_) = List.nth grammar id in
    Obj.magic(ASTNode(ltoken, Obj.magic "", Obj.magic children))
  )
