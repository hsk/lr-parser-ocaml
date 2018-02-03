open OUnit
open Token
open Language
open Parser
open Sample_language
open Parsergenerator

let test () =
  "test grammar input with callback" >::: [
    "custom callback in grammar" >:: begin fun () ->
      let parsing_table = generateParsingTable test_calc_language in
      (*Printf.printf "%s\n" (Precompiler.exec_parsing_table parsing_table);*)
      let parser = Parser.create test_calc_language.grammar parsing_table in
      assert(Obj.magic(parser (Lexer.create test_calc_language.lex) "2*(3+4)") = 14)
    end;
  ]
