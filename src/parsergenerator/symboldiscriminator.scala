package pg.parsergenerator

import pg.language.GrammarDefinition
import pg.token.Token

object symboldiscriminator {

  /**
   * 終端/非終端記号の判別を行う
   */
  case class SymbolDiscriminator(terminal_symbols: Set[Token], nonterminal_symbols: Set[Token])

  def genSymbolDiscriminator(grammar: GrammarDefinition): SymbolDiscriminator = {
    // 左辺値の登録
    val nonterminal_symbols = grammar.map(_.ltoken).toSet // 構文規則の左辺に現れる記号は非終端記号

    // 右辺値の登録
    var terminal_symbols = Set[Token]()
    for (rule <- grammar) {
      for (symbol <- rule.pattern) {
        if (!nonterminal_symbols.contains(symbol)) // 非終端記号でない(=左辺値に現れない)場合、終端記号である
          terminal_symbols += symbol
      }
    }
    SymbolDiscriminator(terminal_symbols, nonterminal_symbols)
  }

  /**
    * 与えられた記号が終端記号かどうかを調べる
    * @param {Token} symbol
    * @returns {boolean}
    */
  def isTerminalSymbol(d: SymbolDiscriminator, symbol: Token): Boolean = {
    d.terminal_symbols.contains(symbol)
  }
  /**
    * 与えられた記号が非終端記号かどうかを調べる
    * @param {Token} symbol
    * @returns {boolean}
    */
  def isNonterminalSymbol(d: SymbolDiscriminator, symbol: Token): Boolean = {
    d.nonterminal_symbols.contains(symbol)
  }
}
