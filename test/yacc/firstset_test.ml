open OUnit
open Token
open Language
open Utils
open Firstset
open Symboldiscriminator
open Sample_language

let test () =
  let first = generateFirst(test_sample_grammar, genSymbolDiscriminator(test_sample_grammar)) in
  "FirstSet test" >::: [
    "valid one terminal and nonterminal symbol" >::: [
      "First(S) is {SEMICOLON, SEPARATE, ATOM, ID}" >:: begin fun () ->
        ["SEMICOLON"; "SEPARATE"; "ATOM"; "ID"] |> List.iter (fun symbol ->
          assert(S.mem symbol (get(first, "S")))
        );
        assert_equal (S.cardinal(get(first, "S"))) 4
      end;
      "First(E) is {SEMICOLON, SEPARATE, ATOM, ID}" >:: begin fun () ->
        ["SEMICOLON"; "SEPARATE"; "ATOM"; "ID"] |> List.iter (fun symbol ->
          assert(S.mem symbol (get(first, "E")))
        );
        assert_equal (S.cardinal(get(first, "E"))) 4
      end;
      "First([E]) is {SEMICOLON, SEPARATE, ATOM, ID}" >:: begin fun () ->
        ["SEMICOLON"; "SEPARATE"; "ATOM"; "ID"] |> List.iter (fun symbol ->
          assert(S.mem symbol (getFromList(first, ["E"])))
        );
        assert_equal (S.cardinal(getFromList(first, ["E"]))) 4
      end;
      "First(LIST) is {SEPARATE, ATOM}" >:: begin fun () ->
        ["SEPARATE"; "ATOM"] |> List.iter (fun symbol ->
          assert(S.mem symbol (get(first, "LIST")))
        );
        assert_equal (S.cardinal(get(first, "LIST"))) 2
      end;
      
      "First(T) is {ATOM}" >:: begin fun () ->
        assert(S.mem "ATOM" (get(first, "T")));
        assert_equal (S.cardinal(get(first, "T"))) 1
      end;
      "First(HOGE) is {ID}" >:: begin fun () ->
        assert(S.mem "ID" (get(first, "HOGE")));
        assert_equal (S.cardinal(get(first, "HOGE"))) 1
      end;
      "First(ID) is {ID}" >:: begin fun () ->
        assert(S.mem "ID" (get(first, "ID")));
        assert_equal (S.cardinal(get(first, "ID"))) 1
      end;
    ];
    "valid word (multiple terminal or nonterminal symbols)" >::: [
      "First(LIST ID) is {SEPARATE ATOM ID}" >:: begin fun () ->
        ["SEPARATE"; "ATOM"; "ID"] |> List.iter (fun symbol ->
          assert(S.mem symbol (getFromList(first, ["LIST"; "ID"])))
        );
        assert_equal (S.cardinal(getFromList(first, ["LIST"; "ID"]))) 3
      end;
      "First(HOGE HOGE) is {ID}" >:: begin fun () ->
        assert(S.mem "ID" (getFromList(first, ["HOGE"; "HOGE"])));
        assert_equal (S.cardinal(getFromList(first, ["HOGE"; "HOGE"]))) 1
      end;
    ];
    "invalid input (contains neither terminal nor nonterminal symbols)" >::: [
      "First(FOO) throws error" >:: begin fun () ->
        assert_raises (Failure "invalid token found: FOO")
          (fun () -> get(first, "FOO"))
      end;
      "First(INVALID) throws error" >:: begin fun () ->
        assert_raises (Failure "invalid token found: INVALID")
          (fun () -> get(first, "INVALID"))
      end;
      "First(INVALID INVALID) throws error" >:: begin fun () ->
        assert_raises (Failure "invalid token found: INVALID")
          (fun () -> getFromList(first, ["INVALID"; "INVALID"]))
      end;
      "First(INVALID S) throws error" >:: begin fun () ->
        assert_raises (Failure "invalid token found: INVALID")
          (fun () -> getFromList(first, ["INVALID"; "S"]))
      end;
      "First(S INVALID) throws error" >:: begin fun () ->
        assert_raises (Failure "invalid token found: INVALID")
          (fun () -> getFromList(first, ["S"; "INVALID"]))
      end;
    ];
  ]

let test2 () =
  let grammar = test_empty_language.grammar in
  let first = generateFirst(grammar, genSymbolDiscriminator(grammar)) in
  "FirstSet test(empty language)" >::: [
    "First(S) is {}" >:: begin fun () ->
      assert_equal (S.cardinal(get(first, "S"))) 0
    end;
  ]
