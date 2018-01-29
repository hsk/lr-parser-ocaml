package pg.precompiler

import pg.language.{LexDefinition, LexRule, Language, GrammarDefinition,GrammarRule,Ptn,Str,Reg,reg}
import pg.parsingtable.{ParsingOperation, ParsingTable,Shift,Reduce,Conflict,Accept,Goto}
import pg.lexer.{Lexer}
import pg.token.{SYMBOL_EOF, Token}
import pg.parser.factory.{ParserFactory}
import pg.parser.parser.{Parser}

object ruleparser {

  val lex: LexDefinition = List(
    LexRule("EXCLAMATION", Str("!"),0,None),
    LexRule("VBAR", Str("|"),0,None),
    LexRule("DOLLAR", Str("$"),0,None),
    LexRule("COLON", Str(":"),0,None),
    LexRule("SEMICOLON", Str(";"),0,None),
    LexRule("LABEL", Reg("[a-zA-Z_][a-zA-Z0-9_]*"),0,None),
    LexRule("REGEXP", Reg("""\/(\\.|\[([^\]]|\.)*\]|[^/])*\/[gimuy]*"""), 0, Some{case(v,_,_) =>
        val tmp = v.toString.split("/")
        val flags = if(v.toString.endsWith("/")) "" else tmp(tmp.length - 1)
        val p = v.toString.substring(1, v.toString.length -1 - flags.length)
        (if(flags=="") "" else "(?"+flags+")")+p
      }),
    LexRule("STRING", Reg("\".*?\""), 0,Some{case(v,_,_) => v.toString.substring(1, v.toString.length-1)}),
    LexRule("STRING", Reg("'.*?'"), 0,Some{case(v,_,_) => v.toString.substring(1, v.toString.length-1)}),
    LexRule(null, Reg("""(\r\n|\r|\n)+"""),0,None),
    LexRule(null, Reg("""[ \f\t\v\u00a0\u1680\u180e\u2000-\u200a\u202f\u205f\u3000\ufeff]+"""),0,None),
    LexRule("INVALID", Reg("."),0,None)
  )
  case class Grammar(start_symbol:Token,grammar:GrammarDefinition)
  case class Sect(start_symbol:Token,sect:GrammarDefinition)
  case class SectLabel(start_symbol:Token,label:String)
  val grammar: GrammarDefinition = List(
    GrammarRule("LANGUAGE", List("LEX", "GRAMMAR"), Some{(c:List[Any], _:Token, _:Lexer) =>
            var start_symbol = c(1).asInstanceOf[Grammar].start_symbol
            // 開始記号の指定がない場合、最初の規則に設定]
            if (start_symbol == null) {
              if (c(1).asInstanceOf[Grammar].grammar.length > 0) start_symbol = c(1).asInstanceOf[Grammar].grammar(0).ltoken
              else start_symbol = ""
            }
            Language(c(0).asInstanceOf[LexDefinition], c(1).asInstanceOf[Grammar].grammar, start_symbol)
          }),
    GrammarRule("LEX", List("LEX", "LEXSECT"), Some{(c:List[Any], _:Token, _:Lexer) =>
      c(0).asInstanceOf[List[LexRule]] ::: List(c(1).asInstanceOf[LexRule])
    }),
    GrammarRule("LEX", List("LEXSECT"), Some{(c:List[Any], _:Token, _:Lexer) => List(c(0).asInstanceOf[LexRule])}),
    GrammarRule("LEXSECT", List("LEXLABEL", "LEXDEF"), Some{(c:List[Any], _:Token, _:Lexer) =>
      LexRule(c(0).asInstanceOf[Token], c(1).asInstanceOf[Ptn],0,None)
    }),
    GrammarRule("LEXLABEL", List("LABEL"), Some{(c:List[Any],_,_)=>c(0).toString}),
    GrammarRule("LEXLABEL", List("EXCLAMATION"), Some{(_,_,_) => null}),
    GrammarRule("LEXLABEL", List("EXCLAMATION", "LABEL"), Some{(_,_,_) => null}),
    GrammarRule("LEXDEF", List("STRING"), Some{(c:List[Any],_,_)=>Str(c(0).toString)}),
    GrammarRule("LEXDEF", List("REGEXP"), Some{(c:List[Any],_,_)=>Reg(c(0).toString)}),
    GrammarRule("GRAMMAR", List("SECT", "GRAMMAR"), Some{(c:List[Any], _:Token, _:Lexer) =>
            var start_symbol = c(1).asInstanceOf[Grammar].start_symbol
            if (c(0).asInstanceOf[Sect].start_symbol != null) {
              start_symbol = c(0).asInstanceOf[Sect].start_symbol
            }
            Grammar(start_symbol, c(0).asInstanceOf[Sect].sect ::: c(1).asInstanceOf[Grammar].grammar)
          }),
    GrammarRule("GRAMMAR", List("SECT"), Some{(c:Seq[Any], _:Token, _:Lexer) =>
            var start_symbol:Token = null
            if (c(0).asInstanceOf[Sect].start_symbol != null) {
              start_symbol = c(0).asInstanceOf[Sect].start_symbol
            }
            Grammar(start_symbol,c(0).asInstanceOf[Sect].sect)
          }),
    GrammarRule("SECT", List("SECTLABEL", "COLON", "DEF", "SEMICOLON"), Some{(c:List[Any], _:Token, _:Lexer) =>
            val result = c(2).asInstanceOf[List[List[String]]]. map {pt =>
              GrammarRule[Any](c(0).asInstanceOf[SectLabel].label, pt.toList,None)
            }
            Sect(c(0).asInstanceOf[SectLabel].start_symbol, result)
          }),
    GrammarRule("SECTLABEL", List("LABEL"), Some{(c:List[Any], _:Token, _:Lexer) => SectLabel(null, c(0).toString)}),
    GrammarRule("SECTLABEL", List("DOLLAR", "LABEL"), Some{(c:List[Any], _:Token, _:Lexer) => SectLabel(c(1).toString, c(1).toString)}),
    GrammarRule("DEF", List("PATTERN", "VBAR", "DEF"), Some{(c:List[Any], _:Token, _:Lexer) => c(0).asInstanceOf[List[String]]::c(2).asInstanceOf[List[List[String]]]}),
    GrammarRule("DEF", List("PATTERN"), Some{(c:List[Any], _:Token, _:Lexer) => List(c(0).asInstanceOf[List[String]])}),
    GrammarRule("PATTERN", List("SYMBOLLIST"), None),
    GrammarRule("PATTERN", List(), Some{(c:List[Any], _:Token, _:Lexer) => List[String]()}),
    GrammarRule("SYMBOLLIST", List("LABEL", "SYMBOLLIST"), Some{(c:List[Any], _:Token, _:Lexer) => c(0).toString :: c(1).asInstanceOf[List[String]]}),
    GrammarRule("SYMBOLLIST", List("LABEL"), Some{(c:List[Any], _:Token, _:Lexer) => List(c(0).toString)})
  )

