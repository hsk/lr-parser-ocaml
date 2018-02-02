open OUnit
open Ruleparser
open Parsergenerator
open Parser
open Language_language

let read filename =
  let lines = ref [] in
  let chan = open_in filename in
  try
    while true; do
      lines := input_line chan :: !lines
    done;
    ""
  with End_of_file ->
    close_in chan;
    String.concat "\n" (List.rev !lines)

let test () =
  let input = read("language") in
  let table = generateParsingTable rule_language in
  let parser = Parser.create rule_language table in
  let lexer = Lexer.create rule_language in
  (* language_parserと同一のものであることが期待される *)
  "language parsing test" >::: [
    "parsing language file" >:: begin fun () ->
      assert_equal ~printer:Language.show (Obj.magic (parse parser lexer input)) language_language_without_callback
    end;
    (* languageファイルを読み取ってパーサを生成したい *)
    "language_parser" >:: begin fun () ->
      assert_equal  ~printer:Language.show (Obj.magic (parse rule_parser lexer input)) language_language_without_callback
    end;
  ]

(* TODO: languageファイルにコールバックも記述可能にして、それを読み取れるようにする *)
