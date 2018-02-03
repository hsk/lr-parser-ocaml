open Token
open Language

let test_sample_grammar: grammarDefinition = [
  "S", ["E"], None;
  "E", ["LIST"; "SEMICOLON"], None;
  "E", ["HOGE"], None;
  "LIST", ["T"], None;
  "LIST", ["LIST"; "SEPARATE"; "T"], None;
  "T", ["ATOM"], None;
  "T", [], None;
  "HOGE", ["ID"], None;
]
let test_sample_lex: lexDefinition = [
  "ATOM",      Str("x"),0,None;
  "ID",        Reg("[a-zA-Z_][a-zA-Z0-9_]*"),0,None;
  "SEMICOLON", Str(";"),0,None;
  "SEPARATE",  Str("|"),0,None;
  "", Reg("(\\r\\n|\\r|\\n)+"),0,None;
  "", Reg("[ \\f\\t]+"),0,None;
  "INVALID",   Reg("."),0,None;
]

let test_sample_language = {lex=test_sample_lex; grammar=test_sample_grammar; start="S"}

let test_empty_language = {lex=[]; grammar=["S", [], None];start="S"}

let test_calc_grammar: grammarDefinition = [
  "EXP", ["EXP"; "PLUS"; "TERM"], Some(fun(c,_) -> Obj.magic((Obj.magic List.nth c(0) : int) + (Obj.magic List.nth c(2) : int)));
  "EXP", ["TERM"], Some(fun(c,_) -> List.nth c(0));
  "TERM", ["TERM"; "ASTERISK"; "ATOM"], Some(fun(c,_) -> Obj.magic((Obj.magic List.nth c(0) : int) * (Obj.magic List.nth c(2) : int)));
  "TERM", ["ATOM"], Some(fun(c,_) -> List.nth c(0));
  "ATOM", ["DIGITS"], Some(fun(c,_) -> Obj.magic(int_of_string(List.nth c(0))));
  "ATOM", ["LPAREN"; "EXP"; "RPAREN"], Some(fun(c,_) -> List.nth c(1));
]

let test_calc_lex: lexDefinition = [
  "DIGITS", Reg("[1-9][0-9]*"),0,None;
  "PLUS", Str("+"),0,None;
  "ASTERISK", Str("*"),0,None;
  "LPAREN", Str("("),0,None;
  "RPAREN", Str(")"),0,None;
  "", Reg("(\\r\\n|\\r|\\n)+"),0,None;
  "", Reg("[ \\f\\t]+"),0,None;
  "INVALID", Reg("."),0,None;
]

let test_calc_language = {lex=test_calc_lex;grammar=test_calc_grammar;start="EXP"}

let test_calc_language_raw_string = "
  DIGITS      /[1-9][0-9]*/
  PLUS        \"+\"
  ASTERISK    \"*\"
  LPAREN      \"(\"
  RPAREN      \")\"
  !ENDLINE    /(\\r\\n|\\r|\\n)+/
  !WHITESPACE /[ \\f\\t]+/
  INVALID     /./

  $EXP : EXP PLUS TERM | TERM;
  TERM : TERM ASTERISK ATOM | ATOM;
  ATOM : DIGITS | LPAREN EXP RPAREN;
"
