open OUnit
open Token
open Lexer

let test_sample_lex: lexDefinition = [
  "ATOM",      Str("x"),0,None;
  "ID",        Reg("[a-zA-Z_][a-zA-Z0-9_]*"),0,None;
  "SEMICOLON", Str(";"),0,None;
  "SEPARATE",  Str("|"),0,None;
  "", Reg("(\\r\\n|\\r|\\n)+"),0,None;
  "", Reg("[ \\f\\t]+"),0,None;
  "INVALID",   Reg("."),0,None;
]

let test () =
  "Lexer test" >::: [
    "test" >:: begin fun () ->
      assert_equal "a" "a"
    end;
    "exec valid input" >:: begin fun () ->
      let lexing = create test_sample_lex in
      assert_equal ~printer:Lexer.show (lexing "xabc;x|&0ax x z;") [
        "ID", "xabc";
        "SEMICOLON", ";";
        "ATOM", "x";
        "SEPARATE", "|";
        "INVALID", "&";
        "INVALID", "0";
        "ID", "ax";  
        "ATOM", "x";
        "ID", "z";
        "SEMICOLON", ";";
        "EOF", "";
      ]
    end;
    "exec invalid input" >:: begin fun () ->
      let lexing = create [] in
      assert_raises (Failure "no pattern matched") (fun () ->lexing "xabc;x|&0ax x z;")
    end;
    "exec no length input" >:: begin fun () ->
      let lexing = create test_sample_lex in
      assert_equal ~printer:Lexer.show (lexing "") [
        "EOF", ""
      ];
      let lexing = create [] in
      assert_equal ~printer:Lexer.show (lexing "") [
        "EOF", ""
      ]
    end;
    "skip string pattern if the following is \\\\w" >:: begin fun () ->
      let lexer = [
        "STR", Str("abc"),0,None;
        "REGEXP", Reg("abc"),0,None;
        "ASTERISK", Str("*"),0,None;
        "XYZ", Str("xyz"),0,None;
      ] in
      let lexing = create lexer in
      assert_equal ~printer:Lexer.show (lexing "abcxyz*abc*xyz*abcabc") [
        "REGEXP","abc";
        "XYZ","xyz";
        "ASTERISK","*";
        "STR","abc";
        "ASTERISK","*";
        "XYZ","xyz";
        "ASTERISK","*";
        "REGEXP","abc";
        "STR","abc";
        "EOF",""
      ]
    end;
    "rule priority" >:: begin fun () ->
      let lexer = [
        "PM", Str("+-"),0,None;
        "PMA", Str("+-*"),0,None;
        "ASTERISK", Str("*"), 1,None;
        "ABC", Reg("abc"),0,None;
        "ABCD", Reg("abcd"),0,None;
        "ABCD2", Str("abcd"),2,None;
        "D", Reg("d"),0,None;
        "XYZ", Reg("xyz"),0,None;
        "XYZW", Reg("xyzw"), -1, None;
        "W", Str("w"),0,None;
        "", Str(" "),0,None;
      ] in
      let lexing = create lexer in      
      assert_equal ~printer:Lexer.show (lexing " +-+-*abcd xyzw") [
        "PM","+-";
        "PMA","+-*";
        "ABCD2","abcd";
        "XYZ","xyz";
        "W","w";
        "EOF","";
      ]
    end;
    "longest match" >:: begin fun () ->
      let lexer = [
        "PM", Str("+-"),0,None;
        "PMA", Str("+-*"),0,None;
        "ASTERISK", Str("*"),0,None;
        "ABC", Reg("abc"),0,None;
        "ABCD", Reg("abcd"),0,None;
        "ABCD2", Reg("abcd"),0,None;
        "D", Reg("d"),0,None;
        "", Str(" "),0,None;
      ] in
      let lexing = create lexer in      
      assert_equal ~printer:Lexer.show (lexing " +-+-*abcd ") [
        "PM", "+-";
        "PMA", "+-*";
        "ABCD", "abcd";
        "EOF", "";
      ]
    end;
    "add rule and exec again after reset 1" >:: begin fun () ->
      let lexer = [
        "ASTERISK", Str("*"),0,None;
        "ABC", Reg("abc"),0,None;
        "", Str(" "),0,None;
      ] in
      let lexing = create lexer in      
      assert_equal ~printer:Lexer.show (lexing " *abc* ") [
        "ASTERISK", "*";
        "ABC", "abc";
        "ASTERISK", "*";
        "EOF", "";
      ];
    end;
    "add rule and exec again after reset 2" >:: begin fun () ->
      let lexer = [
        "ASTERISK", Str("*"),0,None;
        "ABC", Reg("abc"),0,None;
        "", Str(" "),0,None;
        "ABCAST", Reg("abc\\*"), 1,None;
      ] in
      let lexing = create lexer in      
      assert_equal ~printer:Lexer.show (lexing " *abc* ") [
        "ASTERISK", "*";
        "ABCAST", "abc*";
        "EOF", "";
      ];
    end;
    "add rule and exec again after reset 3" >:: begin fun () ->
      let lexer = [
        "ASTERISK", Str("*"),0,None;
        "ABC", Reg("abc"),0,None;
        "", Str(" "),0,None;
        "ABCAST", Reg("abc\\*"), 1,None;
        "ABCAST", Reg("abc\\*"), 1,None;
      ] in
      let lexing = create lexer in      
      assert_equal ~printer:Lexer.show (lexing " *abc* ") [
        "ASTERISK", "*";
        "ABCAST", "abc*";
        "EOF", "";
      ];
      assert_equal ~printer:Lexer.show (lexing " *abc* ") [
        "ASTERISK", "*";
        "ABCAST", "abc*";
        "EOF", "";
      ]
    end;
    "custom callback (without CallbackController)" >:: begin fun () ->
      (* デフォルトの挙動がこれでいいのか不明 *)
      let lexer = [
        "ERROR", Str("x"),0, Some (fun(a,b) ->
          failwith("custom callback")
        );
        "", Str(" "),0,None;
      ] in
      let lexing = create lexer in      
      assert_raises (Failure "custom callback") (fun () ->lexing " x ")
    end;
    "custom callback (set CallbackController)" >:: begin fun () ->
      let lexer = [
        "ERROR", Str("x"),0, Some(fun (a,_) ->
          failwith("custom callback")
        );
        "", Str(" "),0,None;
      ] in
      let lexing = create lexer in      
      assert_raises (Failure "custom callback") (fun () ->lexing " x ")
    end;
  ]

let _ = run_test_tt_main(test())
