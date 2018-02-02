open Token
open Closureitem
open Closureset
open Grammardb

type edge = int M.t
type node = {closure: closureSet; edge: edge}
type dfa = node list
type generator = {lr_dfa: dfa; lalr_dfa: dfa}

(* 既存のClosureSetから新しい規則を生成し、対応する記号ごとにまとめる *)
let generateNewClosureSets((grammardb: grammarDB), (closureset: closureSet)): closureSet M.t =
  (* 規則から新しい規則を生成し、対応する記号ごとにまとめる *)
  let tmp = Array.fold_left (fun tmp i ->
    let (_,pattern,_) = getRuleById(grammardb, i.rule_id) in
    if i.dot_index = List.length pattern then tmp else (* .が末尾にある場合はスキップ *)
    let new_ci = genClosureItem grammardb i.rule_id (i.dot_index + 1) i.lookaheads in
    let edge_label = List.nth pattern i.dot_index in
    let items = if M.mem edge_label tmp then M.find edge_label tmp else [||] in
    M.add edge_label (Array.append items [|new_ci|]) tmp
  ) M.empty (getArray(closureset)) in
  (* ClosureItemの配列からClosureSetに変換 *)
  M.fold_left (fun result (edge_label, items) ->
    M.add edge_label (genClosureSet grammardb items) result
  ) M.empty tmp

(* 与えられたnodeと全く同じnodeがある場合、そのindexを返す *)
(* 見つからなければ-1を返す *)
let getIndexOfDuplicatedNode (dfa, new_node): int =
  let rec loop i =
    if (Array.length dfa) <= i then -1 else
    if Closureset.isSameLR1(new_node.closure, dfa.(i).closure) then i else
    loop (i+1)
  in loop 0

(* DFAの生成 *)
let generateDFA(grammardb: grammarDB):dfa =
  let rec loop1 i dfa flg =
    let closure = dfa.(i).closure in
    (* 新しいノードを生成する *)
    let (dfa,_,flg) = M.fold_left(fun (dfa,edge,flg) (edge_label, cs) ->
      let new_node = {closure=cs; edge=M.empty} in
      (* 既存のNodeのなかに同一のClosureSetを持つものがないか調べる *)
      let index = getIndexOfDuplicatedNode(dfa, new_node) in
      let (dfa,index_to,flg) = if index > -1 then (* 既存の状態と規則が重複する *)
        (dfa,index,flg)
      else (Array.append dfa [|new_node|], Array.length dfa,true)
      in
      (* 辺を追加する *)
      if M.mem edge_label edge then (dfa,edge,flg) else begin
        let edge = M.add edge_label index_to edge in
        dfa.(i) <- {closure; edge}; (* DFAを更新 *)
        (dfa,edge,true)
      end
    ) (dfa,dfa.(i).edge,flg) (generateNewClosureSets(grammardb, closure)) in
    if i+1 < Array.length dfa then loop1 (i+1) dfa flg else (dfa,flg)
  in
  (* 変更がなくなるまでループ *)
  let rec loop dfa =
    match loop1 0 dfa false with
    | dfa,true -> loop dfa
    | dfa,_ -> dfa
  in
  let item = genClosureItem grammardb (-1) 0 [|"EOF"|] in
  let set = genClosureSet grammardb [|item|] in
  Array.to_list (loop [|{closure=set; edge= M.empty}|])

(* LR(1)オートマトンの先読み部分をマージして、LALR(1)オートマトンを作る *)
let mergeLA(grammardb, lr_dfa):dfa =
  let merge_to = ref MI.empty in (* マージ先への対応関係を保持する *)
  let rec findIndex index =
    if not (MI.mem index !merge_to) then index else (
      let i2 = findIndex (MI.find index !merge_to) in
      merge_to := MI.add index i2 !merge_to; (* 対応表を更新 *)
      i2
    )
  in
  let base = Array.of_list lr_dfa in
  for i = 0 to Array.length base - 1 do
    if MI.mem i !merge_to then () else
    for ii = (i + 1) to Array.length base - 1 do
      if MI.mem ii !merge_to then () else
      if Closureset.isSameLR0(base.(i).closure, base.(ii).closure) then begin
        base.(i) <- {closure=Closureset.mergeLA(grammardb,base.(i).closure, base.(ii).closure); edge= base.(i).edge};
        merge_to := MI.add ii i !merge_to
      end
    done
  done;
  (* 削除した部分を配列から抜き取る *)
  let (_,_,fix,nodes) = Array.fold_left (fun (i,ii,fix,nodes) node ->
    if MI.mem i !merge_to then (i+1,ii,ii::fix,nodes)
    else (i+1,ii+1,ii::fix,node::nodes)
  ) (0,0,[],[]) base in
  let fix = Array.of_list (List.rev fix) in
  (* fixのうち、ノードが削除された部分を正しい対応で埋める *)
  MI.iter (fun i to1 -> fix.(i) <- fix.(findIndex to1)) !merge_to;
  (* インデックスの対応表をもとに辺情報を書き換える *)
  List.fold_left (fun result node ->
    let edge = M.fold_left (fun edge (token, node_index) ->
      M.add token fix.(node_index) edge
    ) M.empty node.edge in
    {closure=node.closure; edge} :: result
  ) [] nodes

(* 構文規則からLR(1)DFAおよびLALR(1)DFAを生成する *)
let genDFAGenerator(grammardb: grammarDB):generator = 
  let lr_dfa = generateDFA(grammardb) in
  {lr_dfa; lalr_dfa=mergeLA(grammardb, lr_dfa)}
