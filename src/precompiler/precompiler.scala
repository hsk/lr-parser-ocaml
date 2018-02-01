package pg.precompiler

import pg.language.{Language}
import pg.language.{LexDefinition, LexRule, Language, GrammarDefinition,GrammarRule,Ptn,Str,Reg,reg}
import pg.token.{SYMBOL_EOF}
import pg.parser.parser.{parse}
import pg.parsergenerator.parsergenerator.{ParserGenerator,genParserGenerator}
import ruleparser.{language_parser}

private var import_path: String = "lavriapg"

(* パーサジェネレータをimportするためのディレクトリパス *)
let gen(import_path: string) =
  if (import_path.charAt(import_path.length - 1) <> '/') then import_path + "/" else import_path


(* 予め構文解析器を生成しておいて利用するためのソースコードを生成する *)
(* 構文ファイルを受け取り、それを処理できるパーサを構築するためのソースコードを返す
  * @param {string} input 言語定義文法によって記述された、解析対象となる言語
  * @returns {string} 生成されたパーサのソースコード
  *)
def exec(input: String): String = {
  let language: Language = parse(language_parser,input) in
  (* Printf.fprintf stderr language; *)
  let parsing_table = genParserGenerator(language).parsing_table in
  let result = Buffer.create 80 in
  let log str = Buffer.add_string result (str ^ "\n") in
  let log1 str = Buffer.add_string result str in
  log "import pg.token.{Token, SYMBOL_EOF}";
  log "import pg.language.{Language}";
  log "import pg.parsingtable.{ParsingOperation, ParsingTable}";
  log "import pg.parser.parser.{Parser}";
  log "import pg.parser.factory.{ParserFactory}\n";
  log "val language: Language = Language(";
  log "\t[";
  for (i <- 0 until language.lex.length) {
    let token = language.lex(i).token in
    let pattern = language.lex(i).pattern in
    log1 "\t\(" ^ ("\"" ^ token ^ "\"") ^ ", ";
    (match pattern with
    case Reg(reg) -> log1 reg
    case Str(str) -> log1 "\"" ^ str ^ "\""
    );
    log1 ")";
    if (i != language.lex.length - 1) log1 ","
    log ""
  }
  log "\t],"
  log "\t["
  for (i <- 0 until language.grammar.length) {
    val ltoken = language.grammar(i).ltoken
    val pattern = language.grammar(i).pattern
    log "\t\tGrammarRule(";
    log ("\t\t\t\"" ^ ltoken ^ "\",");
    log1 "\t\t\t" ^ "Array(";
    for (ii <- 0 until pattern.length) {
      log1 "\"" + (pattern(ii).toString) + "\""
      if (ii != pattern.length - 1) log1 ", "
    }
    log ")"
    log1 "\t\t" + ")"
    if (i != language.grammar.length - 1) log1 ","
    log ""
  }
  log "\t),"
  log "\t\"" + (language.start_symbol.toString) + "\""
  log ")\n"
  log "val parsing_table:ParsingTable = Array("
  for (i <- 0 until parsing_table.length) {
    log "\tMap[Token, ParsingOperation]("
    parsing_table(i).foreach{case (value, key) =>
      log "\t\t" + (if(key == SYMBOL_EOF) "SYMBOL_EOF" else ("\"" + (key.toString)+ "\"")) + "-> " + value + ","
    }
    result = result.substring(0, result.length -2)
    log "),"
  }
  result = result.substring(0, result.length-2)
  log "\n)\n";
  log "val parser:Parser = ParserFactory.create(language, parsing_table)";
  result
