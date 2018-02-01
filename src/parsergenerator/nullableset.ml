open Language
open Token

(* ある非終端記号から空列が導かれうるかどうかを判定する *)
type nullableSet = S.t

(* @param {GrammarDefinition} grammar 構文規則 *)
let generateNulls(grammar: grammarDefinition):nullableSet =
  (* 制約条件を導出するために、*)
  (* 空列になりうる記号の集合nullsを導出 *)
  let nulls = grammar |>
    List.filter(fun (_,pattern,_)->List.length pattern=0) |>
    List.map(fun (ltoken,_,_)->ltoken) |>
    S.of_list
  in
  (* 右辺の記号の数が0の規則を持つ記号は空列になりうる *)
  (* 変更が起きなくなるまでループする *)
  let rec loop nulls =
    match grammar |> List.filter(fun (ltoken,pattern,_)->
      not (S.mem ltoken nulls) && not (List.exists (fun a-> not (S.mem a nulls)) pattern)
    ) with
    | [] -> nulls
    | a ->
      loop (List.fold_right (fun (ltoken,_,_) nulls ->
        S.add ltoken nulls
      ) a nulls)
  in
  loop nulls

(* 与えられた[[Token]]がNullableかどうかを調べる *)
let isNullable((set:nullableSet), (token: token)):bool = S.mem token set
