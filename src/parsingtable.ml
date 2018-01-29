(**
  * 構文解析器の実行する命令群
  *)
type op =
| Shift of int (* Shiftオペレーション *)
| Reduce of int (* Reduceオペレーション *)
| Conflict of int list * int list (* Shift/Reduceコンフリクト *)
| Accept (* Acceptオペレーション *)
| Goto of int (* Gotoオペレーション *)

let show_ls ls = "[" ^ String.concat "," ls ^ "]"
let show_ints ls =show_ls (List.map string_of_int ls)

let show_op = function
  | Shift(i) -> Printf.sprintf "Shift(%d)" i
  | Reduce(i) -> Printf.sprintf "Reduce(%d)" i
  | Conflict(l,r) -> Printf.sprintf "Conflict(%s,%s)" (show_ints l) (show_ints r)
  | Accept -> Printf.sprintf "Accept"
  | Goto(i) -> Printf.sprintf "Goto(%d)" i

(**
  * 構文解析表
  *)
type parsingTable = (Token.token * op) list list

let show1(p: (Token.token * op) list):string =
  show_ls (List.map (fun(t,op)->Token.show t ^ " -> " ^ show_op op) p)

let show (p:parsingTable) = show_ls (List.map show1 p)