  /**
   * 言語定義文法の言語定義
   * @type Language
   */
  val language_language: Language = Language(lex, grammar, "LANGUAGE")

  // 予めParsingTableを用意しておくことで高速化
  /**
   * 言語定義文法の言語定義、の構文解析表
   * @type ParsingTable
   */
  val language_parsing_table: ParsingTable = List(
    Map[Token, ParsingOperation](
      "LANGUAGE" -> Goto(1),
      "LEX" -> Goto(2),
      "LEXSECT" -> Goto(3),
      "LEXLABEL" -> Goto(4),
      "LABEL" -> Shift(5),
      "EXCLAMATION" -> Shift(6)),
    Map[Token, ParsingOperation](
      SYMBOL_EOF -> Accept),
    Map[Token, ParsingOperation](
      "GRAMMAR" -> Goto(7),
      "LEXSECT" -> Goto(8),
      "SECT" -> Goto(9),
      "SECTLABEL" -> Goto(10),
      "LABEL" -> Shift(11),
      "DOLLAR" -> Shift(12),
      "LEXLABEL" -> Goto(4),
      "EXCLAMATION" -> Shift(6)),
    Map[Token, ParsingOperation](
      "LABEL" -> Reduce(2),
      "DOLLAR" -> Reduce(2),
      "EXCLAMATION" -> Reduce(2)),
    Map[Token, ParsingOperation](
      "LEXDEF" -> Goto(13),
      "STRING" -> Shift(14),
      "REGEXP" -> Shift(15)),
    Map[Token, ParsingOperation](
      "STRING" -> Reduce(4),
      "REGEXP" -> Reduce(4)),
    Map[Token, ParsingOperation](
      "LABEL" -> Shift(16),
      "STRING" -> Reduce(5),
      "REGEXP" -> Reduce(5)),
    Map[Token, ParsingOperation](
      SYMBOL_EOF -> Reduce(0)),
    Map[Token, ParsingOperation](
      "LABEL" -> Reduce(1),
      "DOLLAR" -> Reduce(1),
      "EXCLAMATION" -> Reduce(1)),
    Map[Token, ParsingOperation](
      "SECT" -> Goto(9),
      "SECTLABEL" -> Goto(10),
      "LABEL" -> Shift(17),
      "DOLLAR" -> Shift(12),
      "GRAMMAR" -> Goto(18),
      SYMBOL_EOF -> Reduce(10)),
    Map[Token, ParsingOperation](
      "COLON" -> Shift(19)),
    Map[Token, ParsingOperation](
      "COLON" -> Reduce(12),
      "STRING" -> Reduce(4),
      "REGEXP" -> Reduce(4)),
    Map[Token, ParsingOperation](
      "LABEL" -> Shift(20)),
    Map[Token, ParsingOperation](
      "LABEL" -> Reduce(3),
      "DOLLAR" -> Reduce(3),
      "EXCLAMATION" -> Reduce(3)),
    Map[Token, ParsingOperation](
      "LABEL" -> Reduce(7),
      "DOLLAR" -> Reduce(7),
      "EXCLAMATION" -> Reduce(7)),
    Map[Token, ParsingOperation](
      "LABEL" -> Reduce(8),
      "DOLLAR" -> Reduce(8),
      "EXCLAMATION" -> Reduce(8)),
    Map[Token, ParsingOperation](
      "STRING" -> Reduce(6),
      "REGEXP" -> Reduce(6)),
    Map[Token, ParsingOperation](
      "COLON" -> Reduce(12)),
    Map[Token, ParsingOperation](
      SYMBOL_EOF -> Reduce(9)),
    Map[Token, ParsingOperation](
      "DEF" -> Goto(21),
      "PATTERN" -> Goto(22),
      "SYMBOLLIST" -> Goto(23),
      "LABEL" -> Shift(24),
      "SEMICOLON" -> Reduce(17),
      "VBAR" -> Reduce(17)),
    Map[Token, ParsingOperation](
      "COLON" -> Reduce(13)),
    Map[Token, ParsingOperation](
      "SEMICOLON" -> Shift(25)),
    Map[Token, ParsingOperation](
      "VBAR" -> Shift(26),
      "SEMICOLON" -> Reduce(15)),
    Map[Token, ParsingOperation](
      "SEMICOLON" -> Reduce(16),
      "VBAR" -> Reduce(16)),
    Map[Token, ParsingOperation](
      "LABEL" -> Shift(24),
      "SYMBOLLIST" -> Goto(27),
      "SEMICOLON" -> Reduce(19),
      "VBAR" -> Reduce(19)),
    Map[Token, ParsingOperation](
      SYMBOL_EOF -> Reduce(11),
      "LABEL" -> Reduce(11),
      "DOLLAR" -> Reduce(11)),
    Map[Token, ParsingOperation](
      "PATTERN" -> Goto(22),
      "DEF" -> Goto(28),
      "SYMBOLLIST" -> Goto(23),
      "LABEL" -> Shift(24),
      "SEMICOLON" -> Reduce(17),
      "VBAR" -> Reduce(17)),
    Map[Token, ParsingOperation](
      "SEMICOLON" -> Reduce(18),
      "VBAR" -> Reduce(18)),
    Map[Token, ParsingOperation](
      "SEMICOLON" -> Reduce(14))
  )

  /**
   * 言語定義ファイルを読み込むための構文解析器
   * @type {Parser}
   */
  val language_parser: Parser = ParserFactory.create(language_language, language_parsing_table)

}
