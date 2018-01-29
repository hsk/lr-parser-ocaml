package pg.data

import pg.language.{Language, LexDefinition, GrammarDefinition,GrammarRule,LexRule,Ptn,Reg,Str,reg}

object sample_language {

  val test_sample_grammar: GrammarDefinition = List(
    GrammarRule("S", List("E"), None),
    GrammarRule("E", List("LIST", "SEMICOLON"), None),
    GrammarRule("E", List("HOGE"), None),
    GrammarRule("LIST", List("T"), None),
    GrammarRule("LIST", List("LIST", "SEPARATE", "T"), None),
    GrammarRule("T", List("ATOM"), None),
    GrammarRule("T", List(), None),
    GrammarRule("HOGE", List("ID"), None)
  )
  val test_sample_lex: LexDefinition = List(
    LexRule("ATOM",      Str("x"),0,None),
    LexRule("ID",        Reg("[a-zA-Z_][a-zA-Z0-9_]*"),0,None),
    LexRule("SEMICOLON", Str(";"),0,None),
    LexRule("SEPARATE",  Str("|"),0,None),
    LexRule(null, Reg("(\r\n|\r|\n)+"),0,None),
    LexRule(null, Reg("[ \f\t\u000b\u00a0\u1680\u180e\u2000-\u200a\u202f\u205f\u3000\ufeff]+"),0,None),
    LexRule("INVALID",   Reg("."),0,None)
  )

  val test_sample_language = Language(test_sample_lex, test_sample_grammar, "S")

  val test_empty_language = Language(List(), List(GrammarRule("S", List(), None)), "S")

  val test_calc_grammar: GrammarDefinition = List(
    GrammarRule("EXP", List("EXP", "PLUS", "TERM"), Some{(c,_,_) => c(0).asInstanceOf[Int] + c(2).asInstanceOf[Int]}),
    GrammarRule("EXP", List("TERM"), Some{(c,_,_) => c(0).asInstanceOf[Int]}),
    GrammarRule("TERM", List("TERM", "ASTERISK", "ATOM"), Some{(c,_,_) => c(0).asInstanceOf[Int] * c(2).asInstanceOf[Int]}),
    GrammarRule("TERM", List("ATOM"), Some{(c,_,_) => c(0)}),
    GrammarRule("ATOM", List("DIGITS"), Some{(c,_,_) => c(0).toString.toInt}),
    GrammarRule("ATOM", List("LPAREN", "EXP", "RPAREN"), Some{(c,_,_) => c(1)})
  )

  val test_calc_lex: LexDefinition = List(
    LexRule("DIGITS", Reg("[1-9][0-9]*"),0,None),
    LexRule("PLUS", Str("+"),0,None),
    LexRule("ASTERISK", Str("*"),0,None),
    LexRule("LPAREN", Str("("),0,None),
    LexRule("RPAREN", Str(")"),0,None),
    LexRule(null, Reg("""(\r\n|\r|\n)+"""),0,None),
    LexRule(null, Reg("""[ \f\t\u000b\u00a0\u1680\u180e\u2000-\u200a\u202f\u205f\u3000\ufeff]+"""),0,None),
    LexRule("INVALID", Reg("."),0,None)
  )

  val test_calc_language = Language(test_calc_lex, test_calc_grammar, "EXP")

  val test_calc_language_raw_string = """
    DIGITS      /[1-9][0-9]*/
    PLUS        "+"
    ASTERISK    "*"
    LPAREN      "("
    RPAREN      ")"
    !ENDLINE    /(\r\n|\r|\n)+/
    !WHITESPACE /[ \f\t\u000b\u00a0\u1680\u180e\u2000-\u200a\u202f\u205f\u3000\ufeff]+/
    INVALID     /./

    $EXP : EXP PLUS TERM | TERM;
    TERM : TERM ASTERISK ATOM | ATOM;
    ATOM : DIGITS | LPAREN EXP RPAREN;
  """

}
