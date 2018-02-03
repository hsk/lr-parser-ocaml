open OUnit
open Ruleparser
open Parser
open Language_language

let test () =
  let input = read("language") in
  let lexer = Lexer.create rule_language.lex in
  "language parsing test" >::: [
    "language_parser" >:: begin fun () ->
      assert_equal ~printer:Language.show (Obj.magic (rule_parse lexer input)) language_language_without_callback
    end;
  ]

let _ = run_test_tt_main(test())