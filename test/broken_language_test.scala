package pg

import org.scalatest.FunSpec
import parsergenerator.parsergenerator.{genParserGenerator,getParser,isConflicted}
import data.broken_language.{test_broken_language}
import pg.parser.parser.{parse}

class broken_language_test extends FunSpec {

  describe("Calculator test with broken language") {
    // TODO: パーサが壊れていることを(コンソール出力以外で)知る方法
    val pg = genParserGenerator(test_broken_language)
    val parser = getParser(pg)
    it("parsing table is broken") {
      assert(isConflicted(pg) == true)
      assert(pg.table_type == "CONFLICTED")
    }
    it(""""1+1" equals 2""") {
      assert(parse(parser, "1+1") == 2)
    }
    it(""""( 1+1 )*3 + ( (1+1) * (1+2*3+4) )\\n" equals 28 (to be failed)""") {
      assert(parse(parser, "( 1+1 )*3 + ( (1+1) * (1+2*3+4) )\n") != 28)
    }
  }
}
