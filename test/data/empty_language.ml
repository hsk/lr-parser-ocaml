open Token
open Language

let lex: lexDefinition = []

let grammar: grammarDefinition = ["S", [], None]

let language = language(lex,grammar,"S")
