open Language
open Token
open Parser
open Rule_parser

let run callback =
  let result = Buffer.create 80 in
  let out1 str = Buffer.add_string result str in
  callback out1;
  Buffer.contents result

let exec_parsing_table parsing_table = run (fun out1 ->
  let o fmt = Printf.kprintf (fun str -> out1 str) fmt in
  let out fmt = Printf.kprintf (fun str -> out1 (str ^ "\n")) fmt in
  out "let parsing_table:parsingTable = [";
    parsing_table |> List.iter(fun p ->
      o "  [";
      p |> List.iter(fun (t, op) -> o "%S, %s;" t (show_op op));
      out "];"
    );
    out "]\n"
  )

(* 予め構文解析器を生成しておいて利用するためのソースコードを生成する *)
(* 構文ファイルを受け取り、それを処理できるパーサを構築するためのソースコードを返す
  * @param {string} input 言語定義文法によって記述された、解析対象となる言語
  * @returns {string} 生成されたパーサのソースコード
  *)
let exec(input: string): string = run (fun out1 ->
  let o fmt = Printf.kprintf (fun str -> out1 str) fmt in
  let out fmt = Printf.kprintf (fun str -> out1 (str ^ "\n")) fmt in
  let lexer = Lexer.create Rule_parser.lex in
  let (lex,grammar,start) :language = Obj.magic(rule_parse lexer input) in
  let parsing_table = Parsergenerator.generate language in

  out "open Token";
  out "open Language";
  out "open Parsingtable";
  out "open Parser";
  out "let language:language = (";
  out "  [";
  lex |> List.iter (fun (token,pattern,_) ->
    match pattern with
    | Reg(reg) -> out "\t\t%S, Reg %S,None;" token reg
    | Str(str) -> out "\t\t%S, Str %S,None;" token str
  );
  out "  ],[";
  grammar |>List.iter(fun(ltoken,ptn,_) ->
    o "    %S,[" ltoken; ptn |> List.iter (fun ptn -> o "%S;" ptn); out "];"
  );
  out "  ],%S)" start;
  out "";
  out "%s" (exec_parsing_table parsing_table);
  out "let parser = create language parsing_table";
)