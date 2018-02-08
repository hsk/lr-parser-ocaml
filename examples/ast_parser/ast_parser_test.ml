open OUnit
open Token
open Language
open Ast
open Parser

let test () =
  let parsingtable = Parsergenerator.generate Calc_language.language in
  let parser = Ast.createParser Calc_language.grammar parsingtable in
  "ast parser test" >::: [
    "getting calc language ast" >:: begin fun () ->
      assert(Obj.magic(parser (Ast.createLex Calc_language.lex) "1+1") =
        ASTNode("EXP", "",
          [ ASTNode("EXP", "", [
              ASTNode("TERM", "", [
                ASTNode("ATOM", "", [
                  ASTNode("DIGITS", "1", [])])])]);
            ASTNode("PLUS", "+", []);
            ASTNode("TERM", "", [
              ASTNode("ATOM", "", [
                ASTNode("DIGITS", "1", [])])])
          ])
      )
    end;
    "invalid input" >:: begin fun () ->
      assert(Obj.magic(parser (Ast.createLex Calc_language.lex) "1zzz") = ASTNode("DIGITS", "1", []))
    end;
  ]
