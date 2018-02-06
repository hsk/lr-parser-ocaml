open Token
open Grammardb

(* `S -> A . B [$]` のような LRアイテム *)
type closureItem = {
  rule_id: int; dot_index: int; lookaheads: token list; (* 規則id・ドット位置・先読記号集合 *)
  lr0_hash: string; lr1_hash: string                     (* LR(0)、LR(1)アイテムのハッシュ値 *)
}

(* ハッシュ文字列を生成する *)
let genHash db rule_id dot_index lookaheads =
  let la_hash = lookaheads |> List.map(fun t -> string_of_int (getTokenId db t)) in
  let lr0_hash = Printf.sprintf "%d,%d" rule_id dot_index in
  let lr1_hash = Printf.sprintf "%s,[%s]" lr0_hash (String.concat "," la_hash) in
  (lr0_hash, lr1_hash)

let isSameLR0 ci1 ci2 = ci1.lr0_hash = ci2.lr0_hash
let isSameLR1 ci1 ci2 = ci1.lr1_hash = ci2.lr1_hash

(* 先読記号配列を、トークンid順にソート *)
let sortLA db lookaheads =
  List.sort (fun t1 t2 -> getTokenId db t1 - getTokenId db t2) lookaheads

let genClosureItem db rule_id dot_index lookaheads =
  if not (hasRuleId db rule_id) then failwith "invalid grammar id";
  if (dot_index < 0 || dot_index > List.length (let (_,pattern,_) = getRuleById db rule_id in pattern))
  then failwith "dot index out of range";
  if lookaheads = [] then failwith "one or more lookahead symbols needed";
  let lookaheads = sortLA db lookaheads in
  let (lr0_hash,lr1_hash) = genHash db rule_id dot_index lookaheads in
  {rule_id; dot_index; lookaheads; lr0_hash; lr1_hash}
