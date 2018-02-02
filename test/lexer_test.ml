open OUnit
open Lexer
open Sample_language
open Token
open Language
open Callback

let test () =
  "Lexer test" >::: [
    "test" >:: begin fun () ->
      assert_equal "a" "a"
    end;
    "exec valid input" >:: begin fun () ->
      let lexer = test_sample_lex in
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in
      assert_equal ~printer:Lexer.show (exec c lexer "xabc;x|&0ax x z;") [
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
      let lexer = [] in
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in
      assert_raises (Failure "no pattern matched") (fun () ->exec c lexer "xabc;x|&0ax x z;")
    end;
    
    "exec no length input" >:: begin fun () ->
      let lexer = test_sample_lex in
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in
      assert_equal ~printer:Lexer.show (exec c lexer "") [
        "EOF", ""
      ];
      let lexer = [] in
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in
      assert_equal ~printer:Lexer.show (exec c lexer "") [
        "EOF", ""
      ]
    end;
    (*
    "regexp flags" >:: begin fun () ->
      let lexer = [
        "I", Reg("(?i)AbC"),0,None;
        "M", Reg("(?m)x\\nyz"),0,None;
        "U", Reg("(?u)\\u0064\\u0065\\u0066"),0,None;
        "G", Reg("pqr"),0,None;
        "A", Reg("(?imu)\\u0061\\nC"),0,None;
      ] in
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in
      assert_equal ~printer:Lexer.show (exec c lexer "abcx\\nyzdefpqra\\nc") [
        "I", "abc";
        "M", "x\\nyz";
        "U", "def";
        "G", "pqr";
        "A", "a\\nc";
        "EOF", "";
      ]
    end;
    *)
    "skip string pattern if the following is \\\\w" >:: begin fun () ->
      let lexer = [
        "STR", Str("abc"),0,None;
        "REGEXP", Reg("abc"),0,None;
        "ASTERISK", Str("*"),0,None;
        "XYZ", Str("xyz"),0,None;
      ] in
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in
      assert_equal ~printer:Lexer.show (exec c lexer "abcxyz*abc*xyz*abcabc") [
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
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in      
      assert_equal ~printer:Lexer.show (exec c lexer " +-+-*abcd xyzw") [
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
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in      
      assert_equal ~printer:Lexer.show (exec c lexer " +-+-*abcd ") [
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
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in      
      assert_equal ~printer:Lexer.show (exec c lexer " *abc* ") [
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
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in      
      assert_equal ~printer:Lexer.show (exec c lexer " *abc* ") [
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
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in      
      assert_equal ~printer:Lexer.show (exec c lexer " *abc* ") [
        "ASTERISK", "*";
        "ABCAST", "abc*";
        "EOF", "";
      ];
      assert_equal ~printer:Lexer.show (exec c lexer " *abc* ") [
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
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in      
      assert_raises (Failure "custom callback") (fun () ->exec c lexer " x ")
    end;
    "custom callback (set CallbackController)" >:: begin fun () ->
      let lexer = [
        "ERROR", Str("x"),0, Some(fun (a,_) ->
          failwith("custom callback")
        );
        "", Str(" "),0,None;
      ] in
      let c = makeDefaultConstructor(Language(lexer, ["S", [], None], "S")) in      
      assert_raises (Failure "custom callback") (fun () ->exec c lexer " x ")
    end;
  ]
