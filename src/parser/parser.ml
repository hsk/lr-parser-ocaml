open Token
open Callback

(**
  * 構文解析器
  *)
module Make(C : CallbackController) = struct
module Make( D:sig
  val parsingtable: Parsingtable.parsingTable
end) = struct
include D
module L = Lexer.Make(C)

let rec drop rnum acc res =
  match (rnum, acc, res) with
  | (0, acc, res) -> (acc, res)
  | (n, acc, a :: res) -> drop(n - 1) (a :: acc) res
  | _ -> failwith("stack is empty")

(**
 * 構文解析する
 * states 現在読んでいる構文解析表の状態番号を置くスタック
 * results 解析中のASTノードを置くスタック
 *)
let rec actions inputs states results = 
  match (states, inputs) with
  | (_, []) -> ("", results)
  | (state::_, (token,value)::inp) ->
    begin try match List.assoc token (List.nth parsingtable state) with
        | Accept -> ("", results) (* 構文解析完了 *)
        | Shift(to1) -> actions inp (to1 :: states) (value :: results)
        | Reduce(grammar_id) -> (* reduceオペレーション *)
          let  Language.GrammarRule(ltoken,pattern,_) = List.nth L.grammar(grammar_id) in
          let rnum = List.length pattern in
          (* 右辺の記号の数だけスタックからポップする *)
          let (children, results2) = drop rnum [] results in
          let child = C.callGrammar(grammar_id, children) in
          (* 対応する規則の右辺の記号の数だけスタックからポップする *)
          let (_,((state2::_) as states2)) = drop rnum [] states in
          (* このままgotoオペレーションを行う *)
          begin match List.assoc ltoken (List.nth parsingtable state2) with
            | Goto(to1) -> actions inputs (to1 :: states2) (child :: results2) (* 必ず Gotoアクション *)
            | _ -> ("parse failed: goto operation expected after reduce operation", child :: results2)
          end
        | Conflict(shift_to, reduce_grammar) ->
          let err = Buffer.create 80 in
          let log = Buffer.add_string err in
          log "conflict found:\n";
          log ("current state " ^ string_of_int state ^ ":" ^ (Parsingtable.show1 (List.nth parsingtable state)) ^ "\n");
          log ("shift:" ^ Parsingtable.show_ints shift_to ^
                    ",reduce:" ^ Parsingtable.show_ints reduce_grammar ^ "\n");
          shift_to |> List.iter (fun (to1: int) ->
            log (Printf.sprintf "shift to %d:%s\n" to1 (Parsingtable.show1 (List.nth parsingtable to1)))
          );
          reduce_grammar |> List.iter (fun (id: int) ->
            log (Printf.sprintf "reduce grammar %d:%s\n" id (Parsingtable.show1 (List.nth parsingtable id)))
          );
          log "parser cannot parse conflicted grammar\n";
          (Buffer.contents err, results)
    with Not_found -> ("parse failed: unexpected token:" ^ token ^ " state:" ^ string_of_int state, results) (* 未定義 *)
    end

(**
  * 構文解析を実行する
  * @param {string} input 解析する入力文字列
  * @returns {any} 解析結果(返る結果はコントローラによって異なる)
  *)
let parse(input: string): any =
  (* parsingtableはconflictを含む以外は正しさが保証されているものと仮定する
     inputsは正しくないトークンが与えられる可能性を含む
     TODO: 詳細な例外処理、エラー検知 *)
  let (error,result_stack) = actions (L.exec input) [0] [] in
  if error <> "" then begin
    Printf.printf "%s\n" error;
    Printf.printf "parse failed.\n"
  end;
  if List.length result_stack <> 1 then Printf.printf "failed to construct tree.\n";
  List.nth result_stack 0


end
end
