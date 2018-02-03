type e = Int of int | Add of e * e | Mul of e * e
type token = INT of int | ADD | MUL | LPAREN | RPAREN

(* Obj.magic *)
let lex = 
  [("expr",(["expr";"ADD";"expr"],function[e1;e2;e3]->Obj.magic(Add(Obj.magic e1,Obj.magic e3))));
   ("expr",(["INT"],function [i] -> Obj.magic(Int(Obj.magic i))));
   ("expr",(["LPAREN";"expr";"RPAREN"],function[_;e1;_]->e1));
  ]

(* Str.regexp *)
let _ =
  let tmp = Str.split (Str.regexp "/") "a/b/" in
  Printf.printf "%s\n" (String.concat "," tmp)

let _ =
  let v = "abc/" in
  let c = String.sub v (String.length v - 1) 1 in
  Printf.printf "%s\n" c

(* Str.regexp *)
let _ =
  let v = "\n\r\n\r  \taaa" in
  if Str.string_match (Str.regexp "\(\r\n\|\n\|\r\|[ \t]\)+") v 0 then
  Printf.printf "[%s]\n" (Str.matched_string v)
