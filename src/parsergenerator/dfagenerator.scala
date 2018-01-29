package pg.parsergenerator

import pg.token.{SYMBOL_EOF, Token}
import closureitem.{ClosureItem,genClosureItem}
import closureset.{ClosureSet,genClosureSet,getArray}
import grammardb.{GrammarDB,getRuleById}
import scala.collection.mutable.ArrayBuffer

object dfagenerator {

  type DFAEdge = Map[Token, Int]
  case class DFANode(closure: ClosureSet, edge: DFAEdge)
  type DFA = List[DFANode]
  case class DFAGenerator(grammardb: GrammarDB, lr_dfa: DFA, lalr_dfa: DFA)

  /**
    * 構文規則からLR(1)DFAおよびLALR(1)DFAを生成する
    * @param {GrammarDB} grammardb 構文規則
    */
  def genDFAGenerator(grammardb: GrammarDB):DFAGenerator = {
    val lr_dfa = generateDFA(grammardb)
    val lalr_dfa = mergeLA(null, lr_dfa)
    DFAGenerator(grammardb, lr_dfa, lalr_dfa)
  }
  /**
    * 既存のClosureSetから新しい規則を生成し、対応する記号ごとにまとめる
    * @param closureset
    */
  private def generateNewClosureSets(grammardb: GrammarDB, closureset: ClosureSet): Map[Token, ClosureSet] = {
    var tmp = Map[Token, Array[ClosureItem]]()
    // 規則から新しい規則を生成し、対応する記号ごとにまとめる
    for (item <- getArray(closureset)) {
      val rule_id = item.rule_id
      val dot_index = item.dot_index
      val lookaheads = item.lookaheads
      val pattern = getRuleById(grammardb, rule_id).pattern
      if (dot_index == pattern.length) {} else { // .が末尾にある場合はスキップ
        val new_ci = genClosureItem(grammardb, rule_id, dot_index + 1, lookaheads)
        val edge_label: Token = pattern(dot_index)

        val items = ArrayBuffer[ClosureItem]()
        if (tmp.contains(edge_label)) {
          // 既に同じ記号が登録されている
          items.appendAll(tmp(edge_label))
        }
        items.append(new_ci)
        tmp += (edge_label -> items.toArray)
      }
    }
    // ClosureItemの配列からClosureSetに変換
    var result = Map[Token, ClosureSet]()
    for ((edge_label, items) <- tmp) {
      result += (edge_label -> genClosureSet(grammardb, items))
    }
    result
  }
  /**
    * DFAの生成
    */
  private def generateDFA(grammardb: GrammarDB):DFA = {
    val initial_item: ClosureItem = genClosureItem(grammardb, -1, 0, Array(SYMBOL_EOF))
    val initial_set: ClosureSet = genClosureSet(grammardb, Array(initial_item))
    val dfa = ArrayBuffer(DFANode(initial_set, Map[Token, Int]()))

    // 変更がなくなるまでループ
    var flg_changed = true
    var i = 0
    while (flg_changed) {
      flg_changed = false
      while (i < dfa.length) {
        val closure = dfa(i).closure
        var edge = dfa(i).edge
        val new_sets: Map[Token, ClosureSet] = generateNewClosureSets(grammardb, closure)

        // 与えられたDFANodeと全く同じDFANodeがある場合、そのindexを返す
        // 見つからなければ-1を返す
        def getIndexOfDuplicatedNode (dfa: ArrayBuffer[DFANode], new_node: DFANode): Int = {
          for ((node, i) <- dfa.zipWithIndex) {
            if (closureset.isSameLR1(new_node.closure, node.closure)) return i
          }
          -1
        };
        // 新しいノードを生成する
        for ((edge_label, cs) <- new_sets) {
          val new_node = DFANode(cs, Map())
          // 既存のNodeのなかに同一のClosureSetを持つものがないか調べる
          val duplicated_index = getIndexOfDuplicatedNode(dfa, new_node)
          val index_to = if (duplicated_index == -1) {
            // 既存の状態と重複しない
            dfa.append(new_node);
            flg_changed = true;
            dfa.length - 1
          } else {
            // 既存の状態と規則が重複する
            // 新しいノードの追加は行わず、重複する既存ノードに対して辺を張る
            duplicated_index
          }
          // 辺を追加する
          if (!edge.contains(edge_label)) {
            edge += (edge_label -> index_to)
            // 新しい辺が追加された
            flg_changed = true
            // DFAを更新
            dfa(i) = DFANode(closure, edge)
          }
        }
        i+=1
      }
      i = 0
    }
    dfa.toList
  }
  /**
    * LR(1)オートマトンの先読み部分をマージして、LALR(1)オートマトンを作る
    */
  private def mergeLA(lalr_dfa:DFA, lr_dfa: DFA):DFA = {
    if (lalr_dfa != null || lr_dfa == null) return lalr_dfa
    val base: Array[DFANode] = lr_dfa.toArray // nullを許容する
    var merge_to = Map[Int,Int]() // マージ先への対応関係を保持する

    for (i <- 0 until base.length) {
      if (base(i) == null) {} else
        for (ii <- (i + 1) until base.length) {
          if (base(ii) == null) {} else
          // LR(0)アイテムセット部分が重複
          if (closureset.isSameLR0(base(i).closure, base(ii).closure)) {
            // ii番目の先読み部分をi番目にマージする
            // インデックス番号の大きい方が削除される
            // 辺情報は、削除された要素の持つ辺の対象もいずれマージされて消えるため操作しなくてよい

            // 更新
            // Nodeに変更をかけるとLR(1)DFAの中身まで変化してしまうため新しいオブジェクトを生成する
            base(i) = DFANode(closureset.mergeLA(base(i).closure, base(ii).closure), base(i).edge)
            // ii番目を削除
            base(ii) = null
            // マージ元->マージ先への対応関係を保持
            merge_to += (ii -> i)
          }
        }
    }
    // 削除した部分を配列から抜き取る
    val prev_length = base.length // ノードをマージする前のノード総数
    val fix = new Array[Int](prev_length) // (元のindex->現在のindex)の対応表を作る
    var d = 0 // ずれ
    // nullで埋めた部分を消すことによるindexの変化
    for (i <- 0 until prev_length) {
      if (base(i) == null) d += 1 // ノードが削除されていた場合、以降のインデックスを1つずらす
      else fix(i) = i - d
    }
    // 配列からnull埋めした部分を削除したものを作る
    val shortened = ArrayBuffer[DFANode]()
    for (node <- base) {
      if (node != null) shortened.append(node)
    }
    // fixのうち、ノードが削除された部分を正しい対応で埋める
    for ((from, to) <- merge_to) {
      var index = to
      while (merge_to.contains(index)) {
        index = merge_to(index)
      }
      if (index != to) merge_to += (to -> index) // 対応表を更新しておく
      fix(from) = fix(index) // toを繰り返し辿っているので未定義部分へのアクセスは発生しない
    }

    var result = ArrayBuffer[DFANode]()
    // インデックスの対応表をもとに辺情報を書き換える
    for (node <- shortened) {
      var new_edge = Map[Token, Int]()
      for ((token, node_index) <- node.edge) {
        new_edge += (token -> fix(node_index))
      }
      result.append(DFANode(node.closure, new_edge))
    }
    result.toList
  }
}
