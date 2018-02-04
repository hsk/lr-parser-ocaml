open Token
open Grammardb

(* `S -> A . B [$]` のような LRアイテム *)
type closureItem = {
  rule_id: int; dot_index: int; lookaheads: token array; (* 規則id・ドット位置・先読記号集合 *)
  lr0_hash: string; lr1_hash: string                     (* LR(0)、LR(1)アイテムのハッシュ値 *)
}

(* ハッシュ文字列を生成する *)
let genHash db rule_id dot_index lookaheads =
  let la_hash = Array.to_list lookaheads |> List.map(fun t -> string_of_int (getTokenId db t)) in
  let lr0_hash = Printf.sprintf "%d,%d" rule_id dot_index in
  let lr1_hash = Printf.sprintf "%s,[%s]" lr0_hash (String.concat "," la_hash) in
  (lr0_hash, lr1_hash)

let isSameLR0 ci1 ci2 = ci1.lr0_hash = ci2.lr0_hash
let isSameLR1 ci1 ci2 = ci1.lr1_hash = ci2.lr1_hash

(* 先読記号配列を、トークンid順にソート *)
let sortLA db lookaheads =
  let lookaheads = Array.copy lookaheads in
  Array.sort (fun t1 t2 -> getTokenId db t1 - getTokenId db t2) lookaheads;
  lookaheads

let genClosureItem db rule_id dot_index lookaheads =
  if not (hasRuleId db rule_id) then failwith "invalid grammar id";
  if (dot_index < 0 || dot_index > List.length (let (_,pattern,_) = getRuleById db rule_id in pattern))
  then failwith "dot index out of range";
  if Array.length lookaheads = 0 then failwith "one or more lookahead symbols needed";
  let lookaheads = sortLA db lookaheads in
  let (lr0_hash,lr1_hash) = genHash db rule_id dot_index lookaheads in
  {rule_id; dot_index; lookaheads; lr0_hash; lr1_hash}

(* LR0部分が同じ2つのClosureItemから先読部分をマージ *)
let merge db ci1 ci2 =
  if not (isSameLR0 ci1 ci2) then failwith "null" else (* LR0部分が違う *)
  if isSameLR1 ci1 ci2 then ci1 else (* 完全一致 *)
  let (a1,a2)        = (ci1.lookaheads, ci2.lookaheads) in
  let (len1,len2,id) = (Array.length a1, Array.length a2, getTokenId db) in
  let rec merge i1 i2 =
    if i1 = len1 && i2 = len2  then []                           else (* 1,2とも終了      *)
    if i1 = len1               then a2.(i2)::merge  i1    (i2+1) else (* 1終了時は2を追加 *)
    if i2 = len2               then a1.(i1)::merge (i1+1)  i2    else (* 2終了時は1を追加 *)
    if a1.(i1) = a2.(i2)       then a1.(i1)::merge (i1+1) (i2+1) else (* 1と2が同じ *)
    if id a1.(i1) < id a2.(i2) then a1.(i1)::merge (i1+1)  i2    else (* idが小さい方を選択 *)
                                    a2.(i2)::merge  i1    (i2+1)  (* 配列はソート済みが前提 *)
  in
  let lookaheads = merge 0 0 in
  genClosureItem db ci1.rule_id ci2.dot_index (Array.of_list lookaheads)

(* LR0部分を維持しながらLR1先読み記号ごとにClosureItemを分割し、先読み記号の数が1のClosureItemの集合を生成 *)
let separateByLookAheads db ci =
  (* lookaheadsの要素数が1未満の状況は存在しない *)
  ci.lookaheads |> Array.map (fun t ->
    genClosureItem db ci.rule_id ci.dot_index [| t |]
  )
