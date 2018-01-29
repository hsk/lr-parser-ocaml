package pg.precompiler

import pg.language.{Language}
import pg.language.{LexDefinition, LexRule, Language, GrammarDefinition,GrammarRule,Ptn,Str,Reg,reg}
import pg.token.{SYMBOL_EOF}
import pg.parser.parser.{parse}
import pg.parsergenerator.parsergenerator.{ParserGenerator,genParserGenerator}
import ruleparser.{language_parser}

object precompiler {
  /**
   * 予め構文解析器を生成しておいて利用するためのソースコードを生成する
   */
  class PreCompiler {
    private var import_path: String = "lavriapg"
    /**
     * @param import_path パーサジェネレータをimportするためのディレクトリパス
     */
    def this(import_path: String) {
      this()
      if (import_path.charAt(import_path.length - 1) != '/') this.import_path += "/"
    }
    /**
     * 構文ファイルを受け取り、それを処理できるパーサを構築するためのソースコードを返す
     * @param {string} input 言語定義文法によって記述された、解析対象となる言語
     * @returns {string} 生成されたパーサのソースコード
     */
    def exec(input: String): String = {
      val language: Language = parse(language_parser,input).asInstanceOf[Language]
      System.err.println(language)
      val parsing_table = genParserGenerator(language).parsing_table
      var result = ""

      result += "import pg.token.{Token, SYMBOL_EOF}\n"
      result += "import pg.language.{Language}\n"
      result += "import pg.parsingtable.{ParsingOperation, ParsingTable}\n"
      result += "import pg.parser.parser.{Parser}\n"
      result += "import pg.parser.factory.{ParserFactory}\n\n"
      result += "val language: Language = Language(\n"
      result += "\tArray(\n"
      for (i <- 0 until language.lex.length) {
        val token = language.lex(i).token
        val pattern = language.lex(i).pattern
        result += "\t\tLexRule(" + (if (token == null) "null" else ("\"" + (token.toString) + "\"")) + ", "
        pattern match {
        case Reg(reg) => result += reg.toString()
        case Str(str) => result += "\"" + str + "\""
        }
        result += ")"
        if (i != language.lex.length - 1) result += ","
        result += "\n"
      }
      result += "\t),\n"
      result += "\tArray(\n"
      for (i <- 0 until language.grammar.length) {
        val ltoken = language.grammar(i).ltoken
        val pattern = language.grammar(i).pattern
        result += "\t\t" + "GrammarRule(\n"
        result += "\t\t\t\"" + (ltoken.toString) + "\",\n"
        result += "\t\t\t" + "Array("
        for (ii <- 0 until pattern.length) {
          result += "\"" + (pattern(ii).toString) + "\""
          if (ii != pattern.length - 1) result += ", "
        }
        result += ")\n"
        result += "\t\t" + ")"
        if (i != language.grammar.length - 1) result += ","
        result += "\n"
      }
      result += "\t),\n"
      result += "\t\"" + (language.start_symbol.toString) + "\"\n"
      result += ")\n\n"
      result += "val parsing_table:ParsingTable = Array(\n"
      for (i <- 0 until parsing_table.length) {
        result += "\tMap[Token, ParsingOperation](\n"
        parsing_table(i).foreach{case (value, key) =>
          result += "\t\t" + (if(key == SYMBOL_EOF) "SYMBOL_EOF" else ("\"" + (key.toString)+ "\"")) + "-> " + value + ",\n"
        }
        result = result.substring(0, result.length -2)
        result += "),\n"
      }
      result = result.substring(0, result.length-2)
      result += "\n)\n\n"
      result += "val parser:Parser = ParserFactory.create(language, parsing_table)\n"
      result
    }
  }
}
