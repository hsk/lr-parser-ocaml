:- expects_dialect(hprolog).
parser([T=V|TS],[S|SS],RS,R) :-
  table(Table),nth0(S,Table,Map),member(T=O,Map),!,parser(O,[T=V|TS],[S|SS],RS,R).
parser(accept,_,_,[R],R).
parser(shift(S),[_=V|TS],SS,RS,R) :- parser(TS,[S|SS],[V|RS],R).
parser(reduce(G),TS,SS,RS,R):-
  grammar(GS),nth0(G,GS,(T=Ptn/F)),length(Ptn,L),
  split_at(L,RS,Param,RS2),split_at(L,SS,_,[S|SS2]),
  table(Table),nth0(S,Table,Map),member(T=goto(S2),Map),call(F,Param,R2),
  parser(TS,[S2,S|SS2],[R2|RS2],R).
m(Ptn,In,R1,R2) :- re_replace(Ptn,'',In,S2),atom_string(R2,S2),atom_concat(R1,R2,In),!,R1\=''.
lexer('',Res,R) :- !,reverse([$ = $|Res],R).
lexer(Input,Res,R) :- lex(Lex),member(Token=Ptn/F,Lex),m(Ptn,Input,R1,R2),!,call(F,R1,R1_),lexer(R2,Res,Token=R1_, R).
lexer(Input,Res,white_space=_,R) :- !,lexer(Input,Res,R).
lexer(Input,Res,Token      =V,R) :- !,lexer(Input,[Token=V|Res],R).

id(A,A).
lex([
  white_space  = '^(\\r\\n|\\r|\\n|[ \\t])+' / id,
  n            = '^[0-9]+'                   / atom_number,
  +            = '^\\+'                      / id,
  *            = '^\\*'                      / id
]).

a1([A],A). add([A,_,B],R) :- R is A + B. mul([A,_,B],R) :- R is A * B.
grammar([
  e = [e,+,t] / add,
  e = [t]     / a1,
  t = [t,*,n] / mul,
  t = [n]     / a1
]).
table([
  [n=shift(2),                                       e=goto(1),t=goto(3)], % 0
  [           + =shift(4),              $ =accept                       ], % 1
  [           + =reduce(3),* =reduce(3),$ =reduce(3)                    ], % 2
  [           + =reduce(1),* =shift(5) ,$ =reduce(1)                    ], % 3
  [n=shift(2),                                                 t=goto(6)], % 4
  [n=shift(7)                                                           ], % 5
  [           + =reduce(0),* =shift(5) ,$ =reduce(0)                    ], % 6
  [           + =reduce(2),* =reduce(2),$ =reduce(2)                    ]  % 7
]).

parse(Input,R) :- lexer(Input,[],TS),!,parser(TS,[0],[],R).

:- parse('8', 8), parse('1+2', 3), parse('2*3+4', 10), parse('1+2*3', 7).
:- parse('1 + 2 * 3 + 4',R),writeln(R).
:- halt.
