package pg.parsergenerator

import org.scalatest.FunSpec
import pg.parsergenerator.grammardb.{genGrammarDB}
import pg.data.sample_language.{test_empty_language, test_sample_language}
import pg.parsergenerator.closureitem.{genClosureItem}
import pg.token.{SYMBOL_EOF}
import pg.parsergenerator.closureset.{ClosureSet,genClosureSet}

class closureset_test extends FunSpec {

  describe("ClosureSet test") {
    describe("Closure{S' -> . S [$]}") {
      val grammardb = genGrammarDB(test_sample_language)
      val cs = genClosureSet(grammardb, Array(genClosureItem(grammardb, -1, 0, Array(SYMBOL_EOF))))
      /*
      S' -> . S [$]
      S -> . E [$]
      E -> . LIST SEMICOLON [$]
      E -> . HOGE [$]
      LIST -> . T [SEMICOLON SEPARATE]
      LIST > . LIST SEPARATE T [SEMICOLON SEPARATE]
      T -> . ATOM [SEMICOLON SEPARATE]
      T -> . [SEMICOLON SEPARATE]
      HOGE -> . ID [$]
      */
      val expanded = Array(
        genClosureItem(grammardb, -1, 0, Array(SYMBOL_EOF)),
        genClosureItem(grammardb, 0, 0, Array(SYMBOL_EOF)),
        genClosureItem(grammardb, 1, 0, Array(SYMBOL_EOF)),
        genClosureItem(grammardb, 2, 0, Array(SYMBOL_EOF)),
        genClosureItem(grammardb, 3, 0, Array("SEMICOLON", "SEPARATE")),
        genClosureItem(grammardb, 4, 0, Array("SEPARATE", "SEMICOLON")), // test changing lookaheads order
        genClosureItem(grammardb, 5, 0, Array("SEMICOLON", "SEPARATE")),
        genClosureItem(grammardb, 6, 0, Array("SEMICOLON", "SEPARATE")),
        genClosureItem(grammardb, 7, 0, Array(SYMBOL_EOF))
      )
      val expanded_shuffled = Array(
        genClosureItem(grammardb, 5, 0, Array("SEMICOLON", "SEPARATE")),
        genClosureItem(grammardb, 2, 0, Array(SYMBOL_EOF)),
        genClosureItem(grammardb, 1, 0, Array(SYMBOL_EOF)),
        genClosureItem(grammardb, 0, 0, Array(SYMBOL_EOF)),
        genClosureItem(grammardb, 4, 0, Array("SEPARATE", "SEMICOLON")),
        genClosureItem(grammardb, 7, 0, Array(SYMBOL_EOF)),
        genClosureItem(grammardb, -1, 0, Array(SYMBOL_EOF)),
        genClosureItem(grammardb, 3, 0, Array("SEMICOLON", "SEPARATE")),
        genClosureItem(grammardb, 6, 0, Array("SEPARATE", "SEMICOLON"))
      )
      it("ClosureSet size") {
        assert(closureset.size(cs)==9)
      }
      it("ClosureSet array") {
        assert(closureset.getArray(cs).deep == expanded.deep)
      }
      describe("ClosureSet equality") {
        it("compare itself") {
          assert(closureset.isSameLR0(cs, cs))
          assert(closureset.isSameLR1(cs, cs))
        }
        it("compare closureset that is given expanded items to constructor") {
          assert(closureset.isSameLR0(cs, genClosureSet(grammardb, expanded_shuffled)))
          assert(closureset.isSameLR1(cs, genClosureSet(grammardb, expanded_shuffled)))
        }
      }
      it("ClosureSet#include") {
        for (ci <- expanded) {
          assert(closureset.includes(cs,ci))
        }
      }
      it("ClosureSet#include invalid inputs") {
        closureset.includes(cs,genClosureItem(grammardb, 0, 1, Array(SYMBOL_EOF)))
        assertThrows[Error](closureset.includes(cs, genClosureItem(grammardb, 0, 2, Array(SYMBOL_EOF)))) //out of range
        assertThrows[Error](closureset.includes(cs, genClosureItem(grammardb, 0, -1, Array(SYMBOL_EOF)))) //out of range
        assertThrows[Error](closureset.includes(cs, genClosureItem(grammardb, -2, 0, Array(SYMBOL_EOF)))) //invalid grammar id
        assertThrows[Error](closureset.includes(cs, genClosureItem(grammardb, -8, 0, Array(SYMBOL_EOF)))) //invalid grammar id
      }
      describe("invalid ClosureSet") {
        it("invalid grammar id") {
          assertThrows[Error](genClosureSet(grammardb, Array(genClosureItem(grammardb, -2, 0, Array(SYMBOL_EOF))))) //invalid grammar id
        }
        it("invalid dot position") {
          assertThrows[Error](genClosureSet(grammardb, Array(genClosureItem(grammardb, 0, -1, Array(SYMBOL_EOF))))) //out of range
        }
      }
    }
    describe("empty grammar") {
      val grammardb = genGrammarDB(test_empty_language)
      val cs = genClosureSet(grammardb, Array(genClosureItem(grammardb, -1, 0, Array(SYMBOL_EOF))))
      val expanded = Array(
        genClosureItem(grammardb, -1, 0, Array(SYMBOL_EOF)),
        genClosureItem(grammardb, 0, 0, Array(SYMBOL_EOF))
      )
      it("ClosureSet size") {
        assert(closureset.size(cs)==2)
      }
      it("ClosureSet array") {
        assert(closureset.getArray(cs).deep == expanded.deep)
      }
      it("ClosureSet#include") {
        for (ci <- expanded) {
          assert(closureset.includes(cs,ci))
        }
      }
    }
  }
}

