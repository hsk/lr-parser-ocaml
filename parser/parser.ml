open Token
open Language

(* 構文解析器の実行する命令群 *)
type op =
  | Shift of int
  | Reduce of int
  | Conflict of int list * int list (* Shift/Reduceコンフリクト *)
  | Accept
  | Goto of int

let show_ls ls = "[" ^ String.concat "," ls ^ "]"
let show_ints ls =show_ls (List.map string_of_int ls)
let show_op = function
  | Shift(i) -> Printf.sprintf "Shift(%d)" i
  | Reduce(i) -> Printf.sprintf "Reduce(%d)" i
  | Conflict(l,r) -> Printf.sprintf "Conflict(%s,%s)" (show_ints l) (show_ints r)
  | Accept -> Printf.sprintf "Accept"
  | Goto(i) -> Printf.sprintf "Goto(%d)" i

(* 構文解析表 *)
type parsingTable = (Token.token * op) list list

let show1(p: (Token.token * op) list):string =
  show_ls (List.map (fun(t,op)->Token.show t ^ " -> " ^ show_op op) p)

let show (p:parsingTable) = show_ls (List.map show1 p)

(* 構文解析器 *)
type parser = (Language.grammarDefinition * parsingTable * callbackController)

let rec drop = function
  | (0, acc, res) -> (acc, res)
  | (n, acc, a :: res) -> drop (n - 1, a::acc, res)
  | _ -> failwith "stack is empty"

(* 構文解析ステートマシン *)
(* states 現在読んでいる構文解析表の状態番号を置くスタック *)
(* results 解析中のASTノードを置くスタック *)
let rec actions parser inputs states results = 
  match (parser, states, inputs) with
  | (_, _, []) -> ("", results)
  | ((grammar,parsingtable,controller), state::_, (token,value)::inp) ->
    begin try match List.assoc token (List.nth parsingtable state) with
    | Accept -> ("", results) (* 完了 *)
    | Shift(to1) -> actions parser inp (to1 :: states) (value :: results)
    | Reduce(grammar_id) ->
      let (ltoken,pattern,_) = List.nth grammar(grammar_id) in
      let rnum = List.length pattern in
      (* 右辺の記号の数だけポップ *)
      let (children, results2) = drop (rnum, [], results) in
      let child = controller.callGrammar(grammar_id, children) in
      (* 対応する規則の右辺の記号の数だけポップ *)
      let (_,((state2::_) as states2)) = drop (rnum, [], states) in
      (* 次は必ず Goto *)
      begin match List.assoc ltoken (List.nth parsingtable state2) with
      | Goto(to1) -> actions parser inputs (to1 :: states2) (child :: results2)
      | _ -> ("parse failed: goto operation expected after reduce operation", child :: results2)
      end
    | Conflict(shift_to, reduce_grammar) ->
      let err = Buffer.create 80 in
      let log str = Buffer.add_string err (str ^ "\n") in
      log "conflict found:";
      log ("current state " ^ string_of_int state ^ ":" ^ (show1 (List.nth parsingtable state)));
      log ("shift:" ^ show_ints shift_to ^
           ",reduce:" ^ show_ints reduce_grammar);
      List.iter (fun (to1: int) ->
        log (Printf.sprintf "shift to %d:%s" to1 (show1 (List.nth parsingtable to1)))
      ) shift_to;
      List.iter (fun (id: int) ->
        log (Printf.sprintf "reduce grammar %d:%s" id (show1 (List.nth parsingtable id)))
      ) reduce_grammar;
      log "parser cannot parse conflicted grammar";
      (Buffer.contents err, results)
    with Not_found ->
      (Printf.sprintf "parse failed: unexpected token:%s state: %d" token state, results) (* 未定義 *)
    end

let parse parser lexer input =
  let (error,result_stack) = actions parser (lexer input) [0] [] in
  if error <> "" then Printf.printf "%s\nparse failed.\n" error;
  if List.length result_stack <> 1 then Printf.printf "failed to construct tree.\n";
  List.nth result_stack 0

(* Parserを生成するためのファクトリ *)

let create language parsingtable =
  (getGrammar language, parsingtable, makeDefaultConstructor language)
