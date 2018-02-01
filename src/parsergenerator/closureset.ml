open Token
open Closureitem
open Grammardb
open Firstset
open Symboldiscriminator

(* 複数のLRアイテムを保持するアイテム集合であり、インスタンス生成時に自身をクロージャー展開する
 * [[GrammarDB]]から与えられるトークンIDをもとにして、LR(0)およびLR(1)アイテム集合としてのハッシュ値を生成することができる
 *)
type closureSet = {grammardb: grammarDB; closureset: closureItem array; lr0_hash: string; lr1_hash: string}

(* 自身が保持する複数の[[ClosureItem]]は、常にLR(1)ハッシュによってソートされた状態に保たれているようにする *)
let sort(closureset: closureItem array):closureItem array =
  let closureset = Array.copy closureset in
  Array.sort (fun i1 i2 -> String.compare i1.Closureitem.lr1_hash i2.Closureitem.lr1_hash) closureset;
  closureset

(* ハッシュ文字列を生成する *)
let updateHash(closureset: closureItem array):(string * string) =
  let closureset = Array.to_list closureset in
  let lr0_hash = closureset |> List.map (fun i->i.Closureitem.lr0_hash) in
  let lr1_hash = closureset |> List.map (fun i->i.Closureitem.lr1_hash) in
  (String.concat "|" lr0_hash, String.concat "|" lr1_hash)

(* クロージャー展開を行う *)
let expandClosure((grammardb: grammarDB), (cset:closureItem array)): closureItem array =
  (* 展開処理中はClosureItemのlookaheadsの要素数を常に1に保つこととする *)
  (* 初期化 *)
  (* ClosureItemをlookaheadsごとに分解する *)
  let closureset = Array.fold_left(fun set ci ->
    Array.append set (separateByLookAheads(ci))
  ) [||] cset in
  let closureset = sort(closureset) in
  (* 変更がなくなるまで繰り返す *)
  let rec loop index closureset =
    if not(index < Array.length closureset) then closureset else
    let ci = closureset.(index) in
    let (_,pattern,_) = getRuleById(grammardb, ci.rule_id) in
    let pattern = Array.of_list pattern in
    if ci.dot_index = Array.length pattern then loop (index+1) closureset else (* .が末尾にある場合はスキップ *)
    (* .が末尾にある場合はスキップ *)
    let follow = pattern.(ci.dot_index) in
    (* .の次の記号が非終端記号でないならばスキップ *)
    if not(isNonterminalSymbol(grammardb.symbols, follow)) then loop (index+1) closureset else
    (* クロージャー展開を行う *)
    (* 先読み記号を導出 *)
    (* ci.lookaheadsは要素数1のため、0番目のインデックスのみを参照すればよい *)
    let slice arr s e = Array.sub arr s (e - s) in
    let ptn = Array.append (slice pattern (ci.dot_index + 1) (Array.length pattern)) [|ci.lookaheads.(0)|] in
    let lookaheads = S.elements (getFromList(grammardb.first, Array.to_list ptn)) in
    let lookaheads = List.sort (fun t1 t2 ->
      getTokenId(grammardb, t1) - getTokenId(grammardb, t2)
    ) lookaheads in
    (* symbolを左辺にもつ全ての規則を、先読み記号を付与して追加 *)
    let rules = findRules(grammardb, follow) in
    let cs = Array.fold_left (fun cs (id,_) ->
      List.fold_left (fun cs la ->
        (* 重複がなければ新しいアイテムを追加する *)
        let new_ci = genClosureItem(grammardb, id, 0, [| la |]) in
        let flg_duplicated =
          Array.exists(fun existing_item -> Closureitem.isSameLR1(new_ci, existing_item)) closureset in
        if not flg_duplicated then Array.append cs [| new_ci |] else cs
      ) cs lookaheads
    ) (Array.copy closureset) rules in
    loop (index+1) cs
  in
  let closureset = loop 0 closureset in
  (* ClosureItemの先読み部分をマージする *)
  let tmp = sort(closureset) in
  let rec loop i closureset1 lookaheads =
    if i >= Array.length tmp then closureset1 else
    let lookaheads = Array.append lookaheads [|tmp.(i).lookaheads.(0)|] in
    if i = Array.length tmp - 1 || not (Closureitem.isSameLR0(tmp.(i), tmp.(i + 1))) then
      loop (i+1) (Array.append closureset1 [|genClosureItem(grammardb, tmp.(i).rule_id, tmp.(i).dot_index, lookaheads)|]) [||]
    else loop (i+1) closureset1 lookaheads
  in
  loop 0 [||] [||]

let genClosureSet((grammardb: grammarDB), (closureset: closureItem array)): closureSet =
  let closureset = sort(expandClosure(grammardb, closureset)) in
  let (lr0_hash,lr1_hash) = updateHash(closureset) in
  {grammardb; closureset; lr0_hash; lr1_hash}

(* 保持しているLRアイテムの数 *)
let size(set: closureSet) = Array.length set.closureset

(* 保持している[[ClosureItem]]の配列を得る *)
let getArray(set: closureSet): closureItem array = Array.copy set.closureset

(* 保持している[[ClosureItem]]の配列を得る
 * 得られた配列に変更が加えられないと保証される場合に用いる *)
let getArray_prevend(set: closureSet): closureItem array = set.closureset

(* LRアイテムが集合に含まれているかどうかを調べる *)
let includes((set: closureSet), (item: closureItem)): bool =
  (* 二分探索を用いて高速に探索する *)
  let rec loop min max =
    if not(min <= max) then false else
    let mid = min + ((max - min) / 2) in
    if item.lr1_hash < set.closureset.(mid).lr1_hash then loop min (mid - 1) else
    if item.lr1_hash > set.closureset.(mid).lr1_hash then loop (mid + 1) max else
    true (* itemとclosureset[mid]が等しい *)
  in
  loop 0 ((Array.length set.closureset) - 1)

let isSameLR0((set: closureSet), (cs: closureSet)): bool = set.lr0_hash = cs.lr0_hash
let isSameLR1((set: closureSet), (cs: closureSet)): bool = set.lr1_hash = cs.lr1_hash

(* LR(0)部分が同じ2つのClosureSetについて、先読み部分を統合した新しいClosureSetを生成する
 * 異なるLR(0)アイテム集合であった場合、nullを返す
 * @param {ClosureSet} cs マージ対象のアイテム集合
 * @returns {ClosureSet | null} 先読み部分がマージされた新しいアイテム集合 *)
let mergeLA((set: closureSet), (cs: closureSet)): closureSet =
  (* LR0部分が違っている場合はnullを返す *)
  if not(isSameLR0(set, cs)) then failwith "null" else
  (* LR1部分まで同じ場合は自身を返す *)
  if (isSameLR1(set, cs)) then set else
  let a1 = getArray(set) in
  let a2 = getArray(cs) in
  (* 2つの配列においてLR部分は順序を含めて等しい *)
  let new_set = ref [] in
  for i = 0 to Array.length a1 - 1 do
    match merge(a1.(i), a2.(i)) with
    | None -> ()
    | Some new_item -> new_set := new_item::!new_set
  done;
  (genClosureSet(set.grammardb, Array.of_list (List.rev !new_set)))
