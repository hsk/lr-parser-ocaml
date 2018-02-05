open OUnit
open Token
open Language
open Parser

let lex: Lexer.lexDefinition = [
  "",        Reg"\\(\\r\\n\\|\\r\\|\\n\\)+",None;
  "",        Reg"[ \\t]+",                  None;
  "NUM",     Reg"[1-9][0-9]*",              None;
  "+",       Str"+",                        None;
  "*",       Str"*",                        None;
  "INVALID", Reg".",                        None;
]

let grammar: grammarDefinition = [
  "E",["E";"+";"T"],  Some(fun([c0;_;c2],_) -> string_of_int((int_of_string c0) + (int_of_string c2)));
  "E",["T"],          Some(fun([c0],_) -> c0);
  "T",["T";"*";"NUM"],Some(fun([c0;_;c2],_) -> string_of_int((int_of_string c0) * (int_of_string c2)));
  "T",["NUM"],        Some(fun([c0],_) -> c0);
]

let language = (grammar,"E")

let parsing_table : parsingTable = [
  ["NUM",Shift(2);                                            "E",Goto(1);"T",Goto(3);]; (* 0 *)
  [               "+",Shift (4);              "EOF",Accept   ;                        ]; (* 1 *)
  [               "+",Reduce(3);"*",Reduce(3);"EOF",Reduce(3);                        ]; (* 2 *)
  [               "+",Reduce(1);"*",Shift (5);"EOF",Reduce(1);                        ]; (* 3 *)
  ["NUM",Shift(2);                                                        "T",Goto(6);]; (* 4 *)
  ["NUM",Shift(7);                                                                    ]; (* 5 *)
  [               "+",Reduce(0);"*",Shift (5);"EOF",Reduce(0);                        ]; (* 6 *)
  [               "+",Reduce(2);"*",Reduce(2);"EOF",Reduce(2);                        ]; (* 7 *)
]

let test () =
  (*Parser.debug_mode := true;*)
  let parser = Parser.create grammar ("",parsing_table) (Lexer.create lex) in
  "calc test" >::: [
    "8"       >:: (fun _ -> assert(parser "8"       = "8"));
    "2*3+4"   >:: (fun _ -> assert(parser "2*3+4"   = "10"));
    "1+2*3"   >:: (fun _ -> assert(parser "1+2*3"   = "7"));
    "1+2"     >:: (fun _ -> assert(parser "1+2"     = "3"));
  ]

let _ = run_test_tt_main(test())
