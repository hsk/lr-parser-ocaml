package pg.parsergenerator

import pg.language.{GrammarDefinition}
import pg.token.{SYMBOL_EOF, Token}
import nullableset.{NullableSet,generateNulls,isNullable}
import symboldiscriminator.{SymbolDiscriminator}
import scala.collection.mutable.ArrayBuffer

object firstset {

  /**
    * First集合
    */
  case class FirstSet(first_map: Map[Token, Set[Token]], nulls: NullableSet)

  private case class Cons(superset: Token, subset: Token)
  private type Constraint = Array[Cons]

  /**
    * First集合を生成する
    * @param {GrammarDefinition} grammar 構文規則
    * @param {SymbolDiscriminator} symbols 終端/非終端記号の判別に用いる分類器
    */
  def generateFirst(grammar: GrammarDefinition, symbols: SymbolDiscriminator):FirstSet = {
    val nulls = generateNulls(grammar)
    // Firstを導出
    var first_result: Map[Token, Set[Token]] = Map[Token, Set[Token]]()
    // 初期化
    // FIRST($) = {$} だけ手動で追加
    first_result += (SYMBOL_EOF -> Set(SYMBOL_EOF))
    // 終端記号Xに対してFirst(X)=X
    val terminal_symbols = symbols.terminal_symbols
    terminal_symbols.foreach{(value: Token) =>
      first_result += (value -> Set(value))
    }
    // 非終端記号はFirst(Y)=∅で初期化
    val nonterminal_symbols = symbols.nonterminal_symbols
    nonterminal_symbols.foreach{(value: Token) =>
      first_result += (value -> Set[Token]())
    }

    // 包含についての制約を生成
    var constraint = ArrayBuffer[Cons]()
    for (rule <- grammar) {
      val sup: Token = rule.ltoken
      // 右辺の左から順に、non-nullableな記号が現れるまで制約に追加
      // 最初のnon-nullableな記号は制約に含める
      var endflg = false
      for (sub <- rule.pattern if(!endflg)) {
        if (sup != sub) constraint.append(Cons(sup, sub))
        if (!isNullable(nulls, sub)) endflg = true
      }
    }

    // 制約解消
    var flg_changed = true
    while (flg_changed) {
      flg_changed = false
      for (pair <- constraint) {
        val sup: Token = pair.superset
        val sub: Token = pair.subset
        var superset: Set[Token] = first_result(sup)
        val subset: Set[Token] = first_result(sub)
        subset.foreach{(token: Token) =>
          // subset内の要素がsupersetに含まれていない
          if (!superset.contains(token)) {
            // subset内の要素をsupersetに入れる
            superset += token
            flg_changed = true
          }
        }
        // First集合を更新
        first_result += (sup -> superset)
      }
    }
    FirstSet(first_result,nulls)
  }

  /**
    * 記号または記号列を与えて、その記号から最初に導かれうる非終端記号の集合を返す
    * @param {Token | Token[]} arg
    * @returns {Set<Token>}
    */
  def get(set:FirstSet, arg: Token): Set[Token] = {
    // 単一の記号の場合
    if (!set.first_map.contains(arg))
      throw new Error("invalid token found: "+ arg)
    set.first_map(arg)
  }

  def getFromList(set:FirstSet, tokens: List[Token]): Set[Token] = {
    // 記号列の場合
    var result = Set[Token]()
    var endflg = false
    for (token <- tokens) {
      // 不正な記号を発見
      if (!set.first_map.contains(token)) throw new Error("invalid token found: "+token)
      if (!endflg) {
        // トークン列の先頭から順にFirst集合を取得
        result ++= set.first_map(token) // 追加
        if (!isNullable(set.nulls, token)) // 現在のトークン ∉ Nulls ならばここでストップ
          endflg = true
      }
    }
    result
  }

}
