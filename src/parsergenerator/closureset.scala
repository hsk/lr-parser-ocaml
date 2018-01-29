package pg.parsergenerator

import pg.token.{Token}
import closureitem.{ClosureItem,genClosureItem,separateByLookAheads,merge}
import grammardb.{GrammarDB,findRules,getRuleById,getTokenId}
import scala.collection.mutable.ArrayBuffer
import firstset.getFromList
import symboldiscriminator.{isNonterminalSymbol}

object closureset {

  /**
   * 複数のLRアイテムを保持するアイテム集合であり、インスタンス生成時に自身をクロージャー展開する
   *
   * [[GrammarDB]]から与えられるトークンIDをもとにして、LR(0)およびLR(1)アイテム集合としてのハッシュ値を生成することができる
   *
   * Immutableであるべきオブジェクトであるため、インスタンス生成後は内部状態が変化することはないと仮定される
   */
  case class ClosureSet(grammardb: GrammarDB, closureset: Array[ClosureItem], lr0_hash: String, lr1_hash: String)

  /**
    * 自身が保持する複数の[[ClosureItem]]は、常にLR(1)ハッシュによってソートされた状態に保たれているようにする
    */
  private def sort(closureset: Array[ClosureItem]):Array[ClosureItem] = {
    closureset.sortWith{(i1: ClosureItem, i2: ClosureItem) =>
      i1.lr1_hash < i2.lr1_hash
    }
  }
  /**
    * ハッシュ文字列を生成する
    */
  private def updateHash(closureset: Array[ClosureItem]):(String,String) = {
    var lr0_hash = ""
    var lr1_hash = ""
    for (i <- 0 until closureset.length) {
      lr0_hash = lr0_hash + closureset(i).lr0_hash
      lr1_hash = lr1_hash + closureset(i).lr1_hash
      if (i != closureset.length - 1) {
        lr0_hash = lr0_hash + "|"
        lr1_hash = lr1_hash + "|"
      }
    }
    (lr0_hash, lr1_hash)
  }

  /**
    * クロージャー展開を行う
    *
    * TODO: リファクタリング
    */
  private def expandClosure(grammardb: GrammarDB, cset:Array[ClosureItem]): Array[ClosureItem] = {
    // 展開処理中はClosureItemのlookaheadsの要素数を常に1に保つこととする
    // 初期化
    val set = ArrayBuffer[ClosureItem]()
    // ClosureItemをlookaheadsごとに分解する
    for (ci <- cset) {
      set.appendAll(separateByLookAheads(ci))
    }
    var closureset = sort(set.toArray)

    // 変更がなくなるまで繰り返す
    var index = 0
    while (index < closureset.length) {
      val ci = closureset(index); index+=1
      val pattern = getRuleById(grammardb, ci.rule_id).pattern

      if (ci.dot_index != pattern.length) { // .が末尾にある場合はスキップ
        val follow = pattern(ci.dot_index)
        if (isNonterminalSymbol(grammardb.symbols, follow)) { // .の次の記号が非終端記号でないならばスキップ

          // クロージャー展開を行う

          // 先読み記号を導出
          // ci.lookaheadsは要素数1のため、0番目のインデックスのみを参照すればよい
          val lookaheads = getFromList(grammardb.first, pattern.slice(ci.dot_index + 1,pattern.length):+ci.lookaheads(0)).toList.sortWith{
            (t1: Token, t2: Token) => getTokenId(grammardb, t1) > getTokenId(grammardb, t2)
          }
          val closureset1 = ArrayBuffer[ClosureItem]()
          closureset1.appendAll(closureset)
          // symbolを左辺にもつ全ての規則を、先読み記号を付与して追加
          val rules = findRules(grammardb, follow)
          for ((id,_) <- rules) {
            for (la <- lookaheads) {
              val new_ci = genClosureItem(grammardb, id, 0, Array(la))
              // 重複がなければ新しいアイテムを追加する
              def flg_duplicated() :Boolean = {
                for (existing_item <- closureset) {
                  if (closureitem.isSameLR1(new_ci, existing_item)) return true
                }
                false
              }
              if (!flg_duplicated()) {
                closureset1.append(new_ci)
              }
            }
          }
          closureset = closureset1.toArray
        }
      }
    }

    // ClosureItemの先読み部分をマージする
    val tmp = sort(closureset)
    val closureset1 = ArrayBuffer[ClosureItem]()
    var merged_lookaheads = ArrayBuffer[Token]()
    for (i <- 0 until tmp.length) {
      merged_lookaheads.append(tmp(i).lookaheads(0))
      if (i == tmp.length - 1 || !closureitem.isSameLR0(tmp(i), tmp(i + 1))) {
        closureset1.append(genClosureItem(grammardb, tmp(i).rule_id, tmp(i).dot_index, merged_lookaheads.toArray))
        merged_lookaheads = ArrayBuffer[Token]()
      }
    }
    closureset1.toArray
  }

