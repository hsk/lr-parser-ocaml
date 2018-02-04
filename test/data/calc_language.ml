open Token
open Lexer
open Language

let lex: lexDefinition = [
  "DIGITS",   Reg("[1-9][0-9]*"),      None;
  "PLUS",     Str("+"),                None;
  "ASTERISK", Str("*"),                None;
  "LPAREN",   Str("("),                None;
  "RPAREN",   Str(")"),                None;
  "",         Reg("(\\r\\n|\\r|\\n)+"),None;
  "",         Reg("[ \\f\\t]+"),       None;
  "INVALID",  Reg("."),                None;
]

let grammar: grammarDefinition = [
  "EXP", ["EXP"; "PLUS"; "TERM"], Some(fun(c,_) -> Obj.magic((Obj.magic List.nth c(0) : int) + (Obj.magic List.nth c(2) : int)));
  "EXP", ["TERM"], Some(fun(c,_) -> List.nth c(0));
  "TERM", ["TERM"; "ASTERISK"; "ATOM"], Some(fun(c,_) -> Obj.magic((Obj.magic List.nth c(0) : int) * (Obj.magic List.nth c(2) : int)));
  "TERM", ["ATOM"], Some(fun(c,_) -> List.nth c(0));
  "ATOM", ["DIGITS"], Some(fun(c,_) -> Obj.magic(int_of_string(List.nth c(0))));
  "ATOM", ["LPAREN"; "EXP"; "RPAREN"], Some(fun(c,_) -> List.nth c(1));
]

let language = language(grammar,"EXP")

open Parser

let parsing_table = [
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
]
