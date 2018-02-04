open OUnit
open Token
open Language
open Parser

let test () =
  let ((_,parsing_table) as table) = Parsergenerator.generate Calc_language.language in
  let lexer = Lexer.create Calc_language.lex in
  let parser = Parser.create Calc_language.grammar table lexer in
  "test parser" >::: [
    "parser factory" >:: begin fun () ->
      (*Printf.printf "%s\n%!" (Parser.show(parsing_table));*)
      assert_equal Calc_language.parsing_table parsing_table;
    end;

    "custom callback in grammar" >:: begin fun () ->
      (*Printf.printf "%s\n" (Precompiler.exec_parsing_table parsing_table);*)
      assert(Obj.magic(parser "2*(3+4)") = 14)
    end;
  ]
