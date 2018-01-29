package pg.data

import pg.language.{Language, LexDefinition, GrammarDefinition,GrammarRule,LexRule,Ptn,Reg,Str,reg}

object broken_language {
  /*
  trait E
  case class EString(f:String) extends E
  case class EInt(f:Int) extends E
  val g = List[(String,List[String])](
    ("EXP", List("EXP", "PLUS", "EXP"), {case List(EInt(c0),EString(c1),EInt(c2)) => EInt(c0 + c2)}),
    ("EXP", List("TERM"), {case List(EInt(c0)) => EInt(c0)}),
    ("TERM", List("TERM", "ASTERISK", "ATOM"), {case List(EInt(c0),EString(c1),EInt(c2)) => EInt(c0 * c2)}),
    ("TERM", List("ATOM"), {case List(EInt(c0)) => EInt(c0) }),
    ("ATOM", List("DIGITS"), {case List(EString(c0)) => EInt(c0.toInt)}),
    ("ATOM", List("LPAREN", "EXP", "RPAREN"), {case List(EString(c0),EInt(c1),EString(c2)) => EInt(c1)})
  )*/

  val test_broken_grammar: GrammarDefinition = List(
    GrammarRule("EXP", List("EXP", "PLUS", "EXP"), Some {case(c,_,_) => c(0).asInstanceOf[Int] + c(2).asInstanceOf[Int]}),
    GrammarRule("EXP", List("TERM"), Some{case(c,_,_) => c(0)}),
    GrammarRule("TERM", List("TERM", "ASTERISK", "ATOM"), Some{case(c,_,_) => c(0).asInstanceOf[Int] * c(2).asInstanceOf[Int]}),
    GrammarRule("TERM", List("ATOM"), Some{case(c,_,_) => c(0)}),
    GrammarRule("ATOM", List("DIGITS"), Some{case(c,_,_) => c(0).toString.toInt}),
    GrammarRule("ATOM", List("LPAREN", "EXP", "RPAREN"), Some{case(c,_,_) => c(1)})
  )

  val test_broken_lex: LexDefinition = List(
    LexRule("DIGITS", Reg("[1-9][0-9]*"),0,None),
    LexRule("PLUS", Str("+"),0,None),
    LexRule("ASTERISK", Str("*"),0,None),
    LexRule("LPAREN", Str("("),0,None),
    LexRule("RPAREN", Str(")"),0,None),
    LexRule(null, Reg("""(\r\n|\r|\n)+"""),0,None),
    LexRule(null, Reg("""[ \f\t\v\u00a0\u1680\u180e\u2000-\u200a\u202f\u205f\u3000\ufeff]+"""),0,None),
    LexRule("INVALID", Reg("."),0,None)
  )

  val test_broken_language = Language(test_broken_lex, test_broken_grammar, "EXP")
}
