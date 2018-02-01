open OUnit
open Lexer
open Broken_language
open Parser
open Language
open Callback
open Parsergenerator

let test () =
  let pg = genParserGenerator(test_broken_language) in
  let parser = getParser(pg) in
  "Calculator test with broken language" >::: [
    "test" >:: begin fun () ->
      assert_equal "a" "a"
    end;
    (* TODO: パーサが壊れていることを(コンソール出力以外で)知る方法 *)
    "parsing table is broken" >:: begin fun () ->
      assert_equal (isConflicted(pg)) true;
      assert_equal (pg.table_type) "CONFLICTED";
    end;
    "\"1+1\" equals 2" >:: begin fun () ->
      assert_equal (Obj.magic (parse parser test_broken_lex "1+1")) 2
    end;
    "\"( 1+1 )*3 + ( (1+1) * (1+2*3+4) )\\n\" equals 28 (to be failed)" >:: begin fun () ->
      assert ((Obj.magic (parse parser test_broken_lex "( 1+1 )*3 + ( (1+1) * (1+2*3+4) )\n"):int) <> 28)
    end;
  ]
