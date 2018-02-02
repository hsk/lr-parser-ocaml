open Token
open Closureitem
open Grammardb
open Firstset
open Symboldiscriminator

(* 複数のLRアイテムを保持するアイテム集合 *)
type closureSet = {closureset: closureItem array; lr0_hash: string; lr1_hash: string}

(* ハッシュ文字列を生成 *)
let genHash items =
  let items = Array.to_list items in
  let lr0_hash = items |> List.map (fun i->i.Closureitem.lr0_hash) in
  let lr1_hash = items |> List.map (fun i->i.Closureitem.lr1_hash) in
  (String.concat "|" lr0_hash, String.concat "|" lr1_hash)

let isSameLR0(cs1, cs2) = cs1.lr0_hash = cs2.lr0_hash
let isSameLR1(cs1, cs2) = cs1.lr1_hash = cs2.lr1_hash

(* 保持するClosureItemは、常にLR(1)ハッシュでソート *)
let sort items =
  let items = Array.copy items in
  Array.sort (fun i1 i2 -> String.compare i1.Closureitem.lr1_hash i2.Closureitem.lr1_hash) items;
  items

(* クロージャー展開を行う *)
let expandClosure grammardb items =

  (* ClosureItemをlookaheadsごとに分解する *)
  let items = sort(Array.fold_left(fun items item ->
    Array.append items (separateByLookAheads grammardb item)
  ) [||] items) in
  (* 展開処理中はClosureItemのlookaheadsの要素数を常に1 *)

  let slice arr s e = Array.sub arr s (e - s) in

  (* 先読み記号を導出 *)
  let expand grammardb items item ts follow =
    (* item.lookaheadsは要素数1 *)
    let ts = Array.append (slice ts (item.dot_index + 1) (Array.length ts)) [|item.lookaheads.(0)|] in
    let ts = List.sort (fun t1 t2 ->
      getTokenId grammardb t1 - getTokenId grammardb t2
    ) (S.elements (getFromList(grammardb.first, Array.to_list ts))) in

    (* follow を左辺にもつ全ての規則を、先読み記号を付与して追加 *)
    findRules(grammardb, follow) |> Array.fold_left (fun items (id,_) ->
      List.fold_left (fun items t ->
        let new_item = genClosureItem grammardb id 0 [| t |] in
        if Array.exists(fun item -> Closureitem.isSameLR1 new_item item) items then items
        (* 重複がなければ新しいアイテムを追加する *)
        else Array.append items [| new_item |]
      ) items ts
    ) items
  in
  (* アイテム追加しながら変更がなくなるまで繰り返す *)
  let rec expandLoop grammardb i items =
    if i >= Array.length items then items else
    let item = items.(i) in
    let ts = getRuleById(grammardb, item.rule_id) |> (fun (_,ts,_) -> Array.of_list ts) in

    (* .が末尾にある *)
    if item.dot_index >= Array.length ts then expandLoop grammardb (i+1) items else
    let follow = ts.(item.dot_index) in
  
    (* .の次の記号が非終端記号以外 *)
    if not(isNonterminalSymbol(grammardb.symbols, follow)) then expandLoop grammardb (i+1) items else
  
    (* クロージャー展開を行う *)
    expandLoop grammardb (i+1) (expand grammardb items item ts follow)
  in
  let items = sort(expandLoop grammardb 0 items) in

  (* ClosureItemの先読み部分をマージする *)
  let (_,items,_) = Array.fold_left (fun (i,results,lookaheads) item ->
    let lookaheads = Array.append lookaheads [|item.lookaheads.(0)|] in
    if i < Array.length items - 1 && Closureitem.isSameLR0 item items.(i + 1) (* 次が同じか？ *)
    then (i+1, results, lookaheads) (* 続け、違う時は追加する *)
    else (i+1, Array.append results [|genClosureItem grammardb item.rule_id item.dot_index lookaheads|], [||])
    ) (0, [||], [||]) items in
  sort(items)

let genClosureSet grammardb items: closureSet =
  let items = expandClosure grammardb items in
  let (lr0_hash,lr1_hash) = genHash(items) in
  {closureset=items; lr0_hash; lr1_hash}

(* 保持しているLRアイテムの数 *)
let size(set: closureSet) = Array.length set.closureset

(* 保持している[[ClosureItem]]の配列を得る *)
let getArray(set: closureSet) = Array.copy set.closureset

(* LRアイテムが集合に含まれているかどうかを調べる *)

let includes(set, (item:closureItem)) =
  Array.exists(fun i -> Closureitem.isSameLR1 i item) set.closureset

(* LR(0)部分が同じ2つのClosureSetについて、先読み部分を統合した新しいClosureSetを生成 *)
let mergeLA(grammardb, (cs1: closureSet), (cs2: closureSet)): closureSet =
  if not(isSameLR0(cs1, cs2)) then failwith "null" else (* LR0部分が違う *)
  if isSameLR1(cs1, cs2) then cs1 else (* LR1部分まで同じ *)
  let a1, a2 = getArray(cs1), getArray(cs2) in
  let new_set = Array.mapi (fun i a1 -> merge(grammardb, a1, a2.(i))) a1 in
  genClosureSet grammardb new_set
