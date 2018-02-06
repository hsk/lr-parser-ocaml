open Utils
open Dfagenerator
open Grammardb
open Closureitem

(* LR0部分が同じ2つのClosureItemから先読部分をマージ *)
let merge_item db ci1 ci2 =
  if not (isSameLR0 ci1 ci2) then failwith "null" else (* LR0部分が違う *)
  if isSameLR1 ci1 ci2 then ci1 else (* 完全一致 *)
  genClosureItem db ci1.rule_id ci1.dot_index ( (* ソートはgenClosureItem 内部で行われる *)
    S.union (S.of_list (Array.to_list ci1.lookaheads)) (S.of_list (Array.to_list ci2.lookaheads))
    |> S.elements |> Array.of_list
  )

(* LR(0)部分が同じ2つのClosureSetについて、先読み部分を統合した新しいClosureSetを生成 *)
let merge_set db cs1 cs2: Closureset.closureSet =
  if not (Closureset.isSameLR0 cs1 cs2) then failwith "null" else (* LR0部分が違う *)
  if Closureset.isSameLR1 cs1 cs2 then cs1 else (* LR1部分まで同じ *)
  let a1, a2 = cs1.Closureset.items, cs2.Closureset.items in
  Closureset.genClosureSet db (Array.mapi (fun i a1 -> merge_item db a1 a2.(i)) a1)

(* LR(1)オートマトンの先読み部分をマージして、LALR(1)オートマトンを作る *)
let generateLALR1DFA db lr_dfa : dfa =
  (* 配列をマージ *)
  let base = Array.of_list lr_dfa in
  let history = MI.empty|>(0|>let rec mergeLoop1 i history = (* i番目のマージ処理 *)
  if i >= Array.length base then history else mergeLoop1 (i+1) begin
    if MI.mem i history then history else (* マージ済 *)
    history|>((i+1)|>let rec mergeLoop2 ii history = (* i番とi番目以降のアイテム集合とマージ *)
    if ii >= Array.length base then history else mergeLoop2 (ii+1) begin
      if MI.mem ii history then history else (* マージ済 *)
      try (* とにかくマージを試みる *)
        base.(i) <- {base.(i) with closure=merge_set db base.(i).closure base.(ii).closure}; (* マージ *)
        MI.add ii i history (* 履歴更新 *)
      with _ -> history (* 失敗したら何もしない *)
    end in mergeLoop2)
  end in mergeLoop1) in
  (* マージした部分を取り出しつつ新旧対応表を作る *)
  let rec find_history o = (* マージ履歴を再帰的に検索 *)
    try find_history (MI.find o history) with _ -> o
  in
  let (_,_,nodes,old2new) = Array.fold_left (fun (o,n,nodes,old2new) node ->
    try (o+1,n,nodes,old2new|>MI.add o (old2new|>MI.find(find_history o))) (* マージ先oをold2newに保存する *)
    with _ -> (o+1,n+1,node::nodes,old2new|>MI.add o n) (* 検索失敗時はマージされていない *)
  ) (0,0,[],MI.empty) base in
  (* old2new対応表をもとに辺情報を書き換える *)
  nodes|>List.rev|>List.map (fun node -> {node with edge=node.edge |> M.map (fun o -> MI.find o old2new)})
