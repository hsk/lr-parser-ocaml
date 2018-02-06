open Token
open Utils
open Closureitem
open Closureset
open Grammardb

type edge = int M.t
type node = {closure: closureSet; edge: edge}
type dfa = node list

(* DFAの生成 *)
let generateLR1DFA db : dfa =
  [| { closure = genClosureSet db [|genClosureItem db (-1) 0 [|"EOF"|]|]; edge = M.empty} |] |>
  (* 変更がなくなるまでループ *)
  let rec loop dfa =
    match updateDFA 0 (dfa, false) with
    | dfa,true -> loop dfa
    | dfa,_ -> Array.to_list dfa
  and updateDFA i (dfa, flg) =
    if i >= Array.length dfa then (dfa,flg) else updateDFA (i+1) (
      (* 新しいノードを生成する *)
      generateNewClosureSets dfa.(i).closure |>
      ((dfa,flg) |> M.fold_left(fun (dfa,flg) (label, cs) ->
        let new_node = {closure=cs; edge=M.empty} in
        (* 既存のNodeのなかに同一のClosureSetを持つものがないか調べる *)
        let (index,dfa,flg) =
          try (Array.findIndex (fun v -> Closureset.isSameLR1 new_node.closure v.closure) dfa,dfa,flg)
          with _ -> (Array.length dfa,Array.add dfa new_node, true)
        in
        (* 辺の追加 *)
        if M.mem label dfa.(i).edge then (dfa,flg) else begin
          dfa.(i) <- {dfa.(i) with edge = M.add label index dfa.(i).edge}; (* DFAを更新 *)
          (dfa,true)
        end
      ))
    )
  (* 既存のClosureSetから新しい規則を生成し、対応する記号ごとにまとめる *)
  and generateNewClosureSets cs: closureSet M.t =
    (* 規則から新しい規則を生成し、対応する記号ごとにまとめる *)
    cs.items |> (M.empty |> Array.fold_left (fun cismap ci ->
      let (_,pattern,_) = getRuleById db ci.rule_id in
      if ci.dot_index = List.length pattern then cismap else (* .が末尾にある場合はスキップ *)
      let label = List.nth pattern ci.dot_index in
      cismap |> M.add_array label (genClosureItem db ci.rule_id (ci.dot_index + 1) ci.lookaheads)
    )) |> M.map (genClosureSet db) (* ClosureItemの配列からClosureSetに変換 *)
  in loop

(* LR(1)オートマトンの先読み部分をマージして、LALR(1)オートマトンを作る *)
let generateLALR1DFA db lr_dfa : dfa =
  let base = Array.of_list lr_dfa in
  let merge_to = MI.empty|>(0|>let rec mergeLoop1 i merge_to =
  if i >= Array.length base then merge_to else mergeLoop1 (i+1) begin
    if MI.mem i merge_to then merge_to else
    merge_to|>((i+1)|>let rec mergeLoop2 ii merge_to =
    if ii >= Array.length base then merge_to else mergeLoop2 (ii+1) begin
      if MI.mem ii merge_to then merge_to else
      if Closureset.isSameLR0 base.(i).closure base.(ii).closure then begin
        base.(i) <- {closure=Closureset.mergeLA(db,base.(i).closure, base.(ii).closure); edge= base.(i).edge};
        MI.add ii i merge_to
      end else merge_to
    end in mergeLoop2)
  end in mergeLoop1) in
  let rec find_merge_to index =
    try find_merge_to (MI.find index merge_to) with _ -> index
  in
  (* マージした部分を配列から抜き取る *)
  let (_,_,o2n,nodes) = Array.fold_left (fun (o,n,o2n,nodes) node ->
    try (o+1,n,o2n|>MI.add o (o2n|>MI.find(find_merge_to o)),nodes) (* マージ先oをo2nに保存する *)
    with _ -> (o+1,n+1,o2n|>MI.add o n,node::nodes) (* 検索失敗時はマージされていない *)
  ) (0,0,MI.empty,[]) base in
  (* o2n対応表をもとに辺情報を書き換える *)
  nodes|>([]|>List.fold_left (fun ls node -> {
    closure=node.closure;
    edge=node.edge |> M.map (fun o -> MI.find o o2n)
  }::ls))
