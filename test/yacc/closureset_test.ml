open OUnit
open Grammardb
open Sample_language
open Closureitem
open Token
open Closureset

let test () =
  let grammardb = genGrammarDB(test_sample_language) in
  let cs = genClosureSet grammardb [| genClosureItem grammardb (-1) 0 [|"EOF"|] |] in
  (*
  S' -> . S [$]
  S -> . E [$]
  E -> . LIST SEMICOLON [$]
  E -> . HOGE [$]
  LIST -> . T [SEMICOLON SEPARATE]
  LIST > . LIST SEPARATE T [SEMICOLON SEPARATE]
  T -> . ATOM [SEMICOLON SEPARATE]
  T -> . [SEMICOLON SEPARATE]
  HOGE -> . ID [$]
  *)
  let expanded = [| 
    genClosureItem grammardb (-1) 0 [|"EOF"|];
    genClosureItem grammardb 0 0 [|"EOF"|];
    genClosureItem grammardb 1 0 [|"EOF"|];
    genClosureItem grammardb 2 0 [|"EOF"|];
    genClosureItem grammardb 3 0 [| "SEMICOLON"; "SEPARATE" |];
    genClosureItem grammardb 4 0 [| "SEPARATE"; "SEMICOLON" |]; (* test changing lookaheads order *)
    genClosureItem grammardb 5 0 [| "SEMICOLON"; "SEPARATE" |];
    genClosureItem grammardb 6 0 [| "SEMICOLON"; "SEPARATE" |];
    genClosureItem grammardb 7 0 [|"EOF"|];
  |] in
  let expanded_shuffled = [| 
    genClosureItem grammardb 5 0 [| "SEMICOLON"; "SEPARATE" |];
    genClosureItem grammardb 2 0 [|"EOF"|];
    genClosureItem grammardb 1 0 [|"EOF"|];
    genClosureItem grammardb 0 0 [|"EOF"|];
    genClosureItem grammardb 4 0 [| "SEPARATE"; "SEMICOLON" |];
    genClosureItem grammardb 7 0 [|"EOF"|];
    genClosureItem grammardb (-1) 0 [|"EOF"|];
    genClosureItem grammardb 3 0 [| "SEMICOLON"; "SEPARATE" |];
    genClosureItem grammardb 6 0 [| "SEPARATE"; "SEMICOLON" |];
  |] in

  "ClosureSet test" >::: [
    "Closure{S' -> . S [$]}" >::: [
      "ClosureSet size" >:: begin fun () ->
        assert(Closureset.size(cs) = 9)
      end;
      "ClosureSet array" >:: begin fun () ->
        assert(Closureset.getArray(cs) = expanded)
      end;
      "ClosureSet equality" >::: [
        "compare itself" >:: begin fun () ->
          assert(Closureset.isSameLR0(cs, cs));
          assert(Closureset.isSameLR1(cs, cs))
        end;
        "compare closureset that is given expanded items to constructor" >:: begin fun () ->
          assert(Closureset.isSameLR0(cs, genClosureSet grammardb expanded_shuffled));
          assert(Closureset.isSameLR1(cs, genClosureSet grammardb expanded_shuffled))
        end;
      ];
      "ClosureSet#include" >:: begin fun () ->
        expanded |> Array.iter (fun ci -> assert(Closureset.includes(cs,ci)))
      end;
      "ClosureSet#include invalid inputs" >:: begin fun () ->
        Closureset.includes(cs,genClosureItem grammardb 0 1 [|"EOF"|]) |> ignore;
        assert_raises (Failure "dot index out of range") (fun () ->
          Closureset.includes(cs, genClosureItem grammardb 0 2 [|"EOF"|]));
        assert_raises (Failure "dot index out of range") (fun () ->
          Closureset.includes(cs, genClosureItem grammardb 0 (-1) [|"EOF"|]));
        assert_raises (Failure "invalid grammar id") (fun () ->
          Closureset.includes(cs, genClosureItem grammardb (-2) 0 [|"EOF"|]));
        assert_raises (Failure "invalid grammar id") (fun () ->
          Closureset.includes(cs, genClosureItem grammardb (-8) 0 [|"EOF"|]));
      end;
      "invalid ClosureSet" >::: [
        "invalid grammar id" >:: begin fun () ->
          assert_raises (Failure "invalid grammar id") (fun () ->
            genClosureSet grammardb [| genClosureItem grammardb (-2) 0 [|"EOF"|] |])
        end;
        "invalid dot position" >:: begin fun () ->
          assert_raises (Failure "dot index out of range") (fun () ->
            genClosureSet grammardb [| genClosureItem grammardb 0 (-1) [|"EOF"|] |])
        end;
      ];
    ];
  ]

let test2 () =
  let grammardb = genGrammarDB(test_empty_language) in
  let cs = genClosureSet grammardb [| genClosureItem grammardb (-1) 0 [|"EOF"|] |] in
  let expanded = [| 
    genClosureItem grammardb (-1) 0 [|"EOF"|];
    genClosureItem grammardb 0 0 [|"EOF"|];
  |] in
  "ClosureSet test2" >::: [
    "empty grammar" >::: [
      "ClosureSet size" >:: begin fun () ->
        assert(Closureset.size(cs) = 2)
      end;
      "ClosureSet array" >:: begin fun () ->
        assert(Closureset.getArray(cs) = expanded)
      end;
      "ClosureSet#include" >:: begin fun () ->
        expanded |> Array.iter (fun ci -> assert(Closureset.includes(cs,ci)))
      end;
    ];
  ]
