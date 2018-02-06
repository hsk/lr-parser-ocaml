open OUnit
open Closureitem
open Grammardb
open Token
open Language

let test () =
  let grammardb = genGrammarDB(Sample_language.language) in
  let ci = genClosureItem grammardb (-1) 0 ["EOF"] in
  "ClosureItem test" >::: [
    "{S' -> . S [$]}" >::: [
      "getter" >:: begin fun () ->
        assert(ci.rule_id = -1);
        assert(ci.dot_index = 0);
        assert_equal (ci.lookaheads) ["EOF"]
      end;
      "ClosureItem Hash" >:: begin fun () ->
        let id_eof = getTokenId grammardb "EOF" in
        assert(ci.lr0_hash = "-1,0");
        assert(ci.lr1_hash = "-1,0,["^string_of_int id_eof^"]")
      end;
      "ClosureItem equality" >::: [
        "compare itself" >:: begin fun () ->
          assert(isSameLR0 ci ci);
          assert(isSameLR1 ci ci)
        end;
        "same ClosureItem" >:: begin fun () ->
          let ci2 = genClosureItem grammardb (-1) 0 ["EOF"] in
          assert(isSameLR0 ci ci2);
          assert(isSameLR1 ci ci2)
        end;
        "not same ClosureItem" >:: begin fun () ->
          let ci2 = genClosureItem grammardb 0 0 ["EOF"] in
          assert (not(isSameLR0 ci ci2));
          assert (not(isSameLR1 ci ci2))
        end;
        "not same lookahead item" >:: begin fun () ->
          let ci2 = genClosureItem grammardb (-1) 0 ["ID"] in
          assert(isSameLR0 ci ci2);
          assert(not(isSameLR1 ci ci2))
        end;
      ];
      "invalid lookahead item" >:: begin fun () ->
        assert_raises (Failure "invalid token X")
          (fun () -> genClosureItem grammardb (-1) 0 ["X"])
      end;
    ];
    "invalid ClosureItem" >::: [
      "invalid grammar id" >:: begin fun () ->
        assert_raises (Failure "invalid grammar id")
          (fun () -> genClosureItem grammardb (-2) 0 ["EOF"])
      end;
      "invalid dot position" >:: begin fun () ->
        assert_raises (Failure "dot index out of range")
          (fun () -> genClosureItem grammardb (-1) (-1) ["EOF"])
      end;
    ];
  ]

