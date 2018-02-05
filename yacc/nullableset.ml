open Language
open Token
open Utils

(* ある非終端記号から空列が導かれうるかどうかを判定する *)
type nullableSet = S.t

(* 空列になりうる記号の集合 nulls を導出 *)
let generateNulls grammar : nullableSet =
  (* 右辺の記号の数が0の規則を持つ記号は空列になる *)
  let nulls = grammar |>
    List.filter(fun (_,pattern,_)->List.length pattern=0) |>
    List.map(fun (ltoken,_,_)->ltoken) |>
    S.of_list
  in
  (* さらに、空になる文法しか呼び出さない文法要素を追加する *)
  (* 要素を追加したらもう一回調べ直す必要があるのでループ *)
  let rec loop nulls =
    let add_grammer = grammar |> List.filter(fun (ltoken,pattern,_)-> (* 追加するのは *)
      not (S.mem ltoken nulls) && (* nullsに含まれておらず *)
      (* 右辺がすべてnullのもの。つまり、nullにならない要素が含まれないもの *)
      not (List.exists (fun a-> not (S.mem a nulls)) pattern)
    ) in
    if add_grammer = [] then nulls else(* 加えるものがなくなったら終了 *)
    (* 加える文法要素があれば、文法名を取り出し、追加してループします *)
    loop (add_grammer|>(List.fold_left (fun nulls (ltoken,_,_) -> S.add ltoken nulls) nulls))
  in
  loop nulls

(* Token が Nullable かどうか *)
let isNullable nulls token : bool = S.mem token nulls
