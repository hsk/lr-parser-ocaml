open OUnit
open Language
open Ruleparser
open Parsergenerator
open Parser
open Language_language

let test () =
  let input = read("language") in
  let table = generateParsingTable rule_language in
  let parse = Parser.create rule_language.grammar table in
  let lexer = Lexer.create rule_language.lex in
  (* language_parserと同一のものであることが期待される *)
  "language parsing test" >::: [
    "parsing language file" >:: begin fun () ->
      assert_equal ~printer:Language.show (Obj.magic (parse lexer input)) language_language_without_callback
    end;
    (* languageファイルを読み取ってパーサを生成したい *)
    "language_parser" >:: begin fun () ->
      assert_equal  ~printer:Language.show (Obj.magic (rule_parse lexer input)) language_language_without_callback
    end;
  ]

(* TODO: languageファイルにコールバックも記述可能にして、それを読み取れるようにする *)
