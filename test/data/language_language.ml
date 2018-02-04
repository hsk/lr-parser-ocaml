open Token
open Language

let lex: lexDefinition = [
  "EXCLAMATION", Str"!",                     None;
  "VBAR",        Str"|",                     None;
  "DOLLAR",      Str"$",                     None;
  "COLON",       Str":",                     None;
  "SEMICOLON",   Str";",                     None;
  "LABEL",       Reg"[a-zA-Z_][a-zA-Z0-9_]*",None;
  "REGEXP",      Reg"\\/.*\\/[gimuy]*",      None;
  "STRING",      Reg"\".*\"",                None;
  "STRING",      Reg"'.*'",                  None;
  "",            Reg"\\(\r\n\\|\r\\|\n\\)+", None;
  "",            Reg"[ \t]+",                None;
  "INVALID",     Reg".",                     None;
]

let grammar: grammarDefinition = [
  "LANGUAGE",  ["LEX";"GRAMMAR"],                      None;
  "LEX",       ["LEX";"LEXSECT"],                      None;
  "LEX",       ["LEXSECT"],                            None;
  "LEXSECT",   ["LEXLABEL";"LEXDEF"],                  None;
  "LEXLABEL",  ["LABEL"],                              None;
  "LEXLABEL",  ["EXCLAMATION"],                        None;
  "LEXLABEL",  ["EXCLAMATION";"LABEL"],                None;
  "LEXDEF",    ["STRING"],                             None;
  "LEXDEF",    ["REGEXP"],                             None;
  "GRAMMAR",   ["SECT";"GRAMMAR"],                     None;
  "GRAMMAR",   ["SECT"],                               None;
  "SECT",      ["SECTLABEL";"COLON";"DEF";"SEMICOLON"],None;
  "SECTLABEL", ["LABEL"],                              None;
  "SECTLABEL", ["DOLLAR";"LABEL"],                     None;
  "DEF",       ["PATTERN";"VBAR";"DEF"],               None;
  "DEF",       ["PATTERN"],                            None;
  "PATTERN",   ["SYMBOLLIST"],                         None;
  "PATTERN",   [],                                     None;
  "SYMBOLLIST",["LABEL";"SYMBOLLIST"],                 None;
  "SYMBOLLIST",["LABEL"],                              None;
]

let language = language(lex, grammar, "LANGUAGE")
