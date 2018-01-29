import pg.language.{GrammarDefinition}
import pg.parsingtable.{ParsingTable,Shift,Reduce,Conflict,Accept,Goto}
import pg.token.{Token, TokenizedInput}
import pg.lexer.{Lexer,exec}
import callback.{CallbackController}
import scala.annotation.tailrec

(**
  * 構文解析器
  *)
case class Parser(lexer: Lexer, grammar: GrammarDefinition, parsingtable: ParsingTable, callback_controller: CallbackController)
(**
  * 構文解析を実行する
  * @param {string} input 解析する入力文字列
  * @returns {any} 解析結果(返る結果はコントローラによって異なる)
  *)
let parse(p: Parser, input: String): Any = {
  // parsingtableはconflictを含む以外は正しさが保証されているものと仮定する
  // inputsは正しくないトークンが与えられる可能性を含む
  // TODO: 詳細な例外処理、エラー検知
  val (error,result_stack) = actions(p, exec(p.lexer, input),List(0),List())
  if (error != "") {
    System.err.println(error)
    System.err.println("parse failed.")
  }
  if (result_stack.length != 1) {
    System.err.println("failed to construct tree.")
  }
  result_stack(0)
}

@tailrec private def drop(rnum: Int, acc: List[Any], res: List[Any]): (List[Any], List[Any]) = {
  (rnum, acc, res) match {
    case (0, acc, res) => (acc, res)
    case (n, acc, a :: res) => drop(n - 1, a :: acc, res)
    case _ => throw new Exception("stack is empty")
  }
}

// 構文解析する
// states 現在読んでいる構文解析表の状態番号を置くスタック
// results 解析中のASTノードを置くスタック
@tailrec private def actions(p: Parser, inputs: List[TokenizedInput],states:List[Int],results:List[Any]):(String,List[Any]) = {
  (states, inputs) match {
    case (_, List()) => ("", results)
    case (state::_, (token,value)::inp) =>
      //println("state:"+state+ " token:"+token)
      p.parsingtable(state).get(token) match {
        case None => ("parse failed: unexpected token:" + token + " state:" + state, results) // 未定義
        case Some(Accept) => ("", results) // 構文解析完了
        case Some(Shift(to)) => actions(p, inp, to :: states, value :: results)
        case Some(Reduce(grammar_id)) => // reduceオペレーション
          val grammar_rule = p.grammar(grammar_id)
          val rnum = grammar_rule.pattern.length
          // 右辺の記号の数だけスタックからポップする
          val (children, results2) = drop(rnum, List(), results)
          val child = if (p.callback_controller == null) children(0)
                      else p.callback_controller.callGrammar(grammar_id, children, p.lexer)
          // 対応する規則の右辺の記号の数だけスタックからポップする
          val (states2 @ (state2::_)) = states.drop(rnum)
          // このままgotoオペレーションを行う
          p.parsingtable(state2).get(grammar_rule.ltoken) match {
            case Some(Goto(to)) => actions(p, inputs, to :: states2, child :: results2) // 必ず Gotoアクション
            case None => ("parse failed: unexpected token:" + token + " state:" + state2, child :: results2) // 未定義
            case _ => ("parse failed: goto operation expected after reduce operation", child :: results2)
          }
        case Some(Conflict(shift_to, reduce_grammar)) =>
          var err = "conflict found:\n"
          err += "current state " + state + ":" + p.parsingtable(state) + "\n"
          err += "shift:" + shift_to + ",reduce:" + reduce_grammar + "\n"
          shift_to.foreach { (to: Int) =>
            err += "shift to " + to + ":" + p.parsingtable(to) + "\n"
          }
          reduce_grammar.foreach { (grammar_id: Int) =>
            err += "reduce grammar " + grammar_id + ":" + p.parsingtable(grammar_id) + "\n"
          }
          err += "parser cannot parse conflicted grammar"
          (err, results)
    }
  }
}
