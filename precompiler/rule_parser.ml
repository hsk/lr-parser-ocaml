open Language
open Token
open Lexer
open Parser

let show (lex,language) = Printf.sprintf "(%s,%s)" (Lexer.show_lexDef lex) (Language.show language)

let lex: lexDefinition = [
  "EXCLAMATION",Str"!",None;
  "VBAR",       Str"|",None;
  "DOLLAR",     Str"$",None;
  "COLON",      Str":",None;
  "SEMICOLON",  Str";",None;
  "LABEL",      Reg"[a-zA-Z_][a-zA-Z0-9_]*",None;
  "REGEXP",     Reg"\\/.*\\/[gimuy]*",      Some(fun(v,_) ->
    let tmp = Str.split (Str.regexp "/") v in
    let flags = if String.sub v (String.length v - 1) 1 = "/" then ""
      else List.nth tmp ((List.length tmp) - 1) in
    let p = String.sub v 1 ((String.length v) - 2 - (String.length flags)) in
    let p = Str.global_replace (Str.regexp "\\\\r") "\r" p in
    let p = Str.global_replace (Str.regexp "\\\\n") "\n" p in
    let p = Str.global_replace (Str.regexp "\\\\t") "\t" p in
    (if flags="" then "" else "(?" ^ flags ^ ")") ^ p
  );
  "STRING", Reg"\".*\"",               Some(fun(v,_) -> String.sub v 1 (String.length v-2));
  "STRING", Reg"'.*'",                 Some(fun(v,_) -> String.sub v 1 (String.length v-2));
  "",       Reg"\\(\r\n\\|\r\\|\n\\)+",None;
  "",       Reg"[ \t]+",               None;
  "INVALID",Reg".",                    None;
]

type grammar = Grammar of token * grammarDefinition
type sect = grammar
type sectLabel = SectLabel of token * string

let grammar: grammarDefinition = [
  "LANGUAGE", ["LEX";"GRAMMAR"], Some(fun ([c0;c1], _) ->
    let Grammar(start_symbol,grammar) = Obj.magic c1 in
    (* 開始記号の指定がない場合、最初の規則に設定] *)
    let start_symbol = match start_symbol,grammar with
    | "",(ltoken,_,_)::_ -> ltoken
    | s,_ -> s
    in
    Obj.magic ((Obj.magic c0 :lexDefinition), (grammar, start_symbol))
  );
  "LEX", ["LEX";"LEXSECT"], Some(fun ([c0;c1], _) ->
    Obj.magic ((Obj.magic c0) @ [(Obj.magic c1:lexRule)])
  );
  "LEX", ["LEXSECT"], Some(fun ([c0], _) -> Obj.magic [(Obj.magic c0:lexRule)]);
  "LEXSECT", ["LEXLABEL";"LEXDEF"], Some(fun ([c0;c1], _) ->
    Obj.magic ((Obj.magic c0 : token), (Obj.magic c1 : ptn),None)
  );
  "LEXLABEL", ["LABEL"], Some(fun ([c0], _) -> c0);
  "LEXLABEL", ["EXCLAMATION"], Some(fun (_,_) -> "");
  "LEXLABEL", ["EXCLAMATION";"LABEL"], Some(fun (_,_) -> "");
  "LEXDEF", ["STRING"], Some(fun ([c0], _) -> Obj.magic(Str c0));
  "LEXDEF", ["REGEXP"], Some(fun ([c0], _) -> Obj.magic(Reg c0));
  "GRAMMAR", ["SECT";"GRAMMAR"], Some(fun ([c0;c1], _) ->
    let Grammar(start_symbol0,sect) = Obj.magic c0 in
    let Grammar(start_symbol1,grammar) = Obj.magic c1 in
    let start_symbol = if start_symbol0 <> "" then start_symbol0 else start_symbol1 in
    Obj.magic (Grammar(start_symbol, sect @ grammar))
  );
  "GRAMMAR", ["SECT"], Some(fun ([c0], _) -> c0);
  "SECT", ["SECTLABEL";"COLON";"DEF";"SEMICOLON"], Some(fun ([c0;_;c2;_], _) ->
    let SectLabel(start_symbol,label) = (Obj.magic c0) in
    let result = (Obj.magic c2 : string list list) |> List.map(fun pt ->
      (label, pt, None)
    ) in
    Obj.magic(Grammar(start_symbol, result))
  );
  "SECTLABEL", ["LABEL"], Some(fun ([c0], _) -> Obj.magic(SectLabel("", c0)));
  "SECTLABEL", ["DOLLAR";"LABEL"], Some(fun ([_;c1], _) -> Obj.magic(SectLabel(c1, c1)));
  "DEF", ["PATTERN";"VBAR";"DEF"], Some(fun ([c0;_;c2], _) -> Obj.magic((Obj.magic c0 : string list) :: (Obj.magic c2 : string list list)));
  "DEF", ["PATTERN"], Some(fun ([c0], _) -> Obj.magic[(Obj.magic c0 : string list)]);
  "PATTERN", ["SYMBOLLIST"], Some(fun([c0],_)->c0);
  "PATTERN", [], Some(fun (c, _) -> Obj.magic []);
  "SYMBOLLIST", ["LABEL";"SYMBOLLIST"], Some(fun ([c0;c1], _) -> Obj.magic(c0 :: (Obj.magic c1 : string list)));
  "SYMBOLLIST", ["LABEL"], Obj.magic(Some(fun ([c0], _) -> [c0]));
]

