open OUnit
open Token
open Language
open Parser

let lex: lexDefinition = [
  "",        Reg"\\(\\r\\n\\|\\r\\|\\n\\)+",None;
  "",        Reg"[ \\t]+",                  None;
  "DIGITS",  Reg"[1-9][0-9]*",              None;
  "PLUS",    Str"+",                        None;
  "ASTERISK",Str"*",                        None;
  "LPAREN",  Str"(",                        None;
  "RPAREN",  Str")",                        None;
  "INVALID", Reg".",                        None;
]

let grammar: grammarDefinition = [
  "EXP", ["EXP";"PLUS";"TERM"],     Some(fun([c0;_;c2],_) -> Obj.magic((Obj.magic c0) + (Obj.magic c2)));
  "EXP", ["TERM"],                  Some(fun([c0],_) -> c0);
  "TERM",["TERM";"ASTERISK";"ATOM"],Some(fun([c0;_;c2],_) -> Obj.magic((Obj.magic c0) * (Obj.magic c2)));
  "TERM",["ATOM"],                  Some(fun([c0],_) -> c0);
  "ATOM",["DIGITS"],                Some(fun([c0],_) -> Obj.magic(int_of_string c0));
  "ATOM",["LPAREN";"EXP";"RPAREN"], Some(fun([_;c1;_],_) -> c1);
]

let language = (lex,grammar,"EXP")

let parsing_table : parsingTable = [
  ["ATOM",Goto(1);"DIGITS",Shift(2);"EXP",Goto(3);"LPAREN",Shift(4);"TERM",Goto(5);];
  ["ASTERISK",Reduce(3);"EOF",Reduce(3);"PLUS",Reduce(3);"RPAREN",Reduce(3);];
  ["ASTERISK",Reduce(4);"EOF",Reduce(4);"PLUS",Reduce(4);"RPAREN",Reduce(4);];
  ["EOF",Accept;"PLUS",Shift(6);];
  ["ATOM",Goto(1);"DIGITS",Shift(2);"EXP",Goto(7);"LPAREN",Shift(4);"TERM",Goto(5);];
  ["ASTERISK",Shift(8);"EOF",Reduce(1);"PLUS",Reduce(1);"RPAREN",Reduce(1);];
  ["ATOM",Goto(1);"DIGITS",Shift(2);"LPAREN",Shift(4);"TERM",Goto(9);];
  ["PLUS",Shift(6);"RPAREN",Shift(10);];
  ["ATOM",Goto(11);"DIGITS",Shift(2);"LPAREN",Shift(4);];
  ["ASTERISK",Shift(8);"EOF",Reduce(0);"PLUS",Reduce(0);"RPAREN",Reduce(0);];
  ["ASTERISK",Reduce(5);"EOF",Reduce(5);"PLUS",Reduce(5);"RPAREN",Reduce(5);];
  ["ASTERISK",Reduce(2);"EOF",Reduce(2);"PLUS",Reduce(2);"RPAREN",Reduce(2);];
]

let test () =
  let parser = Parser.create grammar parsing_table (Lexer.create lex) in
  "calc test" >::: [
    "123"     >:: (fun _ -> assert(Obj.magic(parser "123"    ) = 123));
    "1\n+ 1"  >:: (fun _ -> assert(Obj.magic(parser "1+1"    ) = 2));
    "2*3+4"   >:: (fun _ -> assert(Obj.magic(parser "2*3+4"  ) = 10));
    "2*(3+4)" >:: (fun _ -> assert(Obj.magic(parser "2*(3+4)") = 14));
  ]

let _ = run_test_tt_main(test())
