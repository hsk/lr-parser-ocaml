package pg.parser

import pg.language.{Language}
import pg.parsingtable.{ParsingTable}
import pg.lexer.{Lexer}
import parser.{Parser}
import callback.{ASTConstructor, DefaultCallbackController}

object factory {
  /**
   * Parserを生成するためのファクトリクラス
   */
  object ParserFactory {
    def create(language: Language, parsing_table: ParsingTable): Parser = {
      val cc = new DefaultCallbackController(language)
      new Parser(new Lexer(language.lex,cc), language.grammar, parsing_table, cc)
    }
    def createAST(language: Language, parsing_table: ParsingTable): Parser = {
      val cc = new ASTConstructor(language)
      new Parser(new Lexer(language.lex,cc), language.grammar, parsing_table, cc)
    }
  }
}
