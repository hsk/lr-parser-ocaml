open Language
open Token
open Callback
  (**
    * 字句解析器
    * 入力を受け取ってトークン化する
    *)
module Make(C : CallbackController) = struct
  let Language(lex,grammar, _) = C.language
  (**
    * 入力からトークン1つ分読み込む
    *)
  let step (input:string): (string * tokenizedInput) =
    if (input = "") then (input, (symbol_eof,Obj.magic "")) else begin (* 最後にEOFトークンを付与 *)
    let (_,result,result_match,result_id) = List.fold_left(
    fun (id,result,result_match,result_id) (LexRule(token,pattern,rule_priority,_) as rule) ->
        let m = (match pattern with
        (*  | Reg(ptn) -> ptn.r.findPrefixOf(input) *)
          | Str(ptn) when String.sub input 0 (String.length ptn) <> ptn -> None (* マッチしない *)
          | Str(ptn) when (String.length ptn >= String.length input) -> Some(ptn)
          (* マッチした文字列の末尾が\wで、その直後の文字が\wの場合はスキップ *)
          (* | Str(ptn) when ("\\w$".r.findFirstIn(ptn) = None) -> Some(ptn)
          | Str(ptn) when ("^\\w".r.findFirstIn(input.substring(ptn.length)) = None) -> Some(ptn) *)
          | _ -> None
        ) in
        match (m, result) with
        | (Some(m),_) when result_id = -1 -> (id+1,Some rule,m,id)
        | (Some(m),Some(LexRule(_,_,result_priority,_)))
          when rule_priority > result_priority ||
            (rule_priority == result_priority && String.length m > String.length result_match) -> (id+1,Some rule,m,id)
        | (_,result) -> (id+1,result,result_match,result_id)
    ) (0,None,"",-1) lex in
    match result with
    | None -> failwith("no pattern matched") (* マッチする規則がなかった *)
    | Some(LexRule(token,_,_,_)) ->
      let m = C.callLex(result_id, Obj.magic result_match) in
      (String.sub input 0 (String.length result_match), (token, m))
  end
  
  (**
    * 与えられた入力をすべて解析し、トークン列を返す
    *)
  let exec input =
    let rec loop input result =
      match step input with
      | (i,(("EOF",_) as r)) -> List.rev (r::result)
      | (i,("NULL",_)) -> loop i result
      | (i,r) -> loop i (r::result)
    in
    loop input []
end
