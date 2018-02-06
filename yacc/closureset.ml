open Token
open Utils
open Closureitem
open Grammardb
open Firstset
open Symboldiscriminator

(* 複数のLRアイテムを保持するアイテム集合 *)
type closureSet = {items: closureItem array; lr0_hash: string; lr1_hash: string}

(* ハッシュ文字列を生成 *)
let genHash cis =
  let cis = Array.to_list cis in
  let lr0_hash = cis |> List.map (fun i->i.Closureitem.lr0_hash) in
  let lr1_hash = cis |> List.map (fun i->i.Closureitem.lr1_hash) in
  (String.concat "|" lr0_hash, String.concat "|" lr1_hash)

let isSameLR0 cs1 cs2 = cs1.lr0_hash = cs2.lr0_hash
let isSameLR1 cs1 cs2 = cs1.lr1_hash = cs2.lr1_hash

(* 保持するClosureItemは、常にLR(1)ハッシュでソート *)
let sort cis =
  let cis = Array.copy cis in
  Array.sort (fun i1 i2 -> String.compare i1.Closureitem.lr1_hash i2.Closureitem.lr1_hash) cis;
  cis

let flat_items db (cis:closureItem array) =
  let separete (ci:closureItem):closureItem list = (* ClosureItemのlookaheadsを1つに分解 *)
    ci.lookaheads |> List.map (fun t -> genClosureItem db ci.rule_id ci.dot_index [ t ])
  in
  cis|>Array.to_list|>List.map separete|>List.concat|>Array.of_list

(* クロージャー展開 *)
let expand_closure db cis ci symbols follow_dot_symbol =
  let symbols = Array.add (Array.slice symbols (ci.dot_index + 1) (Array.length symbols)) (List.nth ci.lookaheads 0) in
  let symbols = symbols |> Array.to_list |> Firstset.getFromList db.first |> S.elements in
  let symbols = symbols |> List.sort (fun t1 t2 -> getTokenId db t1 - getTokenId db t2) in
  (* follow_dot_symbol を左辺にもつ全ての規則を、先読み記号を付与して追加 *)
  findRules db follow_dot_symbol |>(cis|>Array.fold_left (fun cis (id,_) ->
    symbols|>(cis|>List.fold_left (fun cis symbol ->
      let new_ci = genClosureItem db id 0 [ symbol ] in
      if Array.exists(fun ci -> Closureitem.isSameLR1 new_ci ci) cis then cis
      (* 重複がなければ新しいアイテムを追加する *)
      else Array.add cis new_ci
    ))
  ))

(* クロージャー展開ループ *)
let rec expand_closure_loop db i cis =
  (* 配列を拡張しながら配列がなくなるまでループ *)
  if i >= Array.length cis then cis else expand_closure_loop db (i+1) (
    let ci = cis.(i) in
    let symbols = getRuleById db ci.rule_id |> (fun (_,symbols,_) -> Array.of_list symbols) in
    if ci.dot_index >= Array.length symbols then cis else (* .が末尾にある *)
    let follow_dot_symbol = symbols.(ci.dot_index) in
    if isNonterminalSymbol db.symbols follow_dot_symbol then
      expand_closure db cis ci symbols follow_dot_symbol (* .の次の記号が非終端記号ならばクロージャー展開を行う *)
    else cis
  )

(* ClosureItemの先読み部分をマージする *)
let merge db cis =
  let (_,cis,_) = cis |> Array.fold_left (fun (i,results,lookaheads) ci ->
    let lookaheads = lookaheads @ ci.lookaheads in
    if i < Array.length cis - 1 && Closureitem.isSameLR0 ci cis.(i + 1) (* 次が同じか？ *)
    then (i+1, results, lookaheads)
    else (i+1, Array.add results (genClosureItem db ci.rule_id ci.dot_index lookaheads), [])
  ) (0, [||], []) in
  cis

let genClosureSet db cis: closureSet =
  let cis = flat_items db cis |> sort in (* アイテム配列全体を分割してフラットにする *)
  let cis = expand_closure_loop db 0 cis |> sort in (* クロージャ展開をアイテム配列を拡張しながら行う *)
  let cis = merge db cis |> sort in (* マージする *)
  let (lr0_hash,lr1_hash) = genHash cis in (* ハッシュを生成する *)
  {items=cis; lr0_hash; lr1_hash}

(* LRアイテムが集合に含まれているかどうかを調べる *)
let includes(cs, ci) = Array.exists(fun i -> Closureitem.isSameLR1 i ci) cs.items
