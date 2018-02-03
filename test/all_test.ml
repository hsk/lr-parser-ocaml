open OUnit

let _ =
  run_test_tt_main("All test" >::: [
    Lexer_test.test ();
    Rule_parsing_test.test ();
    Nullableset_test.test ();
    Symboldiscriminator_test.test();
    Firstset_test.test ();
    Firstset_test.test2 ();
    Syntaxdb_test.test ();
    Closureitem_test.test ();
    Closureset_test.test ();
    Closureset_test.test2 ();
    Parser_test.test ();
    Broken_language_test.test ();
    Language_parsing_test.test ();
  ])
