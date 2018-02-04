open OUnit
open Language
open Rule_parser
open Parser

let test () =
  let input = read("language") in
  let lexer = Lexer.create Rule_parser.lex in
  let table = Parsergenerator.generate Rule_parser.language in
  let parse = Parser.create Rule_parser.grammar table lexer in
  (* language_parserと同一のものであることが期待される *)
  "language parsing test" >::: [
    "parsing language file" >:: begin fun () ->
      assert_equal ~printer:Language.show (Obj.magic (parse input)) Language_language.language
    end;
    (* languageファイルを読み取ってパーサを生成したい *)
    "language_parser" >:: begin fun () ->
      assert_equal  ~printer:Language.show (Obj.magic (rule_parse lexer input)) Language_language.language
    end;
  ]

(* TODO: languageファイルにコールバックも記述可能にして、それを読み取れるようにする *)