  /**
    * @param {GrammarDB} grammardb 使用する構文の情報
    * @param {Array<ClosureItem>} closureset
    */
  def genClosureSet(grammardb: GrammarDB, closureset: Array[ClosureItem]): ClosureSet = {
    val closureset1 = sort(expandClosure(grammardb, closureset))
    val (lr0_hash,lr1_hash) = updateHash(closureset1)
    ClosureSet(grammardb, closureset1, lr0_hash, lr1_hash)
  }
  /**
    * 保持しているLRアイテムの数
    */
  def size(set: ClosureSet) = set.closureset.length
  /**
    * 保持している[[ClosureItem]]の配列を得る
    * @param {boolean} prevent_copy trueを与えると配列をコピーせず返す
    *
    * 得られた配列に変更が加えられないと保証される場合に用いる
    * @returns {Array<ClosureItem>}
    */
  def getArray(set: ClosureSet, prevent_copy: Boolean = false): Array[ClosureItem] = {
    if (prevent_copy) set.closureset
    // デフォルトではコピーして返す(パフォーマンスは少し落ちる)
    else set.closureset.clone()
  }
  /**
    * LRアイテムが集合に含まれているかどうかを調べる
    *
    * @param {ClosureItem} item
    * @returns {boolean}
    */
  def includes(set: ClosureSet, item: ClosureItem): Boolean = {
    // 二分探索を用いて高速に探索する
    var min = 0
    var max = set.closureset.length - 1

    var idx = 0
    //println("item="+item.getLR1Hash())
    for(i<-set.closureset){
      //println("i="+i.getLR1Hash())
      //if(item.getLR1Hash()==i.getLR1Hash()) println("data="+item+ " idx="+idx)
      idx += 1
    }
    while (min <= max) {
      val mid = min + ((max - min) / 2)
      if (item.lr1_hash < set.closureset(mid).lr1_hash) {
        max = mid - 1
      } else if (item.lr1_hash > set.closureset(mid).lr1_hash) {
        min = mid + 1
      } else {
        // itemとclosureset[mid]が等しい
        //println("inc true")
        return true
      }
    }
    //println("inc false min:"+min+" max:"+max)
    false
  }
  /**
    * LR(0)ハッシュの一致を調べる
    * @param {ClosureSet} cs 比較対象のアイテム集合
    * @returns {boolean}
    */
  def isSameLR0(set: ClosureSet, cs: ClosureSet): Boolean = {
    set.lr0_hash == cs.lr0_hash
  }
  /**
    * LR(1)ハッシュの一致を調べる
    * @param {ClosureSet} cs 比較対象のアイテム集合
    * @returns {boolean}
    */
  def isSameLR1(set: ClosureSet, cs: ClosureSet): Boolean = {
    set.lr1_hash == cs.lr1_hash
  }
  /**
    * LR(0)部分が同じ2つのClosureSetについて、先読み部分を統合した新しいClosureSetを生成する
    *
    * 異なるLR(0)アイテム集合であった場合、nullを返す
    * @param {ClosureSet} cs マージ対象のアイテム集合
    * @returns {ClosureSet | null} 先読み部分がマージされた新しいアイテム集合
    */
  def mergeLA(set: ClosureSet, cs: ClosureSet): ClosureSet = {
    // LR0部分が違っている場合はnullを返す
    if (!isSameLR0(set, cs)) return null
    // LR1部分まで同じ場合は自身を返す
    if (isSameLR1(set, cs)) return set
    val a1 = getArray(set)
    val a2 = getArray(cs)
    val new_set = ArrayBuffer[ClosureItem]()
    // 2つの配列においてLR部分は順序を含めて等しい
    for (i <- 0 until a1.length) {
      val new_item = merge(a1(i), a2(i))
      if (new_item != null) new_set.append(new_item)
    }
    genClosureSet(set.grammardb, new_set.toArray)
  }

}
