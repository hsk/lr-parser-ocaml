open OUnit
open Token
open Language
open Parser
open Parsergenerator

let test () =
  let parsing_table = generateParsingTable Calc_language.language in
  let lexer = Lexer.create Calc_language.lex in
  let parser = Parser.create Calc_language.grammar parsing_table lexer in
  "test parser" >::: [
    "parser factory" >:: begin fun () ->
      (*Printf.printf "%s\n%!" (Parser.show(parsing_table));*)
      assert_equal [
        ["ATOM",Goto(1);"DIGITS",Shift(2);"EXP",Goto(3);"LPAREN",Shift(4);"TERM",Goto(5)];
        ["ASTERISK",Reduce(3);"EOF",Reduce(3);"PLUS",Reduce(3);"RPAREN",Reduce(3)];
        ["ASTERISK",Reduce(4);"EOF",Reduce(4);"PLUS",Reduce(4);"RPAREN",Reduce(4)];
        ["EOF",Accept;"PLUS",Shift(6)];
        ["ATOM",Goto(1);"DIGITS",Shift(2);"EXP",Goto(7);"LPAREN",Shift(4);"TERM",Goto(5)];
        ["ASTERISK",Shift(8);"EOF",Reduce(1);"PLUS",Reduce(1);"RPAREN",Reduce(1)];
        ["ATOM",Goto(1);"DIGITS",Shift(2);"LPAREN",Shift(4);"TERM",Goto(9)];
        ["PLUS",Shift(6);"RPAREN",Shift(10)];
        ["ATOM",Goto(11);"DIGITS",Shift(2);"LPAREN",Shift(4)];
        ["ASTERISK",Shift(8);"EOF",Reduce(0);"PLUS",Reduce(0);"RPAREN",Reduce(0)];
        ["ASTERISK",Reduce(5);"EOF",Reduce(5);"PLUS",Reduce(5);"RPAREN",Reduce(5)];
        ["ASTERISK",Reduce(2);"EOF",Reduce(2);"PLUS",Reduce(2);"RPAREN",Reduce(2)];
      ] parsing_table;
    end;

    "custom callback in grammar" >:: begin fun () ->
      (*Printf.printf "%s\n" (Precompiler.exec_parsing_table parsing_table);*)
      assert(Obj.magic(parser "2*(3+4)") = 14)
    end;
  ]
