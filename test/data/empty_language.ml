open Token
open Lexer
open Language

let lex: lexDefinition = []

let grammar: grammarDefinition = ["S", [], None]

let language = language(grammar,"S")
