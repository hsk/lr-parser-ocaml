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
type 'n lexCallback = ('n * 'n) -> 'n

;;
(**
  * 単一の字句ルール
  *)
type 'n lexRule =
  LexRule of token * ptn * int * 'n lexCallback option
(**
  * 字句規則
  *)
type 'n lexDefinition = 'n lexRule list

(**
  * 構文のreduce時に呼び出されるコールバック
  *)
type 'n grammarCallback = ('n list * token) -> 'n

(**
  * 単一の構文ルール
  *)
type 'n grammarRule = GrammarRule of token * token list * 'n grammarCallback option

(**
  * 構文規則
  *)
type 'n grammarDefinition = 'n grammarRule list

(**
  * 言語定義
  *)
type 'n language = Language of 'n lexDefinition * 'n grammarDefinition * token
