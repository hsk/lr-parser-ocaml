open OUnit
open Token
open Lexer

let test_sample_lex: lexDefinition = [
  "ATOM",      Str("x"),                     None;
  "ID",        Reg("[a-zA-Z_][a-zA-Z0-9_]*"),None;
  "SEMICOLON", Str(";"),                     None;
  "SEPARATE",  Str("|"),                     None;
  "",          Reg("(\\r\\n|\\r|\\n)+"),     None;
  "",          Reg("[ \\f\\t]+"),            None;
  "INVALID",   Reg("."),                     None;
]

let test () =
  "Lexer test" >::: [
    "exec valid input" >:: begin fun () ->
      let lexer = create test_sample_lex in
      assert_equal ~printer:Lexer.show (lexer "xabc;x|&0ax x z;") [
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
      let lexer = create [] in
      assert_raises (Failure "no pattern matched") (fun () ->lexer "xabc;x|&0ax x z;")
    end;
    "exec no length input" >:: begin fun () ->
      let lexer = create test_sample_lex in
      assert_equal ~printer:Lexer.show (lexer "") [
        "EOF", ""
      ];
      let lexer = create [] in
      assert_equal ~printer:Lexer.show (lexer "") [
        "EOF", ""
      ]
    end;
    "skip string pattern if the following is \\\\w" >:: begin fun () ->
      let lexer = create [
        "STR",      Str("abc"), None;
        "REGEXP",   Reg("abc"), None;
        "ASTERISK", Str("*"),   None;
        "XYZ",      Str("xyz"), None;
      ] in
      assert_equal ~printer:Lexer.show (lexer "abcxyz*abc*xyz*abcabc") [
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
      let lexer = create [
        "ABCD2",    Str("abcd"),None;
        "ASTERISK", Str("*"),   None;
        "PM",       Str("+-"),  None;
        "PMA",      Str("+-*"), None;
        "ABC",      Reg("abc"), None;
        "ABCD",     Reg("abcd"),None;
        "D",        Reg("d"),   None;
        "XYZ",      Reg("xyz"), None;
        "W",        Str("w"),   None;
        "",         Str(" "),   None;
        "XYZW",     Reg("xyzw"),None;
      ] in
      assert_equal ~printer:Lexer.show (lexer " +-+-*abcd xyzw") [
        "PM","+-";
        "PMA","+-*";
        "ABCD2","abcd";
        "XYZW","xyzw";
        "EOF","";
      ]
    end;
    "longest match" >:: begin fun () ->
      let lexer = create [
        "PM",       Str("+-"),  None;
        "PMA",      Str("+-*"), None;
        "ASTERISK", Str("*"),   None;
        "ABC",      Reg("abc"), None;
        "ABCD",     Reg("abcd"),None;
        "ABCD2",    Reg("abcd"),None;
        "D",        Reg("d"),   None;
        "",         Str(" "),   None;
      ] in
      assert_equal ~printer:Lexer.show (lexer " +-+-*abcd ") [
        "PM", "+-";
        "PMA", "+-*";
        "ABCD", "abcd";
        "EOF", "";
      ]
    end;
    "add rule and exec again after reset 1" >:: begin fun () ->
      let lexer = create [
        "ASTERISK", Str("*"),  None;
        "ABC",      Reg("abc"),None;
        "",         Str(" "),  None;
      ] in
      assert_equal ~printer:Lexer.show (lexer " *abc* ") [
        "ASTERISK", "*";
        "ABC", "abc";
        "ASTERISK", "*";
        "EOF", "";
      ];
    end;
    "add rule and exec again after reset 2" >:: begin fun () ->
      let lexer = create [
        "ABCAST",   Reg("abc\\*"), None;
        "ASTERISK", Str("*"),      None;
        "ABC",      Reg("abc"),    None;
        "",         Str(" "),      None;
      ] in
      assert_equal ~printer:Lexer.show (lexer " *abc* ") [
        "ASTERISK", "*";
        "ABCAST", "abc*";
        "EOF", "";
      ];
    end;
    "add rule and exec again after reset 3" >:: begin fun () ->
      let lexer = create [
        "ASTERISK", Str("*"),     None;
        "ABC",      Reg("abc"),   None;
        "",         Str(" "),     None;
        "ABCAST",   Reg("abc\\*"),None;
        "ABCAST",   Reg("abc\\*"),None;
      ] in
      assert_equal ~printer:Lexer.show (lexer " *abc* ") [
        "ASTERISK", "*";
        "ABCAST", "abc*";
        "EOF", "";
      ];
      assert_equal ~printer:Lexer.show (lexer " *abc* ") [
        "ASTERISK", "*";
        "ABCAST", "abc*";
        "EOF", "";
      ]
    end;
    "custom callback (without CallbackController)" >:: begin fun () ->
      (* デフォルトの挙動がこれでいいのか不明 *)
      let lexer = create [
        "ERROR", Str("x"), Some (fun(a,b) -> failwith("custom callback"));
        "",      Str(" "), None;
      ] in
      assert_raises (Failure "custom callback") (fun () ->lexer " x ")
    end;
    "custom callback (set CallbackController)" >:: begin fun () ->
      let lexer = create [
        "ERROR", Str("x"),Some(fun (a,_) -> failwith("custom callback"));
        "",      Str(" "),None;
      ] in
      assert_raises (Failure "custom callback") (fun () ->lexer " x ")
    end;
  ]

let _ = run_test_tt_main(test())
