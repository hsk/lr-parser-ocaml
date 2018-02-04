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
  let nulls = generateNulls grammar in
  (* Firstを導出 *)
  (* 初期化 *)
  (* FIRST($) = {$} だけ手動で追加 *)
  let first_result = M.singleton "EOF" (S.singleton "EOF") in
  (* 終端記号Xに対してFirst(X)=X *)
  let first_result = List.fold_left (fun first_result value ->
    M.add value (S.singleton value) first_result
  ) first_result (S.elements symbols.terminal_symbols) in
  (* 非終端記号はFirst(Y)=∅で初期化 *)
  let first_result = List.fold_left (fun first_result value ->
    M.add value S.empty first_result
  ) first_result (S.elements symbols.nonterminal_symbols) in

  (* 包含についての制約を生成 *)
  let constraints = List.fold_left (fun constraints rule ->
    let (sup,pattern,_) = rule in
    (* 右辺の左から順に、non-nullableな記号が現れるまで制約に追加 *)
    (* 最初のnon-nullableな記号は制約に含める *)
    let rec loop constraints = function
      | [] -> constraints
      | sub::pattern -> 
        let constraints = if sup <> sub then (sup, sub)::constraints else constraints in
        if not (isNullable nulls sub) then constraints else loop constraints pattern
    in
    loop constraints pattern
  ) [] grammar in
  let constraints = List.rev constraints in

  (* 制約解消 *)
  let rec loop (first_result:S.t M.t) =
    let (flg,first_result) = List.fold_left(fun (flg, first_result) (sup,sub) ->
        let superset: S.t = M.find sup first_result in
        let subset: S.t = M.find sub first_result in
        let set = S.union subset superset in (* subset内の要素がsupersetに含まれていない *)
        if S.equal superset set then (flg,first_result)
        else (true, M.add sup set first_result) (* First集合を更新 *)
    ) (false,first_result) constraints in
    if flg then loop first_result else first_result
  in
  {first_map = loop first_result; nulls}


(* 記号または記号列を与えて、その記号から最初に導かれうる非終端記号の集合を返す *)
let get (set:firstSet) token: S.t =
  (* 単一の記号の場合 *)
  if not(M.mem token set.first_map) then failwith("invalid token found: " ^ token);
  M.find token set.first_map

let getFromList (set:firstSet) tokens: S.t =
  (* 記号列の場合 *)
  let (_,result) = List.fold_left (fun (endflg,result) token ->
    (* 不正な記号を発見 *)
    if not (M.mem token set.first_map) then failwith("invalid token found: " ^ token);
    if endflg then (endflg, result) else
    (* トークン列の先頭から順にFirst集合を取得 *)
    let result = S.union result (M.find token set.first_map) in (* 追加 *)
    let endflg = not (isNullable set.nulls token) in (* 現在のトークン ∉ Nulls ならばここでストップ *)
    (endflg, result)
  ) (false,S.empty) tokens in
  result
