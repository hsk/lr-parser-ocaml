(* usage : ocaml -w -8-40 str.cma parse.ml *)
type i = I of int | E
let rec lexer lex = function "" -> ["$",E] | i ->
  let t,_,f = List.find(fun(t,p,f)->Str.string_match(Str.regexp p) i 0)lex in
  match f (Str.matched_string i),Str.string_after i (Str.match_end()),t with
  r,i,"ws" -> lexer lex i | r,i,_ -> (t,r)::lexer lex i
type op = A | S of int | R of int | G of int
let rec pop = function 0,acc,s->acc,s | n,acc,a::s -> pop (n-1,a::acc,s)
let rec parser(gr,pt,(t,v)::ts,s::ss,rs) =
  dispatch(List.assoc t pt.(s),gr,pt,(t,v)::ts,s::ss,rs)
and dispatch = function
  | A  ,gr,pt,        _, ss,r::_ -> r
  | S s,gr,pt,(_,v)::ts, ss,rs   -> parser(gr,pt,ts,s::ss,v::rs)
  | G s,gr,pt,(_,_)::ts, ss,rs   -> parser(gr,pt,ts,s::ss,   rs)
  | R g,gr,pt,       ts, ss,rs   ->
    let t,ptn,f = gr.(g)        in let len = List.length ptn in
    let _,ss = pop(len,[],ss)   in let rs1,rs=pop(len,[],rs) in
    parser(gr,pt,(t,E)::ts,ss,f rs1::rs)
  
let lex =   [ "ws", "[ \\r\\n\\t]+", (fun i->E);
              "N",  "[1-9][0-9]*",   (fun i-> I(int_of_string i));
              "+",  "+",             (fun i->E);
              "*",  "*",             (fun i->E);                   ]
let grammar=[|"E",["E";"+";"T"],(fun[I a;_;I b]->I(a+b));(*s0*)
              "E",["T"],        (fun[a]    ->a);         (*s1*)
              "T",["T";"*";"N"],(fun[I a;_;I b]->I(a*b));(*s2*)
              "T",["N"],        (fun[a]    ->a);         (*s3*)|]
let table = [|["N",S 2;                        "E",G 1;"T",G 3];(*0*)
              [        "+",S 4;        "$",A  ;               ];(*1*)
              [        "+",R 3;"*",R 3;"$",R 3;               ];(*2*)
              [        "+",R 1;"*",S 5;"$",R 1;               ];(*3*)
              ["N",S 2;                                "T",G 6];(*4*)
              ["N",S 7;                                       ];(*5*)
              [        "+",R 0;"*",S 5;"$",R 0;               ];(*6*)
              [        "+",R 2;"*",R 2;"$",R 2;               ];(*7*)|]
let parse input = parser(grammar, table, lexer lex input,[0],[])
let _ = assert(parse"1+2"=I 3); assert(parse"1+2*3"=I 7);
        assert(parse"2*3+4"=I 10); assert(parse "1 + 2*3 + 4"=I 11)
