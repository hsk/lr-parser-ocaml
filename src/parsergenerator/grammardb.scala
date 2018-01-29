package pg.parsergenerator

import pg.language.{Language, GrammarDefinition, GrammarRule}
import pg.token.{SYMBOL_EOF, SYMBOL_SYNTAX, Token}
import firstset.{FirstSet,generateFirst}
import symboldiscriminator.{SymbolDiscriminator,genSymbolDiscriminator}

object grammardb {

  /**
   * 言語定義から得られる、構文規則に関する情報を管理するクラス
   */
  case class GrammarDB(grammar: GrammarDefinition,start_symbol: Token,first: FirstSet,symbols: SymbolDiscriminator,tokenmap: Map[Token, Int],rulemap: Map[Token, Array[(Int, GrammarRule[Any])]])

  def genGrammarDB(language: Language) :GrammarDB = {
    val symbols = genSymbolDiscriminator(language.grammar)
    GrammarDB(
      language.grammar,
      language.start_symbol,
      generateFirst(language.grammar, symbols),
      symbols,
      initTokenMap(language.grammar),
      initDefMap(language.grammar)
    )
  }
  /**
    * それぞれの記号にidを割り振り、Token->numberの対応を生成
    */
  private def initTokenMap(grammar: GrammarDefinition):Map[Token, Int] = {
    var tokenid_counter: Int = 0
    def new_tokenid() : Int = {
      val id = tokenid_counter
      tokenid_counter += 1
      id
    }

    var tokenmap = Map[Token, Int]()
    tokenmap += (SYMBOL_EOF -> new_tokenid()) // 入力の終端$の登録
    tokenmap += (SYMBOL_SYNTAX -> new_tokenid()) // 仮の開始記号S'の登録

    // 左辺値の登録
    for (rule <- grammar) {
      val ltoken = rule.ltoken
      // 構文規則の左辺に現れる記号は非終端記号
      if (!tokenmap.contains(ltoken)) tokenmap += (ltoken -> new_tokenid())
    }

    // 右辺値の登録
    for (rule <- grammar) {
      for (symbol <- rule.pattern) {
        if (!tokenmap.contains(symbol))
          // 非終端記号でない(=左辺値に現れない)場合、終端記号である
          tokenmap += (symbol -> new_tokenid())
      }
    }
    tokenmap
  }
  /**
    * ある記号を左辺とするような構文ルールとそのidの対応を生成
    */
  private def initDefMap(grammar: GrammarDefinition):Map[Token, Array[(Int, GrammarRule[Any])]] = {
    var rulemap = Map[Token, Array[(Int, GrammarRule[Any])]]()
    for (i <- 0 until grammar.length) {
      var tmp = scala.collection.mutable.ArrayBuffer[(Int,GrammarRule[Any])]()
      if (rulemap.contains(grammar(i).ltoken)) {
        tmp.appendAll(rulemap(grammar(i).ltoken))
      }
      tmp.append(i -> grammar(i))
      rulemap += (grammar(i).ltoken -> tmp.toArray)
    }
    rulemap
  }
  /**
    * 構文規則がいくつあるかを返す ただし-1番の規則は含めない
    */
  private def rule_size(db: GrammarDB): Int = {
    db.grammar.length
  }
  /**
    * 与えられたidの規則が存在するかどうかを調べる
    * @param {number} id
    * @returns {boolean}
    */
  def hasRuleId(db: GrammarDB, id: Int): Boolean = {
    id >= -1 && id < rule_size(db)
  }
  /**
    * 非終端記号xに対し、それが左辺として対応する定義を得る
    *
    * 対応する定義が存在しない場合は空の配列を返す
    * @param x
    */
  def findRules(db: GrammarDB, x: Token): Array[(Int,GrammarRule[Any])] = {
    db.rulemap.getOrElse(x,Array())
  }
  /**
    * 規則idに対応した規則を返す
    *
    * -1が与えられた時は S' -> S $の規則を返す
    * @param id
    */
  def getRuleById(db: GrammarDB, id: Int): GrammarRule[Any] = {
    if (id == -1) GrammarRule[Any](SYMBOL_SYNTAX, List(db.start_symbol), None)
    // GrammarRule(SYMBOL_SYNTAX, Array(this.start_symbol, SYMBOL_EOF))
    else if (id >= 0 && id < db.grammar.length) db.grammar(id)
    else throw new Error("grammar id out of range");
  }
  /**
    * [[Token]]を与えると一意なidを返す
    * @param {Token} token
    * @returns {number}
    */
  def getTokenId(db: GrammarDB, token: Token): Int = {
    if (!db.tokenmap.contains(token)) {
      throw new Error("invalid token "+token)
    }
    db.tokenmap(token)
  }
}
