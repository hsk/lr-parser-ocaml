open Token
open Language
let lex: lexDefinition = [
  "EXCLAMATION", Str("!"),0,None;
  "VBAR", Str("|"),0,None;
  "DOLLAR", Str("$"),0,None;
  "COLON", Str(":"),0,None;
  "SEMICOLON", Str(";"),0,None;
  "LABEL", Reg("[a-zA-Z_][a-zA-Z0-9_]*"),0,None;
  "REGEXP", Reg("\\/.*\\/[gimuy]*"),0,None;
  "STRING", Reg("\".*\""),0,None;
  "STRING", Reg("'.*'"),0,None;
  "", Reg("\\(\r\n\\|\r\\|\n\\)+"),0,None;
  "", Reg("[ \t]+"),0,None;
  "INVALID", Reg("."),0,None;
]

let grammar: grammarDefinition = [
  "LANGUAGE", ["LEX"; "GRAMMAR"], None;
  "LEX", ["LEX"; "LEXSECT"], None;
  "LEX", ["LEXSECT"], None;
  "LEXSECT", ["LEXLABEL"; "LEXDEF"], None;
  "LEXLABEL", ["LABEL"], None;
  "LEXLABEL", ["EXCLAMATION"], None;
  "LEXLABEL", ["EXCLAMATION"; "LABEL"], None;
  "LEXDEF", ["STRING"], None;
  "LEXDEF", ["REGEXP"], None;
  "GRAMMAR", ["SECT"; "GRAMMAR"], None;
  "GRAMMAR", ["SECT"], None;
  "SECT", ["SECTLABEL"; "COLON"; "DEF"; "SEMICOLON"], None;
  "SECTLABEL", ["LABEL"], None;
  "SECTLABEL", ["DOLLAR"; "LABEL"], None;
  "DEF", ["PATTERN"; "VBAR"; "DEF"], None;
  "DEF", ["PATTERN"], None;
  "PATTERN", ["SYMBOLLIST"], None;
  "PATTERN", [], None;
  "SYMBOLLIST", ["LABEL"; "SYMBOLLIST"], None;
  "SYMBOLLIST", ["LABEL"], None;
]

let language_language_without_callback = language(lex, grammar, "LANGUAGE")
