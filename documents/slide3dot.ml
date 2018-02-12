(* usage : ocaml -w -8-40 str.cma parse.ml *)
let grammar=[|"E",["E";"+";"T"],"$1+$2";(*s0*)
              "E",["T"],        "$1";   (*s1*)
              "T",["T";"*";"N"],"$1*$2";(*s2*)
              "T",["N"],        "$1";   (*s3*)|]
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

let _ =
  Printf.printf "digraph G{graph [rankdir=LR];\n";
  Array.iteri(fun i (n,p,f) ->
    Printf.printf "g%d[label=\"g%d %d %s->%s{%s}\" shape=box];\n" i i (List.length p) n (String.concat "" p) f
  ) grammar;
  let gotos = Array.fold_left(fun gotos ls ->
    List.fold_left(fun gotos -> function
      | v,Accept -> ("end",v)::gotos
      | v,Goto j -> (Printf.sprintf "s%d" j,v)::gotos
      | v,Shift j -> (Printf.sprintf "s%d" j,v)::gotos
      | v,_ -> gotos
    ) gotos ls
  ) ["s0","S'"] table in
  Array.iteri(fun i _ ->
    let i = Printf.sprintf "s%d" i in
    Printf.printf "%s[label=\"%s %s\"];\n" i i (List.assoc i gotos)
  ) table;
  Printf.printf "end[label=\"end $\"];\n";

  Array.iteri(fun i m ->
    List.iter(function
    | (v,Accept) -> Printf.printf "s%d->end[label=\"%s\nAccept\"];\n" i v
    | (v,Goto j) -> Printf.printf "s%d->s%d[label=\"%s\nGoto\",color=blue];\n" i j v
    | (v,Shift j) -> Printf.printf "s%d->s%d[label=\"%s\nShift\"];\n" i j v
    | (v,Reduce j) -> Printf.printf "s%d->g%d[label=\"%s\nReduce\"];\n" i j v      
    ) m
  ) table;

  Printf.printf "}\n";
  ()
