open Language
open Token
open Utils
open Nullableset
open Symboldiscriminator

(* First集合 *)
type firstSet = {first_map: S.t M.t; nulls: nullableSet}

type cons = token * token

(* First集合を生成する *)
(* symbols 終端/非終端記号の判別に用いる分類器 *)
let generateFirst grammar (symbols: symbolDiscriminator):firstSet =
  let nulls = generateNulls grammar in (* null集合を生成 *)
  (* 初期化 *)
  (* EOF は EOFだけ追加 *)
  let first_map = M.singleton "EOF" (S.singleton "EOF") in
  (* 終端記号 は自分そのものを追加 *)
  let first_map = List.fold_left (fun first_map value ->
    M.add value (S.singleton value) first_map
  ) first_map (S.elements symbols.terminal_symbols) in
  (* 非終端記号は空を追加 *)
  let first_map = List.fold_left (fun first_map value ->
    M.add value S.empty first_map
  ) first_map (S.elements symbols.nonterminal_symbols) in

  (* 右辺のnon-nullableな記号までを制約として収集 *)
  let constraints = grammar |> (List.fold_left (fun constraints (sup,pattern,_) ->
    let rec loop constraints = function
      | [] -> constraints
      | sub::pattern ->
        (* 自分の文法名以外を制約に含め *)
        let constraints = if sup = sub then constraints else (sup, sub)::constraints in
        (* nullable なら続ける *)
        if isNullable nulls sub then loop constraints pattern else constraints
    in
    loop constraints pattern
  ) []) in
  let constraints = List.rev constraints in

  (* 制約解消 *)
  let rec loop (first_map:S.t M.t) =
    (* 制約でループしてfirst集合を更新 *)
    let (changed,first_map) = constraints |> List.fold_left(fun (changed, first_map) (sup,sub) ->
        let old_set = M.find sup first_map in
        let new_set = S.union old_set (M.find sub first_map) in (* 制約の集合を追加 *)
        if S.equal old_set new_set then (changed, first_map) (* 変化なし *)
        else (true, M.add sup new_set first_map) (* 変化有りなので更新 *)
    ) (false,first_map) in
    if changed then loop first_map else first_map (* 変更あったら繰り返す *)
  in
  {first_map = loop first_map; nulls}


(* 記号または記号列を与えて、その記号から最初に導かれうる非終端記号の集合を返す *)
let get (set:firstSet) token: S.t =
  try M.find token set.first_map with _ -> failwith("invalid token found: " ^ token)

let getFromList (set:firstSet) tokens: S.t =
  (* 記号列の場合 *)
  let (_,result) = List.fold_left (fun (stop,result) token ->
    (* 不正な記号を発見 *)
    if not (M.mem token set.first_map) then failwith("invalid token found: " ^ token);
    if stop then (stop, result) else
    (* トークン列の先頭から順にFirst集合を取得 *)
    let result = S.union result (M.find token set.first_map) in (* 追加 *)
    let stop = not (isNullable set.nulls token) in (* 現在のトークン ∉ Nulls ならばここでストップ *)
    (stop, result)
  ) (false, S.empty) tokens in
  result
