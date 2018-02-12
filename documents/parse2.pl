:- expects_dialect(hprolog).
match(P,I,I1,I2) :- re_replace(P,'',I,S),atom_string(I2,S),atom_concat(I1,I2,I),I1\='',!.
lexer('',[$ = $]).
lexer(I,R)      :- lex(L),member(T=P/F,L),match(P,I,I1,I2),!,call(F,I1,I1_),lexer(T=I1_,I2,R).
lexer(ws=_,I,R) :- lexer(I,R). lexer(T,I,[T|R]) :- lexer(I,R).
parser([T=V|TS], [S|SS],RS, R) :- table(PT),nth0(S,PT,M),member(T=O,M),!,case(O,[T=V|TS],[S|SS],RS,R).
case(a   ,       _, _,[R],R).
case(s(S),[_=V|TS],SS,RS ,R) :- parser(TS,[S|SS],[V|RS],R).
case(g(S),[_  |TS],SS,RS ,R) :- parser(TS,[S|SS],RS,R).
case(r(G),      TS,SS,RS ,R) :- grammar(GS),nth0(G,GS,T=Ptn/F),length(Ptn,L),
                                split_at(L,SS,_,[S|SS2]),split_at(L,RS,RS1,RS2),call(F,RS1,R2),
                                parser([T=''|TS],[S|SS2],[R2|RS2],R).
lex([ ws = '^(\\r\\n|\\r|\\n| |\\t)+' / id,
      n  = '^[0-9]+'                  / atom_number,
      +  = '^\\+'                     / id,
      *  = '^\\*'                     / id           ]).
id(A,A). a1([A],A). add([A,_,B],R) :- R is A + B. mul([A,_,B],R) :- R is A * B.
grammar([ e = [e,+,t] / add,
          e = [t]     / a1,
          t = [t,*,n] / mul,
          t = [n]     / a1   ]).
table([ [n=s(2),                       e=g(1),t=g(3)],   % 0
        [       + =s(4),        $ =a                ],   % 1
        [       + =r(3),* =r(3),$ =r(3)             ],   % 2
        [       + =r(1),* =s(5),$ =r(1)             ],   % 3
        [n=s(2),                              t=g(6)],   % 4
        [n=s(7)                                     ],   % 5
        [       + =r(0),* =s(5),$ =r(0)             ],   % 6
        [       + =r(2),* =r(2),$ =r(2)             ] ]).% 7
parse(Input,R) :- lexer(Input,TS),!,parser(TS,[0],[],R).
:- parse('8', 8), parse('1+2', 3), parse('2*3+4', 10), parse('1+2*3', 7).
:- parse('1 + 2 * 3 + 4',R),writeln(R), halt.