(* 言語定義文法の言語定義 *)
let language = language(grammar, "LANGUAGE")

(* 言語定義文法の言語定義、の構文解析表 *)
let parsing_table: parsingTable = [
  ["LANGUAGE",Goto(1);"LEX",Goto(2);"LEXSECT",Goto(3);"LEXLABEL",Goto(4);"LABEL",Shift(5);"EXCLAMATION",Shift(6)];
  ["EOF",Accept];
  ["GRAMMAR",Goto(7);"LEXSECT",Goto(8);"SECT",Goto(9);"SECTLABEL",Goto(10);"LABEL",Shift(11);"DOLLAR",Shift(12);"LEXLABEL",Goto(4);"EXCLAMATION",Shift(6)];
  ["LABEL",Reduce(2);"DOLLAR",Reduce(2);"EXCLAMATION",Reduce(2)];
  ["LEXDEF",Goto(13);"STRING",Shift(14);"REGEXP",Shift(15)];
  ["STRING",Reduce(4);"REGEXP",Reduce(4)];
  ["LABEL",Shift(16);"STRING",Reduce(5);"REGEXP",Reduce(5)];
  ["EOF",Reduce(0)];
  ["LABEL",Reduce(1);"DOLLAR",Reduce(1);"EXCLAMATION",Reduce(1)];
  ["SECT",Goto(9);"SECTLABEL",Goto(10);"LABEL",Shift(17);"DOLLAR",Shift(12);"GRAMMAR",Goto(18);"EOF",Reduce(10)];
  ["COLON",Shift(19)];
  ["COLON",Reduce(12);"STRING",Reduce(4);"REGEXP",Reduce(4)];
  ["LABEL",Shift(20)];
  ["LABEL",Reduce(3);"DOLLAR",Reduce(3);"EXCLAMATION",Reduce(3)];
  ["LABEL",Reduce(7);"DOLLAR",Reduce(7);"EXCLAMATION",Reduce(7)];
  ["LABEL",Reduce(8);"DOLLAR",Reduce(8);"EXCLAMATION",Reduce(8)];
  ["STRING",Reduce(6);"REGEXP",Reduce(6)];
  ["COLON",Reduce(12)];
  ["EOF",Reduce(9)];
  ["DEF",Goto(21);"PATTERN",Goto(22);"SYMBOLLIST",Goto(23);"LABEL",Shift(24);"SEMICOLON",Reduce(17);"VBAR",Reduce(17)];
  ["COLON",Reduce(13)];
  ["SEMICOLON",Shift(25)];
  ["VBAR",Shift(26);"SEMICOLON",Reduce(15)];
  ["SEMICOLON",Reduce(16);"VBAR",Reduce(16)];
  ["LABEL",Shift(24);"SYMBOLLIST",Goto(27);"SEMICOLON",Reduce(19);"VBAR",Reduce(19)];
  ["EOF",Reduce(11);"LABEL",Reduce(11);"DOLLAR",Reduce(11)];
  ["PATTERN",Goto(22);"DEF",Goto(28);"SYMBOLLIST",Goto(23);"LABEL",Shift(24);"SEMICOLON",Reduce(17);"VBAR",Reduce(17)];
  ["SEMICOLON",Reduce(18);"VBAR",Reduce(18)];
  ["SEMICOLON",Reduce(14)];
]

(* 言語定義ファイルを読み込むための構文解析器 *)
let rule_parse = Parser.create grammar ("",parsing_table)

let read filename =
  let lines = ref [] in
  let chan = open_in filename in
  try
    while true; do
      lines := input_line chan :: !lines
    done;
    ""
  with End_of_file ->
    close_in chan;
    String.concat "\n" (List.rev !lines)
