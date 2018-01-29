package pg.parsergenerator

import org.scalatest.FunSpec
import pg.parsergenerator.grammardb.{genGrammarDB,findRules, getRuleById}
import pg.{data, language, token}
import data.sample_language.test_sample_language
import language.GrammarRule
import token.{SYMBOL_SYNTAX}

class syntaxdb_test extends FunSpec {

  describe("GrammarDB test") {
    val grammardb = genGrammarDB(test_sample_language)

    describe("findRules test") {
      it("get rules of E") {
        assertResult(findRules(grammardb, "E") )( Array(
          (1, GrammarRule("E", List("LIST", "SEMICOLON"), None)),
          (2, GrammarRule("E", List("HOGE"), None))
        ))
      }
      it("get a rule of HOGE") {
        assertResult(findRules(grammardb, "HOGE") )( Array(
          (7, GrammarRule("HOGE", List("ID"), None))
        ))
      }
    }
    describe("getRuleById test") {
      it("rule of grammar 1 is: E -> LIST SEMICOLON") {
        assertResult(getRuleById(grammardb, 1) )( GrammarRule("E", List("LIST", "SEMICOLON"), None))
      }
      it("rule of grammar -1 is: S' -> S") {
        assertResult(getRuleById(grammardb, -1) )( GrammarRule(SYMBOL_SYNTAX, List("S"), None))
      }
      it("throw error by calling rule of grammar -2") {
        assertThrows[Error](getRuleById(grammardb, -2)) // out of range
      }
      it("no error occurs in rule of grammar 7") {
        getRuleById(grammardb, 7)
      }
      it("throw error by calling rule of grammar 8") {
        assertThrows[Error](getRuleById(grammardb, 8)) // out of range
      }
    }
  }

}
