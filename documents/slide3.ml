(* usage : ocaml -w -8-40 str.cma parse.ml *)
type i = I of int | E
let lex =   [ "ws", "[ \\r\\n\\t]+", (fun i->E);
              "N",  "[1-9][0-9]*",   (fun i-> I(int_of_string i));
              "+",  "+",             (fun i->E);
              "*",  "*",             (fun i->E);                   ]
let grammar=[|"E",["E";"+";"T"],(fun[I a;_;I b]->I(a+b));(*s0*)
              "E",["T"],        (fun[a]    ->a);         (*s1*)
              "T",["T";"*";"N"],(fun[I a;_;I b]->I(a*b));(*s2*)
              "T",["N"],        (fun[a]    ->a);         (*s3*)|]
type op = Accept | Shift of int | Reduce of int | Goto of int
let table = [|
(*0*)["N",Shift 2;                                     "E",Goto 1;"T",Goto 3];
(*1*)[           "+",Shift  4;             "$",Accept                       ];
(*2*)[           "+",Reduce 3;"*",Reduce 3;"$",Reduce 3                     ];
(*3*)[           "+",Reduce 1;"*",Shift  5;"$",Reduce 1                     ];
(*4*)["N",Shift 2;                                                "T",Goto 6];
(*5*)["N",Shift 7                                                           ];
(*6*)[           "+",Reduce 0;"*",Shift  5;"$",Reduce 0                     ];
(*7*)[           "+",Reduce 2;"*",Reduce 2;"$",Reduce 2                     ];
|]
let rec lexer = function "" -> ["$",E] | i ->
  let rule,_,f = List.find(fun(_,p,f)->
    Str.string_match(Str.regexp p) i 0
  ) lex in
  match Str.string_after i (Str.match_end()),rule with
  n,"ws" -> lexer n | n,_ -> (rule,f (Str.matched_string i))::lexer n

let rec pop = function
  | 0,acc,s->acc,s
  | n,acc,a::s -> pop (n-1,a::acc,s)
let rec parser((t,v)::ts,s::ss,rs) =
  dispatch(List.assoc t table.(s),(t,v)::ts,s::ss,rs)
and dispatch = function
  | Accept  ,        _, ss,r::_ -> r
  | Shift  s,(_,v)::ts, ss,rs   -> parser(ts,s::ss,v::rs)
  | Goto   s,(_,_)::ts, ss,rs   -> parser(ts,s::ss,   rs)
  | Reduce g,       ts, ss,rs   ->
    let t,ptn,f = grammar.(g) in let len = List.length ptn in
    let _,ss = pop(len,[],ss) in let rs1,rs=pop(len,[],rs) in
    parser((t,E)::ts,ss,f rs1::rs)
let parse input = parser(lexer input,[0],[])
let show = function
  | I i -> Printf.sprintf "%d" i
  | E -> Printf.sprintf "error"
let _ = assert(parse"1+2"=I 3); assert(parse"1+2*3"=I 7);
        assert(parse"2*3+4"=I 10); assert(parse "1 + 2*3 + 4"=I 11);
        Printf.printf "%s\n" (show (parse "1 + 2*3 + 4"))
