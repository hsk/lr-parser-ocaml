package pg.parsergenerator

import org.scalatest.FunSpec
import pg.parsergenerator.closureitem.{genClosureItem,isSameLR0, isSameLR1}
import pg.data.sample_language.{test_sample_language}
import pg.parsergenerator.grammardb.{genGrammarDB,getTokenId}
import pg.token.{SYMBOL_EOF}

class closureitem_test extends FunSpec {

  describe("ClosureItem test") {
    val grammardb = genGrammarDB(test_sample_language)
    describe("{S' -> . S [$]}") {
      val ci = genClosureItem(grammardb, -1, 0, Array(SYMBOL_EOF))
      it("getter") {
        assert(ci.rule_id == -1)
        assert(ci.dot_index == 0)
        assertResult(ci.lookaheads )( Array(SYMBOL_EOF))
      }
      it("ClosureItem Hash") {
        val id_eof = getTokenId(grammardb, SYMBOL_EOF)
        assert(ci.lr0_hash == "-1,0")
        assert(ci.lr1_hash == "-1,0,["+id_eof+"]")
      }
      describe("ClosureItem equality") {
        it("compare itself") {
          assert(isSameLR0(ci, ci))
          assert(isSameLR1(ci, ci))
        }
        it("same ClosureItem") {
          val ci2 = genClosureItem(grammardb, -1, 0, Array(SYMBOL_EOF))
          assert(isSameLR0(ci, ci2))
          assert(isSameLR1(ci, ci2))
        }
        it("not same ClosureItem") {
          val ci2 = genClosureItem(grammardb, 0, 0, Array(SYMBOL_EOF))
          assert(!isSameLR0(ci, ci2))
          assert(!isSameLR1(ci, ci2))
        }
        it("not same lookahead item") {
          val ci2 = genClosureItem(grammardb, -1, 0, Array("ID"))
          assert(isSameLR0(ci, ci2))
          assert(!isSameLR1(ci, ci2))
        }
      }
      it("invalid lookahead item") {
        assertThrows[Error](genClosureItem(grammardb, -1, 0, Array("X"))) // invalid token
      }
    }
    describe("invalid ClosureItem") {
      it("invalid grammar id") {
        assertThrows[Error](genClosureItem(grammardb, -2, 0, Array(SYMBOL_EOF)))
      }
      it("invalid dot position") {
        assertThrows[Error](genClosureItem(grammardb, -1, -1, Array(SYMBOL_EOF)))
      }
    }
  }
}
