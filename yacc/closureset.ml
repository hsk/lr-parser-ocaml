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

(* クロージャー展開を行う *)
let expandClosure db cis =
  (* ClosureItemをlookaheadsごとに分解する *)
  let cis = sort(Array.fold_left(fun cis ci ->
    Array.append cis (separateByLookAheads db ci)
  ) [||] cis) in
  (* 展開処理中はClosureItemのlookaheadsの要素数を常に1 *)

  let slice arr s e = Array.sub arr s (e - s) in

  (* 先読み記号を導出 *)
  let expand db cis ci ts follow =
    (* ci.lookaheadsは要素数1 *)
    let ts = Array.append (slice ts (ci.dot_index + 1) (Array.length ts)) [|ci.lookaheads.(0)|] in
    let ts = List.sort (fun t1 t2 ->
      getTokenId db t1 - getTokenId db t2
    ) (S.elements (getFromList db.first (Array.to_list ts))) in

    (* follow を左辺にもつ全ての規則を、先読み記号を付与して追加 *)
    findRules db follow |> Array.fold_left (fun cis (id,_) ->
      List.fold_left (fun cis t ->
        let new_ci = genClosureItem db id 0 [| t |] in
        if Array.exists(fun ci -> Closureitem.isSameLR1 new_ci ci) cis then cis
        (* 重複がなければ新しいアイテムを追加する *)
        else Array.append cis [| new_ci |]
      ) cis ts
    ) cis
  in
  (* アイテム追加しながら変更がなくなるまで繰り返す *)
  let rec expandLoop db i cis =
    if i >= Array.length cis then cis else
    let ci = cis.(i) in
    let ts = getRuleById db ci.rule_id |> (fun (_,ts,_) -> Array.of_list ts) in

    (* .が末尾にある *)
    if ci.dot_index >= Array.length ts then expandLoop db (i+1) cis else
    let follow = ts.(ci.dot_index) in
  
    (* .の次の記号が非終端記号以外 *)
    if not (isNonterminalSymbol db.symbols follow) then expandLoop db (i+1) cis else
  
    (* クロージャー展開を行う *)
    expandLoop db (i+1) (expand db cis ci ts follow)
  in
  let cis = sort(expandLoop db 0 cis) in

  (* ClosureItemの先読み部分をマージする *)
  let (_,cis,_) = Array.fold_left (fun (i,results,lookaheads) ci ->
    let lookaheads = Array.append lookaheads [|ci.lookaheads.(0)|] in
    if i < Array.length cis - 1 && Closureitem.isSameLR0 ci cis.(i + 1) (* 次が同じか？ *)
    then (i+1, results, lookaheads) (* 続け、違う時は追加する *)
    else (i+1, Array.append results [|genClosureItem db ci.rule_id ci.dot_index lookaheads|], [||])
    ) (0, [||], [||]) cis in
  sort(cis)

let genClosureSet db cis: closureSet =
  let cis = expandClosure db cis in
  let (lr0_hash,lr1_hash) = genHash cis in
  {items=cis; lr0_hash; lr1_hash}

(* 保持しているLRアイテムの数 *)
let size cs = Array.length cs.items

(* LRアイテムが集合に含まれているかどうかを調べる *)

let includes(cs, ci) = Array.exists(fun i -> Closureitem.isSameLR1 i ci) cs.items

(* LR(0)部分が同じ2つのClosureSetについて、先読み部分を統合した新しいClosureSetを生成 *)
let mergeLA(db, cs1, cs2): closureSet =
  if not (isSameLR0 cs1 cs2) then failwith "null" else (* LR0部分が違う *)
  if isSameLR1 cs1 cs2 then cs1 else (* LR1部分まで同じ *)
  let a1, a2 = cs1.items, cs2.items in
  let new_set = Array.mapi (fun i a1 -> merge db a1 a2.(i)) a1 in
  genClosureSet db new_set
