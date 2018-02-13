(* usage : ocaml -w -8-40 str.cma parse.ml *)
type i = I of int | E of string
let lex =   [ "ws", "[ \\r\\n\\t]+", (fun i->E "");
              "N",  "[1-9][0-9]*",   (fun i-> I(int_of_string i));
              "+",  "+",             (fun i->E "+");
              "*",  "*",             (fun i->E "*");              ]
let grammar=[|"E",["E";"+";"T"],(fun[I a;_;I b]->I(a+b)),"$1+$2";(*s0*)
              "E",["T"],        (fun[a]    ->a)         ,"$1"   ;(*s1*)
              "T",["T";"*";"N"],(fun[I a;_;I b]->I(a*b)),"$1*$2";(*s2*)
              "T",["N"],        (fun[a]    ->a)         ,"$1"   ;(*s3*)|]
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
module Log = struct
  let exec cmd =
    let env = Unix.environment () in
    let cmd_out, cmd_in, cmd_err = Unix.open_process_full cmd env in
    close_out cmd_in;
    let cmd_out_descr = Unix.descr_of_in_channel cmd_out in
    let cmd_err_descr = Unix.descr_of_in_channel cmd_err in
    let selector = ref [cmd_err_descr; cmd_out_descr] in
    let errs = ref "" in
    let outs = ref "" in
    while !selector <> [] do
      let can_read, _, _ = Unix.select !selector [] [] 1.0 in
      List.iter
        (fun fh ->
          try
            if fh = cmd_err_descr
            then
              errs := !errs ^ (input_line cmd_err) ^ "\n"
            else
              outs := !outs ^ (input_line cmd_out) ^ "\n"
          with End_of_file ->
            selector := List.filter (fun fh' -> fh <> fh') !selector)
        can_read
    done;
    let code = match Unix.close_process_full (cmd_out, cmd_in, cmd_err) with
    | Unix.WEXITED(c) -> c
    | Unix.WSIGNALED(c) ->c
    | Unix.WSTOPPED(c) -> c in
    (!outs,!errs,string_of_int code)

  let logimg name name2 prm1 fp =
    let color i name =
      if i=name then ",fontcolor=blue,color=blue,fillcolor=\"#88ffff\", style=filled" else ""
    in
    Printf.fprintf fp "digraph G{graph [rankdir=LR];\n";
    Array.iteri(fun i (n,p,_,f) ->
      let i = Printf.sprintf "g%d" i in
      Printf.fprintf fp "%s[label=\"%s %d %s->%s{%s}\" shape=box%s];\n" i i (List.length p) n (String.concat "" p) f (color i name2)
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
      Printf.fprintf fp "%s[label=\"%s %s\"%s];\n" i i (List.assoc i gotos) (color i name)
    ) table;
    Printf.fprintf fp "end[label=\"end $\"%s];\n" (color "end" name);
    let color prm = if Some prm=prm1 then ",color=blue,fontcolor=blue" else "" in
    Array.iteri(fun i m ->
      List.iter(function
      | (v,(Accept as op)) -> Printf.fprintf fp "s%d->end[label=\"%s\nAccept\"%s];\n" i v (color (v,op, i))
      | (v,(Goto j as op)) -> Printf.fprintf fp "s%d->s%d[label=\"%s\nGoto\"%s];\n" i j v (color (v,op, i))
      | (v,(Shift j as op)) -> Printf.fprintf fp "s%d->s%d[label=\"%s\nShift\"%s];\n" i j v (color (v,op, i))
      | (v,(Reduce j as op)) -> Printf.fprintf fp "s%d->g%d[label=\"%s\nReduce\"%s,dir=none];\n" i j v (color (v,op, i))
      ) m
    ) table;
    Printf.fprintf fp "}\n";
    ()

  let o = stdout
  let escape input = (Str.global_replace (Str.regexp "[*+]") "\\\\\\0" input)
  let show = function
    | I i -> Printf.sprintf "%d" i
    | E s -> Printf.sprintf "%s" s
  let show_op = function
    | Accept -> Printf.sprintf "Accept"
    | Shift i -> Printf.sprintf "Shift s%d" i
    | Goto i -> Printf.sprintf "Goto s%d" i
    | Reduce i -> Printf.sprintf "Reduce g%d" i
  let logStart () =
    Printf.fprintf o "---\ntransition: none\n---\n\n"
  let _ = logStart ()
  let logParseStart input =
    Printf.fprintf o "# %s\n\n--\n\n" (escape input)
  let logParseResult input r =
    Printf.fprintf o "# result %s = %s\n\n---\n\n" (escape input) (show r)
  let log1 comment name name2 option op ts ss rs fname =
    Printf.fprintf o "## %s\n\n%!" (show_op op);
    Printf.fprintf o "    inputs %s %s\n" (String.concat " " (List.map(fun(a,b)->show b) ts)) comment;
    Printf.fprintf o "    status %s\n" (String.concat " " (List.map string_of_int ss));
    Printf.fprintf o "    results %s\n" (String.concat " " (List.map show rs));
    Printf.fprintf o "![fig](images/%s.png)\n\n%!" fname;
    Printf.fprintf o "\n--\n\n%!";
    let fp = open_out "a.dot" in logimg name name2 option fp; close_out fp;
    exec ("dot -Tpng a.dot -o images/"^fname^".png") |> ignore;
    ()
  let log(op,((t,v)::_ as ts),s::ss,rs) =
    let name = Printf.sprintf "s%d" s in
    log1 "" name "" None op  ts (s::ss) rs name;
    (match op with
    | Reduce g ->
      let name2 = Printf.sprintf "g%d" g in
      let fname = Printf.sprintf "g%d-%d" g (int_of_char t.[0]) in
      let (a,b,_,c)=grammar.(g) in
      log1 (Printf.sprintf "文法g%dを見て、%d個Pop、{%s}を結果にpush、文法名%sを入力にpush" g (List.length b) c a)
        name name2 (Some (t,op,s)) op ts (s::ss) rs fname;
    | Accept ->
      let fname = Printf.sprintf "s%d-%d" s (int_of_char t.[0]) in
      log1 "アクセプト" name "" (Some (t,op,s)) op ts (s::ss) rs fname;
      log1 (Printf.sprintf "結果 %s です" (show (List.nth rs 0))) "end" "" None op  ts (s::ss) rs "end";
    | Goto p ->
      let fname = Printf.sprintf "s%d-%d" s (int_of_char t.[0]) in
      log1 (Printf.sprintf "ステータスに%dをpush,入力%sを捨てる" p (show v)) name "" (Some (t,op,s)) op ts (s::ss) rs fname;
    | Shift p ->
      let fname = Printf.sprintf "s%d-%d" s (int_of_char t.[0]) in
      log1 (Printf.sprintf "ステータスに%dをpush 入力%sを結果に移動" p (show v)) name "" (Some (t,op,s)) op ts (s::ss) rs fname;
    );
    ()
