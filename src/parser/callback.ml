open Language
open Ast

(**
  * 字句解析・構文解析時に呼び出されるコールバックを管理するコントローラー
  * いわゆるStrategyパターン
  *)
module type CallbackController = sig
  type t
  val language: t language
  val init: unit -> unit
  val callLex: int * t -> t
  val callGrammar: int * t list -> t
end

(**
  * 言語情報に付随するコールバックを呼び出すコントローラ
  *)
module DefaultCallbackController = struct
module Make(X : sig type t val language: t language end) : CallbackController = struct
  include X
  
  (**
    * 解析を開始する際、初期化のために呼び出される
    * デフォルトでは何もしない
    *)
  let init(): unit = () (* do nothing *)
  
  let callLex ((id: int), (value: t)): t =
    let Language(lex,_, _) = language in
    match List.nth lex id with
    | LexRule(token,_,_,Some(callback)) -> callback(value, Obj.magic token)
    | _ -> value

  let callGrammar((id: int), (children: t list)): t =
    let Language(_,grammer, _) = language in
    match List.nth grammer id with
    | GrammarRule(ltoken,_,Some(callback)) -> callback(children, ltoken)
    | _ -> List.nth children 0
end
end

(**
  * ASTを構築するコントローラ
  *)
module ASTConstructor = struct
module Make(X : sig type t val language: t language end) : CallbackController = struct
  include X
  (**
    * 解析を開始する際、初期化のために呼び出される
    * デフォルトでは何もしない
    *)
  let init(): unit = () (* do nothing *)

  let callLex ((id: int), (value: t)): t =
    let Language(lex,_, _) = language in
    let LexRule(token,_,_,_) = List.nth lex id in
    Obj.magic(ASTNode(token, Obj.magic value, []))

  let callGrammar((id: int), (children: t list)): t =
    let Language(_,grammer, _) = language in
    let GrammarRule(ltoken,_,_) = List.nth grammer id in
    Obj.magic(ASTNode(ltoken, Obj.magic (), Obj.magic children))
end
end
