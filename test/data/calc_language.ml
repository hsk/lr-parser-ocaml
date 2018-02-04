open Token
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

let language = language(lex,grammar,"EXP")
