open Token
open Language

(* 入力からトークン1つ分読み込む *)
let step (c:callbackController) lex (input:string): (string * tokenizedInput) =
  if (input = "") then (input, ("EOF",Obj.magic "")) else begin (* 最後にEOFトークンを付与 *)
    let (_,result,result_match,result_id) = List.fold_left(
      fun (id,result,result_match,result_id) ((token,pattern,rule_priority,_) as rule) ->
        let m = (match pattern with
          (*| Reg(ptn) when (Printf.printf "Reg(%s)\n%!" ptn;false) -> None*)
          | Reg(ptn) when Str.string_match (Str.regexp ptn) input 0 -> Some(Str.matched_string input)
          | Str(ptn) when String.length ptn > String.length input -> None (* マッチしない *)
          | Str(ptn) when String.sub input 0 (String.length ptn) <> ptn -> None (* マッチしない *)
          | Str(ptn) when ptn = input -> Some(ptn)
          (* マッチした文字列の末尾が\wで、その直後の文字が\wの場合はスキップ *)
          | Str(ptn) when not (Str.string_match (Str.regexp ".*[a-zA-Z_0-9]$") ptn 0) -> Some(ptn)
          | Str(ptn) when not (Str.string_match (Str.regexp "[a-zA-Z_0-9]") (Str.string_after input (String.length ptn) ) 0) -> Some(ptn)
          | _ -> None
        ) in
        match (m, result) with
        | (Some(m),None) -> (id+1,Some rule,m,id)
        | (Some(m),Some(_,_,result_priority,_))
          when rule_priority > result_priority ||
            (rule_priority == result_priority && String.length m > String.length result_match) -> (id+1,Some rule,m,id)
        | (_,result) -> (id+1,result,result_match,result_id)
    ) (0,None,"",-1) lex in
    match result with
    | None -> Printf.printf "error [%s] %d\n%!" input (int_of_char (String.get input 0)); failwith("no pattern matched") (* マッチする規則がなかった *)
    | Some(token,_,_,_) ->
      let m = c.callLex(result_id, Obj.magic result_match) in
      (Str.string_after input (String.length result_match), (token, m))
  end
  
(* 与えられた入力をすべて解析し、トークン列を返す *)
let exec c lex input =
  let rec loop input result =
    match step c lex input with
    | (i,(("EOF",_) as r)) -> List.rev (r::result)
    | (i,("",_)) -> loop i result
    | (i,("NULL",_)) -> loop i result
    | (i,r) -> loop i (r::result)
  in
  loop input []

let show ls = "[" ^ String.concat ";" (List.map (fun (a,b)-> a^","^b) ls) ^ "]"

let create lang = exec (makeDefaultConstructor lang) lang.lex
