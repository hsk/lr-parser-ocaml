open Language
open Token
open Utils

(* 終端/非終端記号の判別を行う *)
type symbolDiscriminator = {terminal_symbols: S.t; nonterminal_symbols: S.t}

let genSymbolDiscriminator(grammar: grammarDefinition): symbolDiscriminator =
  let nonterminal_symbols = grammar |>(* 構文規則の左辺に現れる記号は非終端記号 *)
    List.map(fun (ltoken,_,_)->ltoken) |> S.of_list
  in
  let terminal_symbols = List.fold_left(fun set (_,pattern,_) ->
    (* 非終端記号でない(=左辺値に現れない)場合、終端記号である *)
    pattern |>
      List.filter (fun symbol->not(S.mem symbol nonterminal_symbols)) |>
      (fun ptn -> List.fold_right S.add ptn set)
  ) S.empty grammar in
  {terminal_symbols; nonterminal_symbols}

(* 与えられた記号が終端記号かどうかを調べる *)
let isTerminalSymbol(d, symbol) = S.mem symbol d.terminal_symbols

(* 与えられた記号が非終端記号かどうかを調べる *)
let isNonterminalSymbol(d, symbol) = S.mem symbol d.nonterminal_symbols

