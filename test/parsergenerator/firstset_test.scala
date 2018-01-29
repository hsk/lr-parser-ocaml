package pg.parsergenerator

import org.scalatest.FunSpec
import pg.parsergenerator.firstset.{FirstSet,generateFirst,get,getFromList}
import pg.parsergenerator.symboldiscriminator.genSymbolDiscriminator
import pg.{data, token}
import data.sample_language.{test_empty_language, test_sample_grammar}

class firstset_test extends FunSpec {

  describe("FirstSet test") {
    val first = generateFirst(test_sample_grammar, genSymbolDiscriminator(test_sample_grammar))
    describe("valid one terminal and nonterminal symbol") {
      it("First(S) is {SEMICOLON, SEPARATE, ATOM, ID}") {
        for (symbol <- Array("SEMICOLON", "SEPARATE", "ATOM", "ID")) {
          assert(get(first, "S").contains(symbol))
        }
        assert(get(first, "S").size == 4)
      }
      it("First(E) is {SEMICOLON, SEPARATE, ATOM, ID}") {
        for (symbol <- Array("SEMICOLON", "SEPARATE", "ATOM", "ID")) {
          assert(get(first, "E").contains(symbol))
        }
        assert(get(first, "E").size == 4)
      }
      it("First([E]) is {SEMICOLON, SEPARATE, ATOM, ID}") {
        for (symbol <- Array("SEMICOLON", "SEPARATE", "ATOM", "ID")) {
          assert(getFromList(first, List("E")).contains(symbol))
        }
        assert(getFromList(first, List("E")).size == 4)
      }
      it("First(LIST) is {SEPARATE, ATOM}") {
        for (symbol <- Array("SEPARATE", "ATOM")) {
          assert(get(first, "LIST").contains(symbol))
        }
        assert(get(first, "LIST").size == 2)
      }
      it("First(T) is {ATOM}") {
        assert(get(first, "T").contains("ATOM"))
        assert(get(first, "T").size == 1)
      }
      it("First(HOGE) is {ID}") {
        assert(get(first, "HOGE").contains("ID"))
        assert(get(first, "HOGE").size == 1)
      }
      it("First(ID) is {ID}") {
        assert(get(first, "ID").contains("ID"))
        assert(get(first, "ID").size == 1)
      }
    }
    describe("valid word (multiple terminal or nonterminal symbols)") {
      it("First(LIST ID) is {SEPARATE ATOM ID}") {
        for (symbol <- Array("SEPARATE", "ATOM", "ID")) {
          assert(getFromList(first, List("LIST", "ID")).contains(symbol))
        }
        assert(getFromList(first, List("LIST", "ID")).size == 3)
      }
      it("First(HOGE HOGE) is {ID}") {
        assert(getFromList(first, List("HOGE", "HOGE")).contains("ID"))
        assert(getFromList(first, List("HOGE", "HOGE")).size == 1)
      }
    }
    describe("invalid input (contains neither terminal nor nonterminal symbols)") {
      it("First(FOO) throws error") {
        assertThrows[Error](get(first, "FOO")) //invalid token
      }
      it("First(INVALID) throws error") {
        assertThrows[Error](get(first, "INVALID")) //invalid token
      }
      it("First(INVALID INVALID) throws error") {
        assertThrows[Error](getFromList(first, List("INVALID", "INVALID"))) //invalid token
      }
      it("First(INVALID S) throws error") {
        assertThrows[Error](getFromList(first, List("INVALID", "S"))) //invalid token
      }
      it("First(S INVALID) throws error") {
        assertThrows[Error](getFromList(first, List("S", "INVALID"))) //invalid token
      }
    }
  }

  describe("FirstSet test(empty language)") {
    val first = generateFirst(test_empty_language.grammar, genSymbolDiscriminator(test_empty_language.grammar))
    it("First(S) is {}") {
      assert(get(first, "S").size == 0)
    }
  }
}
