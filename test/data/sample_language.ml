open Token
open Lexer
open Language

let grammar: grammarDefinition = [
  "S", ["E"], None;
  "E", ["LIST"; "SEMICOLON"], None;
  "E", ["HOGE"], None;
  "LIST", ["T"], None;
  "LIST", ["LIST"; "SEPARATE"; "T"], None;
  "T", ["ATOM"], None;
  "T", [], None;
  "HOGE", ["ID"], None;
]
let lex: lexDefinition = [
  "ATOM",      Str("x"),None;
  "ID",        Reg("[a-zA-Z_][a-zA-Z0-9_]*"),None;
  "SEMICOLON", Str(";"),None;
  "SEPARATE",  Str("|"),None;
  "", Reg("(\\r\\n|\\r|\\n)+"),None;
  "", Reg("[ \\f\\t]+"),None;
  "INVALID",   Reg("."),None;
]

let language = language(grammar,"S")
