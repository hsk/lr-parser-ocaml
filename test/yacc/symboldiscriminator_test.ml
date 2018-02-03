open OUnit
open Utils
open Symboldiscriminator
open Sample_language
open Token
open Language

let test () =
  let symbols = genSymbolDiscriminator(test_sample_grammar) in
  "SymbolDiscriminator test" >::: [
    "test sample language" >::: [
      "S is Nonterminal" >:: begin fun () ->
        assert(isNonterminalSymbol(symbols, "S"));
        assert(not(isTerminalSymbol(symbols, "S")))
      end;
      "E is Nonterminal" >:: begin fun () ->
        assert(isNonterminalSymbol(symbols, "E"));
        assert(not(isTerminalSymbol(symbols, "E")))
      end;
      "LIST is Nonterminal" >:: begin fun () ->
        assert(isNonterminalSymbol(symbols, "LIST"));
        assert(not(isTerminalSymbol(symbols, "LIST")))
      end;
      "T is Nonterminal" >:: begin fun () ->
        assert(isNonterminalSymbol(symbols, "T"));
        assert(not(isTerminalSymbol(symbols, "T")))
      end;
      "HOGE is Nonterminal" >:: begin fun () ->
        assert(isNonterminalSymbol(symbols, "HOGE"));
        assert(not(isTerminalSymbol(symbols, "HOGE")))
      end;
      "SEMICOLON is Terminal" >:: begin fun () ->
        assert(not(isNonterminalSymbol(symbols, "SEMICOLON")));
        assert(isTerminalSymbol(symbols, "SEMICOLON"))
      end;
      "SEPARATE is Terminal" >:: begin fun () ->
        assert(not(isNonterminalSymbol(symbols, "SEPARATE")));
        assert(isTerminalSymbol(symbols, "SEPARATE"))
      end;
      "ATOM is Terminal" >:: begin fun () ->
        assert(not(isNonterminalSymbol(symbols, "ATOM")));
        assert(isTerminalSymbol(symbols, "ATOM"))
      end;
      "ID is Terminal" >:: begin fun () ->
        assert(not(isNonterminalSymbol(symbols, "ID")));
        assert(isTerminalSymbol(symbols, "ID"))
      end;
      "INVALID (not appear in grammar) is neither Nonterminal nor Terminal" >:: begin fun () ->
        assert(not(isNonterminalSymbol(symbols, "INVALID")));
        assert(not(isTerminalSymbol(symbols, "INVALID")))
      end;
      "Check nonterminal symbols set" >:: begin fun () ->
        let nt = symbols.nonterminal_symbols in
        ["S"; "E"; "LIST"; "T"; "HOGE"] |> List.iter (fun symbol ->
          assert(S.mem symbol nt)
        );
        assert_equal (S.cardinal nt) 5
      end;
      "Check terminal symbols set" >:: begin fun () ->
        let t = symbols.terminal_symbols in
        ["SEMICOLON"; "SEPARATE"; "ATOM"; "ID"] |> List.iter (fun symbol ->
          assert(S.mem symbol t)
        );
        assert_equal (S.cardinal t) 4
      end;
    ];
    "test sample language" >::: [
      "Check nonterminal symbols set 2" >:: begin fun () ->
        let symbols = genSymbolDiscriminator(test_calc_grammar) in
        let nt = symbols.nonterminal_symbols in
        ["EXP"; "TERM"; "ATOM"] |> List.iter (fun symbol ->
          assert(S.mem symbol nt)
        );
        assert_equal (S.cardinal nt) 3
      end;
      "Check terminal symbols set 2" >:: begin fun () ->
        let symbols = genSymbolDiscriminator(test_calc_grammar) in
        let t = symbols.terminal_symbols in
        ["PLUS"; "ASTERISK"; "DIGITS"; "LPAREN"; "RPAREN"] |> List.iter (fun symbol ->
          assert(S.mem symbol t)
        );
        assert_equal (S.cardinal t) 5
      end;
    ];
    "test empty language" >::: [
      "Check nonterminal symbols set 3" >:: begin fun () ->
        let {grammar} = test_empty_language in
        let symbols = genSymbolDiscriminator(grammar) in
        let nt = symbols.nonterminal_symbols in
        assert(S.mem "S" nt);
        assert_equal (S.cardinal nt) 1
      end;
      "Check terminal symbols set 3" >:: begin fun () ->
        let {grammar} = test_empty_language in
        let symbols = genSymbolDiscriminator(grammar) in
        let t = symbols.terminal_symbols in
        assert_equal (S.cardinal t) 0
      end;
    ];
  ]
