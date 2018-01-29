package pg.data

import pg.language.{Language, LexDefinition, GrammarDefinition,GrammarRule,LexRule,Ptn,Reg,Str,reg}

object language_language {

  val lex: LexDefinition = List(
    LexRule("EXCLAMATION", Str("!"),0,None),
    LexRule("VBAR", Str("|"),0,None),
    LexRule("DOLLAR", Str("$"),0,None),
    LexRule("COLON", Str(":"),0,None),
    LexRule("SEMICOLON", Str(";"),0,None),
    LexRule("LABEL", Reg("""[a-zA-Z_][a-zA-Z0-9_]*"""),0,None),
    LexRule("REGEXP", Reg("\\/.*\\/[gimuy]*"),0,None),
    LexRule("STRING", Reg("\".*\""),0,None),
    LexRule("STRING", Reg("'.*'"),0,None),
    LexRule(null, Reg("""(\r\n|\r|\n)+"""),0,None),
    LexRule(null, Reg("[ \\f\\t\\v\\u00a0\\u1680\\u180e\\u2000-\\u200a\\u202f\\u205f\\u3000\\ufeff]+"),0,None),
    LexRule("INVALID", Reg("."),0,None)
  )

  val grammar: GrammarDefinition = List(
    GrammarRule("LANGUAGE", List("LEX", "GRAMMAR"), None),
    GrammarRule("LEX", List("LEX", "LEXSECT"), None),
    GrammarRule("LEX", List("LEXSECT"), None),
    GrammarRule("LEXSECT", List("LEXLABEL", "LEXDEF"), None),
    GrammarRule("LEXLABEL", List("LABEL"), None),
    GrammarRule("LEXLABEL", List("EXCLAMATION"), None),
    GrammarRule("LEXLABEL", List("EXCLAMATION", "LABEL"), None),
    GrammarRule("LEXDEF", List("STRING"), None),
    GrammarRule("LEXDEF", List("REGEXP"), None),
    GrammarRule("GRAMMAR", List("SECT", "GRAMMAR"), None),
    GrammarRule("GRAMMAR", List("SECT"), None),
    GrammarRule("SECT", List("SECTLABEL", "COLON", "DEF", "SEMICOLON"), None),
    GrammarRule("SECTLABEL", List("LABEL"), None),
    GrammarRule("SECTLABEL", List("DOLLAR", "LABEL"), None),
    GrammarRule("DEF", List("PATTERN", "VBAR", "DEF"), None),
    GrammarRule("DEF", List("PATTERN"), None),
    GrammarRule("PATTERN", List("SYMBOLLIST"), None),
    GrammarRule("PATTERN", List(), None),
    GrammarRule("SYMBOLLIST", List("LABEL", "SYMBOLLIST"), None),
    GrammarRule("SYMBOLLIST", List("LABEL"), None)
  )

  val language_language_without_callback = Language(lex, grammar, "LANGUAGE")

}
