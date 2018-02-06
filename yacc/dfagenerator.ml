open Token
open Utils
open Closureitem
open Closureset
open Grammardb

type edge = int M.t
type node = {closure: closureSet; edge: edge}
type dfa = node list

(* .を進めた記号からアイテム集合へのマップを生成 *)
let generate_follow_dot_csmap db cs: closureSet M.t =
  cs.items |> (M.empty |> Array.fold_left (fun map ci ->
    let (_,pattern,_) = getRuleById db ci.rule_id in
    if ci.dot_index = List.length pattern then map else (* .が末尾にある場合はスキップ *)
    let label = List.nth pattern ci.dot_index in
    map |> M.add_array label (genClosureItem db ci.rule_id (ci.dot_index + 1) ci.lookaheads)
  )) |> M.map (genClosureSet db) (* ClosureItemの配列からClosureSetに変換 *)
  
let rec updateDFA db i (dfa, flg) =
  if i >= Array.length dfa then (dfa,flg) else updateDFA db (i+1) (
    (* .を進めた記号からアイテム集合へのマップを生成 *)
    let follow_dot_cs_map = generate_follow_dot_csmap db dfa.(i).closure in
    (* DFAノードを生成する *)
    follow_dot_cs_map |> ((dfa,flg) |> M.fold_left(fun (dfa,flg) (follow_label, follow_dot_cs) ->
      let (index,dfa,flg) = (* 既存のNodeのなかに同一のClosureSetを持つindexを検索 *)
        try (Array.findIndex(fun node -> Closureset.isSameLR1 follow_dot_cs node.closure) dfa,dfa,flg)
        with _ -> (* ない時はdfaを拡張する *)
          (Array.length dfa, Array.add dfa {closure=follow_dot_cs; edge=M.empty}, true)
      in
      if M.mem follow_label dfa.(i).edge then (dfa,flg) else begin (* 辺が含まれていないとき *)
        dfa.(i) <- {dfa.(i) with edge = M.add follow_label index dfa.(i).edge}; (* dfaに辺を追加 *)
        (dfa,true)
      end
    ))
  )

(* DFAの生成 *)
let generateLR1DFA db : dfa =
  [| { closure = genClosureSet db [|genClosureItem db (-1) 0 [|"EOF"|]|]; edge = M.empty} |] |>
  (* 変更がなくなるまでループ *)
  let rec loop dfa =
    match updateDFA db 0 (dfa, false) with
    | dfa,true -> loop dfa
    | dfa,_ -> Array.to_list dfa
  in loop
