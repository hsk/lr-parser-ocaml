open OUnit
open Token
open Sample_language
open Parsergenerator
open Parser
open Language
open Callback

let test () =
  Printf.printf "type=%s\n%!" (genParserGenerator test_calc_language).table_type;
  let parsingtable = (genParserGenerator test_calc_language).parsing_table in
  let parser = Parser.createAst test_calc_language (genParserGenerator test_calc_language).parsing_table in
  "parser test" >::: [
    "parser factory" >:: begin fun () ->
      (*Printf.printf "%s\n%!" (Parser.show(parsingtable));*)
      assert_equal("[[ATOM -> Goto(1),DIGITS -> Shift(2),EXP -> Goto(3),LPAREN -> Shift(4),TERM -> Goto(5)],[ASTERISK -> Reduce(3),EOF -> Reduce(3),PLUS -> Reduce(3),RPAREN -> Reduce(3)],[ASTERISK -> Reduce(4),EOF -> Reduce(4),PLUS -> Reduce(4),RPAREN -> Reduce(4)],[EOF -> Accept,PLUS -> Shift(6)],[ATOM -> Goto(1),DIGITS -> Shift(2),EXP -> Goto(7),LPAREN -> Shift(4),TERM -> Goto(5)],[ASTERISK -> Shift(8),EOF -> Reduce(1),PLUS -> Reduce(1),RPAREN -> Reduce(1)],[ATOM -> Goto(1),DIGITS -> Shift(2),LPAREN -> Shift(4),TERM -> Goto(9)],[PLUS -> Shift(6),RPAREN -> Shift(10)],[ATOM -> Goto(11),DIGITS -> Shift(2),LPAREN -> Shift(4)],[ASTERISK -> Shift(8),EOF -> Reduce(0),PLUS -> Reduce(0),RPAREN -> Reduce(0)],[ASTERISK -> Reduce(5),EOF -> Reduce(5),PLUS -> Reduce(5),RPAREN -> Reduce(5)],[ASTERISK -> Reduce(2),EOF -> Reduce(2),PLUS -> Reduce(2),RPAREN -> Reduce(2)]]"
      )(Parser.show(parsingtable));
      Parser.createAst test_calc_language parsingtable |> ignore
    end;
    "getting calc language ast" >:: begin fun () ->
      (*let (ast : ast) = Obj.magic(parse parser (getLexer test_calc_language) "1") in
      Printf.printf "ast=%s\n%!" (Callback.show ast);*)
      assert(Obj.magic(parse parser (getLexer test_calc_language) "1+1") =
        ASTNode("EXP", "",
          [
            ASTNode("EXP", "", [
              ASTNode("TERM", "", [
                ASTNode("ATOM", "", [
                  ASTNode("DIGITS", "1", [])])])]);
            ASTNode("PLUS", "+", []);
            ASTNode("TERM", "", [
              ASTNode("ATOM", "", [
                ASTNode("DIGITS", "1", [])])])
          ])
      )
    end;
    "invalid input" >:: begin fun () ->
      assert(Obj.magic(parse parser (getLexer test_calc_language) "1zzz") = ASTNode("DIGITS", "1", []))
    end;
  ]
let test2 () =
  "test grammar input with callback" >::: [
    "custom callback in grammar" >:: begin fun () ->
      let parser = Parser.create test_calc_language (genParserGenerator test_calc_language).parsing_table in
      assert(Obj.magic(parse parser (getLexer test_calc_language) "2*(3+4)") = 14)
    end;
  ]
