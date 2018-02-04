open Language
open Token
open Utils
open Firstset
open Symboldiscriminator

(* 言語定義から得られる、構文規則に関する情報を管理するクラス *)
type grammarDB = {
  grammar: grammarDefinition;
  start_symbol: token;
  first: firstSet;
  symbols: symbolDiscriminator;
  tokenmap: int M.t;
  rulemap: (int * grammarRule) array M.t
}

(* それぞれの記号にidを割り振り、Token->numberの対応を生成 *)
let initTokenMap grammar : int M.t =
  let tokenid_counter = ref (-1) in
  let new_tokenid () =
    incr tokenid_counter;
    !tokenid_counter
  in
  let tokenmap = M.singleton "EOF" (new_tokenid()) in (* 入力の終端$の登録 *)
  let tokenmap = M.add "S'" (new_tokenid()) tokenmap in (* 仮の開始記号S'の登録 *)

  (* 左辺値の登録 *)
  let tokenmap = List.fold_left(fun (tokenmap:int M.t) (ltoken,_,_) ->
    (* 構文規則の左辺に現れる記号は非終端記号 *)
    if M.mem ltoken tokenmap then tokenmap else
    M.add ltoken (new_tokenid()) tokenmap
  ) tokenmap grammar in
  (* 右辺値の登録 *)
  List.fold_left(fun tokenmap (_,pattern,_) ->
    List.fold_left(fun tokenmap symbol ->
      if M.mem symbol tokenmap then tokenmap else
      (* 非終端記号でない(=左辺値に現れない)場合、終端記号である *)
      M.add symbol (new_tokenid()) tokenmap
    ) tokenmap pattern
  ) tokenmap grammar

(* ある記号を左辺とするような構文ルールとそのidの対応を生成 *)
let initDefMap grammar : (int * grammarRule) array M.t =
  let (_,rulemap) = List.fold_left(fun (i,(rulemap:(int * grammarRule) array M.t)) ((ltoken,_,_) as rule) ->
    let r = [|i, rule|] in
    let r = if M.mem ltoken rulemap then Array.append (M.find ltoken rulemap) r else r in
    (i+1, M.add ltoken r rulemap)
  ) (0,M.empty) grammar in
  rulemap

let genGrammarDB ((_,grammar,start): language) :grammarDB =
  let symbols = genSymbolDiscriminator grammar in
  {
    grammar = grammar;
    start_symbol = start;
    first = generateFirst grammar symbols;
    symbols = symbols;
    tokenmap = initTokenMap grammar;
    rulemap = initDefMap grammar;
  }


(* 構文規則がいくつあるかを返す ただし-1番の規則は含めない *)
let rule_size db: int = List.length db.grammar

(* 与えられたidの規則が存在するかどうかを調べる *)
let hasRuleId db id : bool = id >= -1 && id < rule_size(db)

(* 非終端記号xに対し、それが左辺として対応する定義を得る *)
(* 対応する定義が存在しない場合は空の配列を返す *)
let findRules db x : (int * grammarRule) array =
  if M.mem x db.rulemap then M.find x db.rulemap else [||]

(* 規則idに対応した規則を返す *)
(* -1が与えられた時は S' -> S $の規則を返す *)
let getRuleById db id : grammarRule =
  if (id = -1) then ("S'", [db.start_symbol], None)
  (* GrammarRule("S'", Array(this.start_symbol, "EOF")) *)
  else if id >= 0 && id < List.length db.grammar then List.nth db.grammar id
  else failwith("grammar id out of range")

(* [[Token]]を与えると一意なidを返す *)
let getTokenId db token =
  if not (M.mem token db.tokenmap) then failwith("invalid token " ^ token) else
  M.find token db.tokenmap
