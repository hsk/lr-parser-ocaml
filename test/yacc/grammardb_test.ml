open OUnit
open Grammardb
open Token
open Language

let test () =
  let db = genGrammarDB(Sample_language.language) in
  "GrammarDB test" >::: [
    "findRules test" >::: [
      "get rules of E" >:: begin fun () ->
        assert_equal (findRules db "E") [|
          1, ("E", ["LIST"; "SEMICOLON"], None);
          2, ("E", ["HOGE"], None);
        |]
      end;
      "get a rule of HOGE" >:: begin fun () ->
        assert_equal (findRules db "HOGE") [|
          7, ("HOGE", ["ID"], None)
        |]
      end;
    ];
    "getRuleById test" >::: [
      "rule of grammar 1 is: E -> LIST SEMICOLON" >:: begin fun () ->
        assert_equal (getRuleById db 1) ("E", ["LIST"; "SEMICOLON"], None)
      end;
      "rule of grammar -1 is: S' -> S" >:: begin fun () ->
        assert_equal (getRuleById db (-1)) ("S'", ["S"], None)
      end;
      "throw error by calling rule of grammar -2" >:: begin fun () ->
        assert_raises (Failure "grammar id out of range")
          (fun () -> getRuleById db (-2))
      end;
      "no error occurs in rule of grammar 7" >:: begin fun () ->
        getRuleById db 7 |> ignore
      end;
      "throw error by calling rule of grammar 8" >:: begin fun () ->
        assert_raises (Failure "grammar id out of range")
          (fun () -> getRuleById db 8)
      end;
    ];
  ]
