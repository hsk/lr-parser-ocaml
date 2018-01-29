package pg.parser

import org.scalatest.FunSpec
import pg.parser.ast.ASTNode
import pg.parser.factory.ParserFactory
import pg.parser.parser.Parser
import pg.{data, parsergenerator, token}
import data.sample_language.test_calc_language
import parsergenerator.parsergenerator.genParserGenerator
import pg.parser.parser.{parse}

class parser_test extends FunSpec {

  describe("parser test") {
    val parsingtable = genParserGenerator(test_calc_language).parsing_table
    val parser = ParserFactory.createAST(test_calc_language, genParserGenerator(test_calc_language).parsing_table)

    it("parser factory") {
      println(pg.parsingtable.show(parsingtable))
      assertResult(
        "List(Map(TERM -> Goto(1), EXP -> Goto(2), ATOM -> Goto(3), LPAREN -> Shift(4), DIGITS -> Shift(5)), Map(ASTERISK -> Shift(6), EOF -> Reduce(1), PLUS -> Reduce(1), RPAREN -> Reduce(1)), Map(PLUS -> Shift(7), EOF -> AcceptOperation), Map(EOF -> Reduce(3), PLUS -> Reduce(3), ASTERISK -> Reduce(3), RPAREN -> Reduce(3)), Map(TERM -> Goto(1), EXP -> Goto(8), ATOM -> Goto(3), LPAREN -> Shift(4), DIGITS -> Shift(5)), Map(EOF -> Reduce(4), PLUS -> Reduce(4), ASTERISK -> Reduce(4), RPAREN -> Reduce(4)), Map(ATOM -> Goto(9), DIGITS -> Shift(5), LPAREN -> Shift(4)), Map(TERM -> Goto(10), ATOM -> Goto(3), DIGITS -> Shift(5), LPAREN -> Shift(4)), Map(PLUS -> Shift(7), RPAREN -> Shift(11)), Map(EOF -> Reduce(2), PLUS -> Reduce(2), ASTERISK -> Reduce(2), RPAREN -> Reduce(2)), Map(ASTERISK -> Shift(6), EOF -> Reduce(0), PLUS -> Reduce(0), RPAREN -> Reduce(0)), Map(EOF -> Reduce(5), PLUS -> Reduce(5), ASTERISK -> Reduce(5), RPAREN -> Reduce(5)))"
      )(pg.parsingtable.show(parsingtable))
      ParserFactory.createAST(test_calc_language, parsingtable).asInstanceOf[Parser]
    }
    it("getting calc language ast") {
      assert(parse(parser, "1+1") ==
        ASTNode("EXP", null,
          List(
            ASTNode("EXP", null, List(
              ASTNode("TERM", null, List(
                ASTNode("ATOM", null, List(
                  ASTNode("DIGITS", "1", List()))))))),
            ASTNode("PLUS", "+", List()),
            ASTNode("TERM", null, List(
              ASTNode("ATOM", null, List(
                ASTNode("DIGITS", "1", List())))))
          ))
      )
    }
    it("invalid input") {
      assert(parse(parser, "1zzz") == ASTNode("DIGITS", "1", List()))
    }
  }

  describe("test grammar input with callback") {
    val parser = ParserFactory.create(test_calc_language, genParserGenerator(test_calc_language).parsing_table)
    it("custom callback in grammar") {
      assert(parse(parser, "2*(3+4)") == 14)
    }
  }
}
