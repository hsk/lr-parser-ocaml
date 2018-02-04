open Language
open Token
open Utils
open Parser
open Dfagenerator
open Grammardb
open Closureset
open Closureitem
open Symboldiscriminator

(* DFAから構文解析表を構築する *)
let generateParsingTable db dfa table_type : (string * parsingTable) =
  let table_type = ref table_type in
  let table = dfa |> List.map (fun node ->
    (* 辺をもとにshiftとgotoオペレーションを追加 *)
    let table_row = M.fold_left(fun table_row (label, to1) ->
      if isTerminalSymbol db.symbols label then M.add label (Shift(to1)) table_row
      else if isNonterminalSymbol db.symbols label then M.add label (Goto(to1)) table_row
      else table_row
    ) M.empty node.edge in
    (* Closureをもとにacceptとreduceオペレーションを追加していく *)
    let table_row = Array.fold_left (fun table_row (item:closureItem) ->
      let (_,pattern,_) = getRuleById db item.rule_id in
      (* 規則末尾が.でないならスキップ *)
      if item.dot_index <> List.length pattern then table_row else
      if item.rule_id = -1 then M.add "EOF" Accept table_row else
      Array.fold_left(fun table_row label ->
        (* 既に同じ記号でオペレーションが登録されていないか確認 *)
        if not (M.mem label table_row) then M.add label (Reduce(item.rule_id)) table_row
        else begin (* コンフリクトが発生 *)
          table_type := "CONFLICTED"; (* 構文解析に失敗 *)
          let conflicted =
            match M.find label table_row with
            | Shift(to1) -> Conflict([to1],[item.rule_id]) (* shift/reduce コンフリクト *)
            | Reduce(grammar_id) -> Conflict([], [grammar_id; item.rule_id]) (* reduce/reduce コンフリクト *)
            | Conflict(shift_to, reduce_grammar) ->
              Conflict(shift_to, reduce_grammar @ [item.rule_id]) (* もっとやばい衝突 *)
            | _ -> Conflict([], [])
          in
          (* とりあえず衝突したオペレーションを登録しておく *)
          M.add label conflicted table_row
        end
      ) table_row item.lookaheads
    ) table_row (node.closure.items) in
    M.bindings table_row
  ) in
  (!table_type, table)

(* 言語定義から構文解析表および構文解析器を生成するパーサジェネレータ *)
let generate language : (string * parsingTable) =
  let db = genGrammarDB language in
  let (lr_dfa:dfa) = generateLR1DFA db in
  let (lalr_dfa:dfa) = generateLALR1DFA db lr_dfa in
  let (table_type, lalr_table) = generateParsingTable db lalr_dfa "LALR1" in
  if table_type <> "CONFLICTED" then (table_type, lalr_table)
  else begin
    (* LALR(1)構文解析表の生成に失敗 *)
    (* LR(1)構文解析表の生成を試みる *)
    Printf.printf "LALR parsing conflict found. use LR(1) table.\n";
    let (table_type, lr_table) = generateParsingTable db lr_dfa "LR1" in
    if table_type <> "CONFLICTED" then (table_type, lr_table)
    else begin
      (* LR(1)構文解析表の生成に失敗 *)
      Printf.fprintf stderr "LR(1) parsing conflict found. use LR(1) conflicted table.\n";
      (table_type, lr_table)
    end
  end

(* 生成された構文解析表に衝突が発生しているかどうかを調べる *)
let isConflicted (table_type, _): bool = table_type = "CONFLICTED"
