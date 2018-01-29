package pg.parsergenerator

import pg.language.{Language}
import pg.parsingtable.{ParsingTable, Accept, Conflict, Goto, ParsingOperation, Reduce, Shift}
import pg.token.{SYMBOL_EOF, Token}
import pg.parser.factory.{ParserFactory}
import pg.parser.parser.{Parser}
import dfagenerator.{DFA, DFAGenerator, genDFAGenerator}
import grammardb.{GrammarDB,genGrammarDB,getRuleById}
import closureset.{getArray}
import symboldiscriminator.{isTerminalSymbol, isNonterminalSymbol}

object parsergenerator {

  /**
   * 言語定義から構文解析表および構文解析器を生成するパーサジェネレータ
   */
  case class ParserGenerator(language: Language, grammardb: GrammarDB, dfa_generator: DFAGenerator, parsing_table: ParsingTable, table_type: String)
  // "LR1" | "LALR1" | "CONFLICTED"
  /**
   * @param {Language} language 言語定義
   */
  def genParserGenerator(language: Language):ParserGenerator = {
    val grammardb = genGrammarDB(language)
    val dfa_generator = genDFAGenerator(grammardb)
    val (lalr_table, lalr_success) = generateParsingTable(grammardb, dfa_generator.lalr_dfa);
    if (lalr_success) ParserGenerator(language, grammardb, dfa_generator, lalr_table, "LALR1")
    else {
      // LALR(1)構文解析表の生成に失敗
      // LR(1)構文解析表の生成を試みる
      System.err.println("LALR parsing conflict found. use LR(1) table.")
      val (lr_table, lr_success) = generateParsingTable(grammardb, dfa_generator.lr_dfa)
      if (lr_success) ParserGenerator(language, grammardb, dfa_generator, lr_table, "LR1")
      else {
        // LR(1)構文解析表の生成に失敗
        System.err.println("LR(1) parsing conflict found. use LR(1) conflicted table.")
        ParserGenerator(language, grammardb, dfa_generator, lr_table, "CONFLICTED")
      }
    }
  }

  type Res = (ParsingTable, Boolean)
  /**
    * DFAから構文解析表を構築する
    * @param {DFA} dfa
    */
  private def generateParsingTable(grammardb: GrammarDB, dfa: DFA): Res = {
    var flg_conflicted = false

    val parsing_table = dfa.map{node =>
      var table_row = Map[Token, ParsingOperation]()
      // 辺をもとにshiftとgotoオペレーションを追加
      for ((label, to) <- node.edge) {
        if (isTerminalSymbol(grammardb.symbols, label)) {
          // ラベルが終端記号の場合
          // shiftオペレーションを追加
          table_row += (label -> Shift(to))
        } else if (isNonterminalSymbol(grammardb.symbols, label)) {
          // ラベルが非終端記号の場合
          // gotoオペレーションを追加
          table_row += (label -> Goto(to))
        }
      }

      // Closureをもとにacceptとreduceオペレーションを追加していく
      for (item <- getArray(node.closure)) {
        // 規則末尾が.でないならスキップ
        // if(item.pattern.getRuleById(item.pattern.size-1) != SYMBOL_DOT) return;
        if (item.dot_index != getRuleById(grammardb, item.rule_id).pattern.length) {} else
        if (item.rule_id == -1) {
          // acceptオペレーション
          // この規則を読み終わると解析終了
          // $をラベルにacceptオペレーションを追加
          table_row += (SYMBOL_EOF -> Accept)
        } else
          for (label <- item.lookaheads) {
            val operation = Reduce(item.rule_id)
            // 既に同じ記号でオペレーションが登録されていないか確認

            if (table_row.contains(label)) {
              // コンフリクトが発生
              flg_conflicted = true // 構文解析に失敗
              val existing_operation = table_row(label) // 上で.has(label)のチェックを行っているためnon-nullable
              val conflicted_operation =
                existing_operation match {
                  case Shift(to) => // shift/reduce コンフリクト
                    Conflict(List(to),List(operation.grammar_id))
                  case Reduce(grammar_id) => // reduce/reduce コンフリクト
                    Conflict(List(), List(grammar_id, operation.grammar_id))
                  case Conflict(shift_to,reduce_grammar) => // もっとやばい衝突
                    Conflict(shift_to, reduce_grammar:::List(operation.grammar_id))
                  case _ => Conflict(List(), List())
                }
              // とりあえず衝突したオペレーションを登録しておく
              table_row += (label -> conflicted_operation)
            }
            else {
              // 衝突しないのでreduceオペレーションを追加
              table_row += (label -> operation)
            }
          }
      }
      table_row
    }
    (parsing_table, !flg_conflicted)
  }
  /**
    * 構文解析器を得る
    * @returns {Parser}
    */
  def getParser(gen: ParserGenerator): Parser = {
    ParserFactory.create(gen.language, gen.parsing_table)
  }

  /**
    * 生成された構文解析表に衝突が発生しているかどうかを調べる
    * @returns {boolean}
    */
  def isConflicted(gen: ParserGenerator): Boolean = {
    gen.table_type == "CONFLICTED"
  }
}
