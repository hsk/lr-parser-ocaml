package pg.parsergenerator

import pg.token.{Token}
import grammardb.{GrammarDB,hasRuleId,getRuleById,getTokenId}

object closureitem {

  /**
   * 単一のLRアイテムであり、`S -> A . B [$]` のようなアイテムの規則id・ドットの位置・先読み記号の集合の情報を持つ
   *
   * [[GrammarDB]]から与えられるトークンIDをもとにして、LR(0)およびLR(1)アイテムとしてのハッシュ値を生成することができる
   *
   * Immutableであるべきオブジェクトであるため、インスタンス生成後は内部状態が変化することはないと仮定される
   */
  case class ClosureItem(grammardb: GrammarDB, rule_id: Int, dot_index: Int, lookaheads: Array[Token], lr0_hash: String, lr1_hash: String) {
    override def equals(a:Any): Boolean = {
      a match {
        case b:ClosureItem => isSameLR1(this, b)
        case _ => false
      }
    }
  }
  /**
    * @param {GrammarDB} grammardb 使用する構文の情報
    * @param {number} _rule_id 構文のid
    * @param {number} _dot_index ドットの位置
    * @param {Array<Token>} _lookaheads 先読み記号の集合
    */
  def genClosureItem(grammardb: GrammarDB, rule_id: Int, dot_index: Int, lookaheads: Array[Token]) : ClosureItem = {
    // 有効な値かどうか調べる
    if (!hasRuleId(grammardb, rule_id))
      throw new Error("invalid grammar id")
    if (dot_index < 0 || dot_index > getRuleById(grammardb, rule_id).pattern.length)
      throw new Error("dot index out of range")
    if (lookaheads.length == 0) // 必要か？
      throw new Error("one or more lookahead symbols needed")
    val lookaheads2 = sortLA(grammardb, lookaheads)
    val (lr0_hash,lr1_hash) = genHash(grammardb, rule_id, dot_index, lookaheads2)
    ClosureItem(grammardb, rule_id, dot_index, lookaheads2, lr0_hash, lr1_hash)
  }

  /**
    * ハッシュ文字列を生成する
    */
  private def genHash(grammardb: GrammarDB, rule_id: Int, dot_index: Int, lookaheads: Array[Token]):(String,String) = {
    val lr0_hash = rule_id.toString() + "," + dot_index.toString()
    var la_hash = "["
    for (i <- 0 until lookaheads.length) {
      la_hash = la_hash+getTokenId(grammardb, lookaheads(i)).toString()
      if (i != lookaheads.length - 1) la_hash = la_hash+","
    }
    la_hash = la_hash+"]"
    val lr1_hash = lr0_hash + "," + la_hash
    (lr0_hash,lr1_hash)
  }

  /**
    * 先読み記号の配列を、[[GrammarDB]]によって割り振られるトークンid順にソートする
    */
  private def sortLA(grammardb: GrammarDB, lookaheads: Array[Token]):Array[Token] = {
    lookaheads.toList.sortWith{(t1: Token, t2: Token) =>
      getTokenId(grammardb, t1) < getTokenId(grammardb, t2)
    }.toArray
  }
  /**
    * LR(0)ハッシュの一致を調べる
    * @param {ClosureItem} c 比較対象のLRアイテム
    * @returns {boolean}
    */
  def isSameLR0(s: ClosureItem, c: ClosureItem): Boolean = s.lr0_hash == c.lr0_hash

  /**
    * LR(1)ハッシュの一致を調べる
    * @param {ClosureItem} c 比較対象のLRアイテム
    * @returns {boolean}
    */
  def isSameLR1(s: ClosureItem, c: ClosureItem): Boolean = s.lr1_hash == c.lr1_hash

  /**
    * LR0部分を維持しながらLR1先読み記号ごとにClosureItemを分割し、先読み記号の数が1のClosureItemの集合を生成する
    */
  def separateByLookAheads(s: ClosureItem): Array[ClosureItem] = {
    // s.lookaheadsの要素数が1未満の状況は存在しない
    s.lookaheads.map{la=>
      genClosureItem(s.grammardb, s.rule_id, s.dot_index, Array(la))
    }.toArray
  }

  /**
    * LR0部分が同じ2つのClosureItemについて、先読み部分を統合した新しいClosureItemを生成する
    *
    * 異なるLR(0)アイテムであった場合、nullを返す
    * @param {ClosureItem} c マージ対象のLRアイテム
    * @returns {ClosureItem | null} 先読み部分がマージされた新しいLRアイテム
    */
  def merge(s: ClosureItem, c: ClosureItem): ClosureItem = {
    // LR0部分が違っている場合はnullを返す
    if (!isSameLR0(s, c)) return null
    // LR1部分まで同じ場合は自身を返す
    if (isSameLR1(s, c)) return s
    // 双方のlookaheads配列はソート済みであると仮定できる
    var i1 = 0
    var i2 = 0
    var new_la = scala.collection.mutable.ArrayBuffer[Token]()
    // 2つのLA配列をマージして新しい配列を生成する
    while (i1 < s.lookaheads.length || i2 < c.lookaheads.length) {
      if (i1 == s.lookaheads.length) {
        new_la.append(c.lookaheads(i2));i2+=1
      } else if (i2 == c.lookaheads.length) {
        new_la.append(s.lookaheads(i1));i1+=1
      } else if (s.lookaheads(i1) == c.lookaheads(i2)) {
        new_la.append(s.lookaheads(i1));i1+=1;i2+=1
      } else if (getTokenId(s.grammardb, s.lookaheads(i1)) < getTokenId(s.grammardb, c.lookaheads(i2))) {
        new_la.append(s.lookaheads(i1));i1+=1
      } else {
        new_la.append(c.lookaheads(i2));i2+=1
      }
    }
    genClosureItem(s.grammardb, s.rule_id, s.dot_index, new_la.toArray)
  }

}
