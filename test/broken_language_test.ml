open OUnit
open Lexer
open Parser
open Language
open Token

let grammar: grammarDefinition = [
  "EXP", ["EXP"; "PLUS"; "EXP"], Some(fun (c,_)-> Obj.magic((Obj.magic List.nth c(0) :int) + (Obj.magic List.nth c(2) :int)));
  "EXP", ["TERM"], Some(fun (c,_)-> List.nth c(0));
  "TERM", ["TERM"; "ASTERISK"; "ATOM"], Some(fun (c,_)-> Obj.magic((Obj.magic List.nth c(0) :int) * (Obj.magic List.nth c(2) :int)));
  "TERM", ["ATOM"], Some(fun (c,_)-> List.nth c(0));
  "ATOM", ["DIGITS"], Some(fun (c,_)-> Obj.magic(int_of_string (List.nth c(0))));
  "ATOM", ["LPAREN"; "EXP"; "RPAREN"], Some(fun (c,_)-> List.nth c(1));
]

let lex: lexDefinition = [
  "DIGITS",  Reg"[1-9][0-9]*",          None;
  "PLUS",    Str"+",                    None;
  "ASTERISK",Str"*",                    None;
  "LPAREN",  Str"(",                    None;
  "RPAREN",  Str")",                    None;
  "",        Reg"\\(\r\n\\|\r\\|\n\\)+",None;
  "",        Reg"[ \t]+",               None;
  "INVALID", Reg".",                    None;
]

let language: language = (lex, grammar, "EXP")

let test () =
  let table = Parsergenerator.generate language in
  let lexer = Lexer.create lex in
  let parser = Parser.create grammar table lexer in
  "Calculator test with broken language" >::: [
    (* TODO: パーサが壊れていることを(コンソール出力以外で)知る方法 *)
    "parsing table is broken" >:: begin fun () ->
      let table = Parsergenerator.generate language in
      let _ = Parser.create grammar table in
      assert_equal (Parsergenerator.isConflicted()) true;
      assert_equal !Parsergenerator.table_type "CONFLICTED";
    end;
    "\"1+1\" equals 2" >:: begin fun () ->
      assert_equal (Obj.magic (parser "1+1")) 2
    end;
    "\"( 1+1 )*3 + ( (1+1) * (1+2*3+4) )\\n\" equals 28 (to be failed)" >:: begin fun () ->
      assert ((Obj.magic (parser "( 1+1 )*3 + ( (1+1) * (1+2*3+4) )\n"):int) <> 28)
    end;
  ]
