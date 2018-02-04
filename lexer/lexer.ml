open Token

type ptn = Str of string | Reg of string (* パターン *)
type lexCallback = (any * any) -> any (* 字句規則マッチ時に呼び出されるコールバック *)
type lexRule = token * ptn * lexCallback option (* 単一の字句ルール *)
type lexDefinition = lexRule list(* 字句規則 *)

let show_ptn = function
  | Str(s) -> Printf.sprintf "Str(%S)" s
  | Reg(s) -> Printf.sprintf "Reg(%S)" s
let show_lexRule = function
  | (token,ptn,None) -> Printf.sprintf "(%S,%s,None)"  token (show_ptn ptn)
  | (token,ptn,Some(_)) -> Printf.sprintf "(%S,%s,Some(_))" token (show_ptn ptn)
let show_lexDef ls = "[" ^ String.concat ";" (List.map show_lexRule ls) ^ "]"

(* 入力からトークン1つ分読み込む *)
let step lex callback (input:string): (string * tokenizedInput) =
  if input = "" then (input, ("EOF", "")) else (* 最後にEOFトークンを付与 *)
  (* プライオリティ付きで、最長一致かつ、文字列指定の場合は特別な制限付きなので全部探索する *)
  let (_,rv,rid) = lex |> ((0,"",-1) |> List.fold_left(
    fun (id,rv,rid) (token,ptn,_) ->
      let m = match ptn with
        | Reg ptn when Str.string_match (Str.regexp ptn) input 0 -> Some(Str.matched_string input)
        | Str ptn when String.length ptn > String.length input -> None
        | Str ptn when ptn = input -> Some ptn
        | Str ptn when String.sub input 0 (String.length ptn) <> ptn -> None
        (* マッチした文字列の末尾が\wで、その直後の文字が\wの場合はスキップ *)
        | Str ptn when not(Str.string_match (Str.regexp ".*[a-zA-Z_0-9]$") ptn 0) -> Some ptn
        | Str ptn when not(Str.string_match (Str.regexp "[a-zA-Z_0-9]") (Str.string_after input (String.length ptn)) 0) -> Some ptn
        | _ -> None
      in
      match (m, rid) with
      | (Some v,-1) ->                                        (id+1, v, id) (* 初めて見つかった場合 *)
      | (Some v,_) when String.length v > String.length rv -> (id+1, v, id) (* 同じ優先順のときは最長一致 *)
      | _ ->                                                  (id+1,rv,rid) (* それ以外は以前のものを使用 *)
  )) in
  match rid with
  | -1 -> Printf.printf "error [%s] %d\n%!" input (int_of_char (String.get input 0));
          failwith("no pattern matched") (* マッチする規則がなかった *)
  | rid -> (Str.string_after input (String.length rv), (List.nth lex rid |>(fun(token,_,_)->token), callback(rid, rv)))

(* 与えられた入力をすべて解析し、トークン列を返す *)
let exec lex callback input =
  let rec loop input res =
    match step lex callback input with
    | (i,(("EOF",_) as r)) -> List.rev (r::res)
    | (i, (""   ,_)      ) -> loop i res
    | (i,              r ) -> loop i (r::res)
  in
  loop input []

(* exec の結果を文字列化 *)
let show ls = "[" ^ String.concat ";" (List.map (fun (a,b)-> a^","^b) ls) ^ "]"

(* 文字列を返す字句解析器を生成 *)
let create lex:lexer = exec lex (fun (id, value) ->
  match List.nth lex id with
  | (token,_,Some(callback)) -> callback(value, token)
  | _ -> value
)
