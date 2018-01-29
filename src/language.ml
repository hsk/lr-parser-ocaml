open Token

(**
  * パターン
  *)
type ptn =
 | Str of string
 | Reg of string

(**
  * 字句規則マッチ時に呼び出されるコールバック
  *)
type lexCallback = (any * any) -> any

(**
  * 単一の字句ルール
  *)
type lexRule =
  LexRule of token * ptn * int * lexCallback option
(**
  * 字句規則
  *)
type lexDefinition = lexRule list

(**
  * 構文のreduce時に呼び出されるコールバック
  *)
type grammarCallback = (any list * token) -> any

(**
  * 単一の構文ルール
  *)
type grammarRule = GrammarRule of token * token list * grammarCallback option

(**
  * 構文規則
  *)
type grammarDefinition = grammarRule list

(**
  * 言語定義
  *)
type language = Language of lexDefinition * grammarDefinition * token
