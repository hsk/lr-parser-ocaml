open Token
open Grammardb

(* 単一のLRアイテムであり、`S -> A . B [$]` のようなアイテムの規則id・ドットの位置・先読み記号の集合の情報を持つ *)
(* [[GrammarDB]]から与えられるトークンIDをもとにして、LR(0)およびLR(1)アイテムとしてのハッシュ値を生成することができる *)
type closureItem = {
  grammardb: grammarDB; rule_id: int; dot_index: int; lookaheads: token array;
  lr0_hash: string; lr1_hash: string
}

(* ハッシュ文字列を生成する *)
let genHash((grammardb: grammarDB), (rule_id: int), (dot_index: int), (lookaheads: token array)):(string * string) =
  let lr0_hash = Printf.sprintf "%d,%d" rule_id dot_index in
  let la_hash = Array.fold_right(fun i ls -> string_of_int (getTokenId(grammardb, i))::ls) lookaheads [] in
  (lr0_hash, lr0_hash ^ "," ^ "[" ^ String.concat ", " la_hash ^ "]")

(* 先読み記号の配列を、[[GrammarDB]]によって割り振られるトークンid順にソートする *)
let sortLA((grammardb: grammarDB), (lookaheads: token array)):token array =
  let lookaheads = Array.copy lookaheads in
  Array.sort (fun t1 t2 ->
    getTokenId(grammardb, t1) - getTokenId(grammardb, t2)
  ) lookaheads;
  lookaheads

(* @param {GrammarDB} grammardb 使用する構文の情報
  * @param {number} _rule_id 構文のid
  * @param {number} _dot_index ドットの位置
  * @param {Array<Token>} _lookaheads 先読み記号の集合
  *)
let genClosureItem((grammardb: grammarDB), (rule_id: int), (dot_index: int), (lookaheads: token array)) : closureItem =
  (* 有効な値かどうか調べる *)
  if not (hasRuleId(grammardb, rule_id)) then failwith("invalid grammar id");
  if (dot_index < 0 || dot_index > List.length (let(_,pattern,_)=getRuleById(grammardb, rule_id) in pattern))
  then failwith("dot index out of range");
  if Array.length lookaheads = 0 then failwith("one or more lookahead symbols needed");
  let lookaheads = sortLA(grammardb, lookaheads) in
  let (lr0_hash,lr1_hash) = genHash(grammardb, rule_id, dot_index, lookaheads) in
  {grammardb; rule_id; dot_index; lookaheads; lr0_hash; lr1_hash}

let isSameLR0((s: closureItem), (c: closureItem)): bool = s.lr0_hash = c.lr0_hash
let isSameLR1((s: closureItem), (c: closureItem)): bool = s.lr1_hash = c.lr1_hash

(* LR0部分を維持しながらLR1先読み記号ごとにClosureItemを分割し、先読み記号の数が1のClosureItemの集合を生成する *)
let separateByLookAheads(s: closureItem): closureItem array =
  (* s.lookaheadsの要素数が1未満の状況は存在しない *)
  s.lookaheads |> Array.map (fun la ->
    genClosureItem(s.grammardb, s.rule_id, s.dot_index, [| la |])
  )

(* LR0部分が同じ2つのClosureItemについて、先読み部分を統合した新しいClosureItemを生成する *)
(* 異なるLR(0)アイテムであった場合、Noneを返す *)
let merge((s: closureItem), (c: closureItem)): closureItem option =
  if not(isSameLR0(s, c)) then None else (* LR0部分が違っている場合はnullを返す *)
  if isSameLR1(s, c) then Some s else (* LR1部分まで同じ場合は自身を返す *)
  (* 配列はソート済み *)
  (* 2つのLA配列をマージして新しい配列を生成する *)
  let rec loop i1 i2 =
    if not(i1 < Array.length s.lookaheads || i2 < Array.length c.lookaheads)
    then []
    else if i1 = Array.length s.lookaheads
    then c.lookaheads.(i2)::loop i1 (i2+1)
    else if i2 = Array.length c.lookaheads
    then s.lookaheads.(i1)::loop (i1+1) i2
    else if s.lookaheads.(i1) = c.lookaheads.(i2)
    then s.lookaheads.(i1)::loop (i1+1) (i2+1)
    else if getTokenId(s.grammardb, s.lookaheads.(i1)) < getTokenId(s.grammardb, c.lookaheads.(i2))
    then s.lookaheads.(i1)::loop (i1+1) i2
    else c.lookaheads.(i2)::loop i1 (i2+1)
  in
  let new_la = loop 0 0 in
  Some (genClosureItem(s.grammardb, s.rule_id, s.dot_index, Array.of_list new_la))
