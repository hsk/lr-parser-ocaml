open OUnit
open Nullableset
open Token

let test () =
  let nulls = generateNulls Sample_language.grammar in
  "NullableSet test" >::: [
    "T is Nullable" >:: begin fun () ->
      assert(isNullable(nulls, "T"))
    end;
    "LIST is Nullable" >:: begin fun () ->
      assert(isNullable(nulls, "LIST"))
    end;
    "HOGE is not Nullable" >:: begin fun () ->
      assert(not(isNullable(nulls, "HOGE")))
    end;
    "E is not Nullable" >:: begin fun () ->
      assert(not(isNullable(nulls, "E")))
    end;
    "S is not Nullable" >:: begin fun () ->
      assert(not(isNullable(nulls, "S")))
    end;
  ]
