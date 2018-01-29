type e = Int of int | Add of e * e | Mul of e * e
type token = INT of int | ADD | MUL | LPAREN | RPAREN

let lex = 
  [("expr",(["expr";"ADD";"expr"],function[e1;e2;e3]->Obj.magic(Add(Obj.magic e1,Obj.magic e3))));
   ("expr",(["INT"],function [i] -> Obj.magic(Int(Obj.magic i))));
   ("expr",(["LPAREN";"expr";"RPAREN"],function[_;e1;_]->e1));
  ]