open Token
open Language

(* 構文解析器の実行する命令群 *)
type op =
  | Accept
  | Shift of int
  | Reduce of int
  | Goto of int
  | Conflict of int list * int list (* Shift/Reduceコンフリクト *)

let show_ls ls = "[" ^ String.concat ";" ls ^ "]"
let show_ints ls =show_ls (List.map string_of_int ls)
let show_op = function
  | Accept -> Printf.sprintf "Accept"
  | Shift(i) -> Printf.sprintf "Shift(%d)" i
  | Reduce(i) -> Printf.sprintf "Reduce(%d)" i
  | Goto(i) -> Printf.sprintf "Goto(%d)" i
  | Conflict(l,r) -> Printf.sprintf "Conflict(%s,%s)" (show_ints l) (show_ints r)

(* 構文解析表 *)
type parsingTable = (Token.token * op) list list

let show1(p: (Token.token * op) list):string =
  show_ls (List.map (fun(t,op)->Printf.sprintf "%S,%s" t (show_op op)) p)

let show (p:parsingTable) = show_ls (List.map show1 p)

(* 構文解析器 *)
type parserCallback = grammarDefinition -> (int * any list) -> any
type parser = (grammarDefinition * parsingTable * parserCallback)

let rec drop = function
  | (0, acc, res) -> (acc, res)
  | (n, acc, a :: res) -> drop (n - 1, a::acc, res)
  | _ -> failwith "stack is empty"

let rec pop2 num stack = drop (num,[], stack)
let rec pop num stack = let (_,stack) = pop2 num stack in stack

let debug_mode = ref false

let debug_out str = if !debug_mode then Printf.printf "%s\n%!" str
let log fmt = Printf.kprintf (fun str -> debug_out str) fmt
let logState(i,s,r) =
  log "%s %s %s" (show_tokeninputs i) (show_ls (List.map string_of_int s)) (show_ls r)
let logOp op = log "%s" (show_op op); op
(* 構文解析ステートマシン *)
(* states 現在読んでいる構文解析表の状態番号を置くスタック *)
(* results 解析中のASTノードを置くスタック *)
let rec automaton parser inputs states results =
  logState(inputs,states,results);
  match (inputs,parser,states) with
  | ([], _, _) -> ("", results)
  | ((token,value)::inp,(grammar,parsingtable,callback), state::_) ->
    begin try match logOp(List.assoc token (List.nth parsingtable state)) with
    | Accept -> ("", results) (* 完了 *)
    | Shift(to1) -> automaton parser inp (to1 :: states) (value :: results)
    | Reduce(grammar_id) ->
      let (ltoken,pattern,_) = List.nth grammar grammar_id in
      let rnum = List.length pattern in
      let (children, results) = pop2 rnum results in  (* 右辺の記号の数だけポップ *)
      let ((state::_) as states) = pop rnum states in (* 対応する規則の右辺の記号の数だけポップ *)
      let results = callback(grammar_id, children) :: results in (* callback 実行 *)
      logState(inputs,states,results);
      (* 次は必ず Goto *)
      begin match logOp(List.assoc ltoken (List.nth parsingtable state)) with
      | Goto(to1) -> automaton parser inputs (to1 :: states) results
      | _ -> ("parse failed: goto operation expected after reduce operation", results)
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

let parse grammar parsingtable callback (lexer:lexer) input =
  let (error,result_stack) = automaton (grammar,parsingtable,callback) (lexer input) [0] [] in
  if error <> "" then Printf.printf "%s\nparse failed.\n" error;
  if List.length result_stack <> 1 then Printf.printf "failed to construct tree.\n";
  List.nth result_stack 0

(* Parserを生成するためのファクトリ *)
let create grammar (_,parsingtable) =
  parse grammar parsingtable (fun (id, children) ->
    match List.nth grammar id with
    | (ltoken,_,Some(callback)) -> callback(children, ltoken)
    | _ -> List.nth children 0
  )
