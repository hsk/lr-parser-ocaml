package pg.parsergenerator

import pg.language.GrammarDefinition
import pg.token.Token

object nullableset {

  /**
   * ある非終端記号から空列が導かれうるかどうかを判定する
   */
  type NullableSet = Set[Token]

  /**
   * @param {GrammarDefinition} grammar 構文規則
   */
  def generateNulls(grammar: GrammarDefinition):NullableSet = {
    // 制約条件を導出するために、
    // 空列になりうる記号の集合nullsを導出
    var nulls = grammar.filter{_.pattern.length==0}.map(_.ltoken).toSet
    // 右辺の記号の数が0の規則を持つ記号は空列になりうる

    // 変更が起きなくなるまでループする
    var flg_changed: Boolean = true
    while (flg_changed) {
      flg_changed = false
      for (rule <- grammar if (!nulls.contains(rule.ltoken) && !rule.pattern.exists(!nulls.contains(_)))) {
        // 既にnullsに含まれていればスキップ
        // 右辺に含まれる記号がすべてnullableの場合はその左辺はnullable
        flg_changed = true
        nulls += rule.ltoken
      }
    }
    nulls
  }

  /**
   * 与えられた[[Token]]がNullableかどうかを調べる
   * @param {Token} token
   * @returns {boolean}
   */
  def isNullable(set:NullableSet, token: Token):Boolean = set.contains(token)
}
