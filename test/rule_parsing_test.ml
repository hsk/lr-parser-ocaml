open OUnit
open Lexer
open Language
open Parser
open Rule_parser

let test () =
  let input = read("language") in
  let lexer = Lexer.create Rule_parser.lex in
  "rule parsing test" >::: [
    "language_parser" >:: begin fun () ->
      assert_equal ~printer:Rule_parser.show (Obj.magic (rule_parse lexer input)) (Language_language.lex,Language_language.language)
    end;
  ]

let _ = run_test_tt_main(test())