end
let rec lexer = function "" -> ["$",E "$"] | i ->
  let rule,_,f = List.find(fun(_,p,f)->
    Str.string_match(Str.regexp p) i 0
  ) lex in
  match Str.string_after i (Str.match_end()),rule with
  n,"ws" -> lexer n | n,_ -> (rule,f (Str.matched_string i))::lexer n

let rec pop = function
  | 0,acc,s->acc,s
  | n,acc,a::s -> pop (n-1,a::acc,s)

let rec parser((t,v)::ts,s::ss,rs) =
  let op = List.assoc t table.(s) in
  Log.log(op, (t,v)::ts,s::ss,rs);
  match(op,(t,v)::ts,s::ss,rs) with
  | Accept  ,        _, ss,r::_ -> r
  | Shift  s,(_,v)::ts, ss,rs   -> parser(ts,s::ss,v::rs)
  | Goto   s,(_,_)::ts, ss,rs   -> parser(ts,s::ss,   rs)
  | Reduce g,       ts, ss,rs   ->
    let t,ptn,f,_ = grammar.(g) in let len = List.length ptn in
    let _,ss = pop(len,[],ss) in let rs1,rs=pop(len,[],rs) in
    parser((t,E t)::ts,ss,f rs1::rs)
let parse input =
  Log.logParseStart input;
  let r = parser(lexer input,[0],[]) in
  Log.logParseResult input r;
  r
let _ = assert(parse "1" =I 1);
        assert(parse "2*3" =I 6); assert(parse"2*3*4"=I 24);
        assert(parse "1+2" =I 3); assert(parse "1+2+3" =I 6);
        assert(parse "1+2*3" =I 7); assert(parse "2*3+4" =I 10);
        ()
