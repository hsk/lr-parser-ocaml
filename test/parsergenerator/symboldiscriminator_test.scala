package pg.parsergenerator

import org.scalatest.FunSpec
import pg.parsergenerator.symboldiscriminator.genSymbolDiscriminator
import pg.{data, token}
import data.sample_language.{test_calc_grammar, test_empty_language, test_sample_grammar}
import token.{Token}
import symboldiscriminator.{isTerminalSymbol, isNonterminalSymbol}

class symboldiscriminator_test extends FunSpec {

  describe("SymbolDiscriminator test") {
    describe("test sample language") {
      val symbols = genSymbolDiscriminator(test_sample_grammar)
      it("S is Nonterminal") {
        assert(isNonterminalSymbol(symbols, "S"))
        assert(!isTerminalSymbol(symbols, "S"))
      }
      it("E is Nonterminal") {
        assert(isNonterminalSymbol(symbols, "E"))
        assert(!isTerminalSymbol(symbols, "E"))
      }
      it("LIST is Nonterminal") {
        assert(isNonterminalSymbol(symbols, "LIST"))
        assert(!isTerminalSymbol(symbols, "LIST"))
      }
      it("T is Nonterminal") {
        assert(isNonterminalSymbol(symbols, "T"))
        assert(!isTerminalSymbol(symbols, "T"))
      }
      it("HOGE is Nonterminal") {
        assert(isNonterminalSymbol(symbols, "HOGE"))
        assert(!isTerminalSymbol(symbols, "HOGE"))
      }
      it("SEMICOLON is Terminal") {
        assert(!isNonterminalSymbol(symbols, "SEMICOLON"))
        assert(isTerminalSymbol(symbols, "SEMICOLON"))
      }
      it("SEPARATE is Terminal") {
        assert(!isNonterminalSymbol(symbols, "SEPARATE"))
        assert(isTerminalSymbol(symbols, "SEPARATE"))
      }
      it("ATOM is Terminal") {
        assert(!isNonterminalSymbol(symbols, "ATOM"))
        assert(isTerminalSymbol(symbols, "ATOM"))
      }
      it("ID is Terminal") {
        assert(!isNonterminalSymbol(symbols, "ID"))
        assert(isTerminalSymbol(symbols, "ID"))
      }
      it("INVALID (not appear in grammar) is neither Nonterminal nor Terminal") {
        assert(!isNonterminalSymbol(symbols, "INVALID"))
        assert(!isTerminalSymbol(symbols, "INVALID"))
      }
      it("Check nonterminal symbols set") {
        val nt: Set[Token] = symbols.nonterminal_symbols
        for (symbol <- Array("S", "E", "LIST", "T", "HOGE")) {
          assert(nt.contains(symbol))
        }
        assert(nt.size == 5)
      }
      it("Check terminal symbols set") {
        val t: Set[Token] = symbols.terminal_symbols
        for (symbol <- Array("SEMICOLON", "SEPARATE", "ATOM", "ID")) {
          assert(t.contains(symbol))
        }
        assert(t.size == 4)
      }
    }
    describe("test sample language") {
      val symbols = genSymbolDiscriminator(test_calc_grammar)
      it("Check nonterminal symbols set 2") {
        val nt: Set[Token] = symbols.nonterminal_symbols
        for (symbol <- Array("EXP", "TERM", "ATOM")) {
          assert(nt.contains(symbol))
        }
        assert(nt.size == 3)
      }
      it("Check terminal symbols set 2") {
        val t: Set[Token] = symbols.terminal_symbols
        for (symbol <- Array("PLUS", "ASTERISK", "DIGITS", "LPAREN", "RPAREN")) {
          assert(t.contains(symbol))
        }
        assert(t.size == 5)
      }
    }
    describe("test empty language") {
      val symbols = genSymbolDiscriminator(test_empty_language.grammar)
      it("Check nonterminal symbols set 3") {
        val nt: Set[Token] = symbols.nonterminal_symbols
        assert(nt.contains("S"))
        assert(nt.size == 1)
      }
      it("Check terminal symbols set 3") {
        val t: Set[Token] = symbols.terminal_symbols
        assert(t.size == 0)
      }
    }
  }
}
