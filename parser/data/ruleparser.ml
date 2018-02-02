open Language
open Token
open Parser

let lex: lexDefinition = [
  "EXCLAMATION", Str("!"),0,None;
  "VBAR", Str("|"),0,None;
  "DOLLAR", Str("$"),0,None;
  "COLON", Str(":"),0,None;
  "SEMICOLON", Str(";"),0,None;
  "LABEL", Reg("[a-zA-Z_][a-zA-Z0-9_]*"),0,None;
  "REGEXP", Reg("\\/.*\\/[gimuy]*"), 0, Some(fun(v,_) ->
      let tmp = Str.split (Str.regexp "/") v in
      let flags = if String.sub v (String.length v - 1) 1 = "/" then ""
        else List.nth tmp ((List.length tmp) - 1) in
      let p = String.sub v 1 ((String.length v) - 2 - (String.length flags)) in
      let p = Str.global_replace (Str.regexp "\\\\r") "\r" p in
      let p = Str.global_replace (Str.regexp "\\\\n") "\n" p in
      let p = Str.global_replace (Str.regexp "\\\\t") "\t" p in
      (if flags="" then "" else "(?" ^ flags ^ ")") ^ p
    );
  "STRING", Reg("\".*\""), 0,Some(fun(v,_) -> String.sub v 1 (String.length v-2));
  "STRING", Reg("'.*'"), 0,Some(fun(v,_) -> String.sub v 1 (String.length v-2));
  "", Reg("\\(\r\n\\|\r\\|\n\\)+"),0,None;
  "", Reg("[ \t]+"),0,None;
  "INVALID", Reg("."),0,None;
]

type grammar = Grammar of token * grammarDefinition
type sect = grammar
type sectLabel = SectLabel of token * string

let grammar: grammarDefinition = [
  "LANGUAGE", ["LEX";"GRAMMAR"], Some(fun (c, _) ->
    let Grammar(start_symbol,grammar) = Obj.magic (List.nth c 1) in
    (* 開始記号の指定がない場合、最初の規則に設定] *)
    let start_symbol = match start_symbol,grammar with
    | "",(ltoken,_,_)::_ -> ltoken
    | s,_ -> s
    in
    Obj.magic (language(Obj.magic(List.nth c 0), grammar, start_symbol))
  );
  "LEX", ["LEX";"LEXSECT"], Some(fun (c, _) ->
    Obj.magic ((Obj.magic (List.nth c 0)) @ [(Obj.magic (List.nth c 1):lexRule)])
  );
  "LEX", ["LEXSECT"], Some(fun (c, _) -> Obj.magic [(Obj.magic (List.nth c 0):lexRule)]);
  "LEXSECT", ["LEXLABEL";"LEXDEF"], Some(fun (c, _) ->
    Obj.magic ((Obj.magic (List.nth c 0) : token), (Obj.magic (List.nth c 1) : ptn),0,None)
  );
  "LEXLABEL", ["LABEL"], Some(fun (c, _) -> List.nth c 0);
  "LEXLABEL", ["EXCLAMATION"], Some(fun (_,_) -> "");
  "LEXLABEL", ["EXCLAMATION";"LABEL"], Some(fun (_,_) -> "");
  "LEXDEF", ["STRING"], Some(fun (c, _) -> Obj.magic(Str(List.nth c 0)));
  "LEXDEF", ["REGEXP"], Some(fun (c, _) -> Obj.magic(Reg(List.nth c 0)));
  "GRAMMAR", ["SECT";"GRAMMAR"], Some(fun (c, _) ->
    let Grammar(start_symbol0,sect) = (Obj.magic (List.nth c 0) : sect) in
    let Grammar(start_symbol1,grammar) = (Obj.magic (List.nth c 1) : grammar) in
    let start_symbol = if start_symbol0 <> "" then start_symbol0 else start_symbol1 in
    Obj.magic (Grammar(start_symbol, sect @ grammar))
  );
  "GRAMMAR", ["SECT"], Some(fun (c, _) -> Obj.magic(Obj.magic (List.nth c 0) : grammar));
  "SECT", ["SECTLABEL";"COLON";"DEF";"SEMICOLON"], Some(fun (c, _) ->
    let SectLabel(start_symbol,label) = (Obj.magic (List.nth c 0)) in
    let result = (Obj.magic (List.nth c 2) : string list list) |> List.map(fun pt ->
      (label, pt, None)
    ) in
    Obj.magic(Grammar(start_symbol, result))
  );
  "SECTLABEL", ["LABEL"], Some(fun (c, _) -> Obj.magic(SectLabel("", List.nth c 0)));
  "SECTLABEL", ["DOLLAR";"LABEL"], Some(fun (c, _) -> Obj.magic(SectLabel(List.nth c 1, List.nth c 1)));
  "DEF", ["PATTERN";"VBAR";"DEF"], Some(fun (c, _) -> Obj.magic((Obj.magic (List.nth c 0) : string list) :: (Obj.magic (List.nth c 2) : string list list)));
  "DEF", ["PATTERN"], Some(fun (c, _) -> Obj.magic[(Obj.magic (List.nth c 0) : string list)]);
  "PATTERN", ["SYMBOLLIST"], Some(fun(c,_)->(List.nth c 0));
  "PATTERN", [], Some(fun (c, _) -> Obj.magic []);
  "SYMBOLLIST", ["LABEL";"SYMBOLLIST"], Some(fun (c, _) -> Obj.magic((List.nth c 0) :: (Obj.magic (List.nth c 1) : string list)));
  "SYMBOLLIST", ["LABEL"], Obj.magic(Some(fun (c, _) -> [(List.nth c 0)]));
]

(* 言語定義文法の言語定義 *)
let rule_language: language = language(lex, grammar, "LANGUAGE")

(* 言語定義文法の言語定義、の構文解析表 *)
let rule_parsing_table: parsingTable = [
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
let rule_parser = create rule_language rule_parsing_table

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
