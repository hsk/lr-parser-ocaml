---
customTheme : "my-theme"
---

# LR-パーシングを勉強してみた

h_sakurai

---

### 要約

- LR-パーシングはやっぱり難しい
- 動く短いソースがあれば嬉しい
- 短いものを書いた
- 変数名が短すぎると意味が分かりずらくなる
  - 分かってしまえば短いほうがいい
  - 動くコードあるので書き直してみれば勉強になるはず

---

### とにかくソースを見るぞゴルァ

プログラムは大きく5つに別れます:

1. 文法定義
    - 字句定義の lex
    - 構文定義の grammar
2. 構文解析表 table
3. 字句解析器 lexer
4. 構文解析器 parser
5. メイン処理

---

### 文法定義

```
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
```

- type i はスタック内に異なるデータを含めるためのデータです。
- 字句の定義と、文法の定義をコールバック付きで定義できます。

---

### 構文解析表

```
type op = A | S of int | R of int | G of int
let table = [|["N",S 2;                        "E",G 1;"T",G 3];(*0*)
              [        "+",S 4;        "$",A  ;               ];(*1*)
              [        "+",R 3;"*",R 3;"$",R 3;               ];(*2*)
              [        "+",R 1;"*",S 5;"$",R 1;               ];(*3*)
              ["N",S 2;                                "T",G 6];(*4*)
              ["N",S 7;                                       ];(*5*)
              [        "+",R 0;"*",S 5;"$",R 0;               ];(*6*)
              [        "+",R 2;"*",R 2;"$",R 2;               ];(*7*)|]
```

- LRパーシングには構文解析表が別途必要になります。
- op はAccept,Shift,Reduce,Gotoをそれぞれ表します。
- 通常構文解析表はYaccなどのコンパイラコンパイラで自動生成します。
- 今回は、自前で用意しました。

---

### 字句解析器

```
let rec lexer = function "" -> ["$",E] | i ->
  let rule,_,f = List.find(fun(_,p,f)->
    Str.string_match(Str.regexp p) i 0
  ) lex in
  match Str.string_after i (Str.match_end()),rule with
  | n,"ws" -> lexer n
  | n,rule -> (rule,f (Str.matched_string i))::lexer n
let rec pop = function
  | 0,acc,s->acc,s
  | n,acc,a::s -> pop (n-1,a::acc,s)
```

- 文字列を受け取ってlexにstring_matchでマッチするものを見つける。
- match_endでマッチ文字列以降を取り出し
- ルール名が"ws"なら空白なので飛ばして再帰呼び出し
- それ以外はmatched_stringでマッチ文字列を取得後コールバック関数を読んでリストに加えます。
- pop は構文解析で使うのですがスタックをnで分割してリターン値と結果のスタックを返します

---

### 構文解析器

```
let rec parser((t,v)::ts,s::ss,rs) =
  dispatch(List.assoc t table.(s),(t,v)::ts,s::ss,rs)
and dispatch = function
  | A  ,        _, ss,r::_ -> r
  | S s,(_,v)::ts, ss,rs   -> parser(ts,s::ss,v::rs)
  | G s,(_,_)::ts, ss,rs   -> parser(ts,s::ss,   rs)
  | R g,       ts, ss,rs   ->
    let t,ptn,f = grammar.(g) in let len = List.length ptn in
    let _,ss = pop(len,[],ss) in let rs1,rs=pop(len,[],rs) in
    parser((t,E)::ts,ss,f rs1::rs)
```

- parserは入力リスト、ステータススタック、結果スタックを受け取って、命令を取り出し分配します。
- dispatch A は解析完了を意味し、結果スタックから値を返します。
- S はシフトで入力を１つ結果スタックに積み状態も変えます。
- G はGotoで入力を１つ捨てて状態を変えます。必ずR還元の後に現れます。
- R は還元で文法表を引き、パターン長分Pop、コールバック結果を結果につみ、文法名を入力にpush backします。

---

### メインプログラム

```
let show = function
  | I i -> Printf.sprintf "%d" i
  | E -> Printf.sprintf "error"
let parse input = parser(lexer lex input,[0],[])
let _ = assert(parse"1+2"=I 3); assert(parse"1+2*3"=I 7);
        assert(parse"2*3+4"=I 10);
        Printf.printf "%s\n" (show (parse "1 + 2*3 + 4"))
```

- showは結果の印字処理です
- parse 文字列を受け取ってparserに文法、構文解析表、字句解析結果と初期のステータススタック、結果スタックを渡して呼び出す関数です。
- 使い方は `assert(parse"2*3+4"=I 10);` のように使います。

---

### まとめ

- LR構文解析のプログラムを見てみました。
- 文法定義は字句定義の lex、構文定義の grammarがあり LR構文解析では構文解析表 table が必要なので自前で用意しました。
- 字句解析器 lexer と 構文解析器 parser は変数名が分かりづらいかも知れませんが短く定義できました。
- メイン処理では様々な入力に対してテストし、結果を表示してみました。
- LR構文解析のプログラム自体はとても簡単に書けました。

---

### LR構文解析とは

- 上昇型の表を使って構文解析する手法です
- 仕組み自体はやっぱり難しいです
- しかし、パーサ自体のプログラムは簡単です
- 表を作る作業はなかなか複雑になります
- しかし、表さえあればプログラム自体は簡単なのです
