open OUnit
open Token
open Language
open Ast
open Parser

let test () =
  let parsingtable = Parsergenerator.generate test_calc_language in
  let parser = Ast.createParser test_calc_language.grammar parsingtable in
  "parser test" >::: [
    "getting calc language ast" >:: begin fun () ->
      (*let (ast : ast) = Obj.magic(parser (test_calc_language.lex) "1") in
      Printf.printf "ast=%s\n%!" (Callback.show ast);*)
      assert(Obj.magic(parser (Ast.createLex test_calc_language.lex) "1+1") =
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
      assert(Obj.magic(parser (Ast.createLex test_calc_language.lex) "1zzz") = ASTNode("DIGITS", "1", []))
    end;
  ]
