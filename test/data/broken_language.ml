open Language

(*
trait E
case class EString(f:String) extends E
case class EInt(f:Int) extends E
let g = List[(String,List[String])](
  ("EXP", ["EXP"; "PLUS"; "EXP"], {case [EInt(c0),EString(c1),EInt(c2)) => EInt(c0 + c2)}),
  ("EXP", ["TERM"), {case [EInt(c0)) => EInt(c0)}),
  ("TERM", ["TERM"; "ASTERISK"; "ATOM"), {case [EInt(c0),EString(c1),EInt(c2)) => EInt(c0 * c2)}),
  ("TERM", ["ATOM"), {case [EInt(c0)) => EInt(c0) }),
  ("ATOM", ["DIGITS"), {case [EString(c0)) => EInt(c0.toInt)}),
  ("ATOM", ["LPAREN"; "EXP"; "RPAREN"), {case [EString(c0),EInt(c1),EString(c2)) => EInt(c1)})
)*)

let test_broken_grammar: grammarDefinition = [
  "EXP", ["EXP"; "PLUS"; "EXP"], Some(fun (c,_)-> Obj.magic((Obj.magic List.nth c(0) :int) + (Obj.magic List.nth c(2) :int)));
  "EXP", ["TERM"], Some(fun (c,_)-> List.nth c(0));
  "TERM", ["TERM"; "ASTERISK"; "ATOM"], Some(fun (c,_)-> Obj.magic((Obj.magic List.nth c(0) :int) * (Obj.magic List.nth c(2) :int)));
  "TERM", ["ATOM"], Some(fun (c,_)-> List.nth c(0));
  "ATOM", ["DIGITS"], Some(fun (c,_)-> Obj.magic(int_of_string (List.nth c(0))));
  "ATOM", ["LPAREN"; "EXP"; "RPAREN"], Some(fun (c,_)-> List.nth c(1));
]

let test_broken_lex: lexDefinition = [
  "DIGITS", Reg("[1-9][0-9]*"),0,None;
  "PLUS", Str("+"),0,None;
  "ASTERISK", Str("*"),0,None;
  "LPAREN", Str("("),0,None;
  "RPAREN", Str(")"),0,None;
  "", Reg("\(\r\n\|\r\|\n\)+"),0,None;
  "", Reg("[ \t]+"),0,None;
  "INVALID", Reg("."),0,None;
]

let test_broken_language = language(test_broken_lex, test_broken_grammar, "EXP")
