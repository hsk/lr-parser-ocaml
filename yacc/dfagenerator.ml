open Token
open Utils
open Closureitem
open Closureset
open Grammardb

type edge = int M.t 
type node = {closure: closureSet; edge: edge (* トークンからDFAのインデックスを示す *) }
type dfa = node list

let show_edge (edge:edge) =
  let s = edge |> M.bindings |> List.map(fun (t,i)-> Printf.sprintf "%s -> %d;" t i) |> String.concat "" in
  "[" ^ s ^ "]"

let show db dfa =
  dfa |> List.map(fun{closure;edge}->
    Printf.sprintf "{closure=\n%sedge=%s\n}\n"
      (Closureset.showi db closure) (show_edge edge)
  ) |> String.concat ""
let showi db dfa =
  dfa |> List.mapi(fun i {closure;edge}->
    Printf.sprintf "%d {closure=\n%sedge=%s\n}\n" i
      (Closureset.showi db closure) (show_edge edge)
  ) |> String.concat ""

(* .を進めた記号からアイテム集合へのマップを生成 *)
let generate_follow_dot_csmap db cs: closureSet M.t =
  cs.items |> (M.empty |> List.fold_left (fun map ci ->
    let (_,pattern,_) = getRuleById db ci.rule_id in
    if ci.dot_index = List.length pattern then map else (* .が末尾にある場合はスキップ *)
    let label = List.nth pattern ci.dot_index in
    map |> M.add_list label (genClosureItem db ci.rule_id (ci.dot_index + 1) ci.lookaheads)
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
  [| { closure = genClosureSet db [genClosureItem db (-1) 0 ["EOF"]]; edge = M.empty} |] |>
  (* 変更がなくなるまでループ *)
  let rec loop dfa =
    (* Printf.printf "DFA\n%s" (showi db (Array.to_list dfa)); *)
    match updateDFA db 0 (dfa, false) with
    | dfa,true -> loop dfa
    | dfa,_ -> Array.to_list dfa
  in loop
