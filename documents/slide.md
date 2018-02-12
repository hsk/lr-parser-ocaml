---
customTheme : "my-theme"
---

## 900行LALR1パーサジェネレータ on OCaml

h_sakurai

---

### パーサを詳しく見る

```
let rec parser(gr,pt,(t,v)::ts,s::ss,rs) =
  dispatch(List.assoc t pt.(s),gr,pt,(t,v)::ts,s::ss,rs)
and dispatch = function
  | A  ,gr,pt,        _,ss,r::_-> r (* アクセプト 完了 *)
  | S s,gr,pt,(_,v)::ts,ss,rs  ->parser(gr,pt,ts,s::ss,v::rs)
  | G s,gr,pt,(_,_)::ts,ss,rs  ->parser(gr,pt,ts,s::ss,   rs)
  | R g,gr,pt,       ts,ss,rs  ->
    let t,ptn,f=gr.(g)      in let len=List.length ptn in
    let _,ss=pop(len,[],ss) in let rs1,rs=pop(len,[],rs)in
    parser(gr,pt,(t,E)::ts,ss,f rs1::rs)
```

- parserはssのトップをみて命令を取出し分配する
- dispatchは各命令を実行します。
- S シフト,G Gotoは状態を変えSは入力を結果に
- R リデュースは文法の長さだけpopして結果をコールバックしてrsに加え、字句に文法名をpushback。

---

### 今日のお話

1. LR構文解析は難しい
2. OCamlへの移植
3. 分かりやすい解説

---

### 今日のお話

1. **LR構文解析は難しい**
2. OCamlへの移植
3. 分かりやすい解説

---

### LR構文解析は難しい

- 仕組みがよくわからない
- 作れそうにない
- 分かりやすい解説がない

---

### 分れば簡単らしい

- 作ったことある人は簡単だと言っている
- 分かっている人にとっては簡単らしい
- しかし、分からない人には難しいんだよなぁ

---

### 本当に、簡単なのかな？

- パーサコンビネータは分かったら簡単だった
- 正規表現のオートマトンも分かったら簡単だった
- LR構文解析も簡単なのだろう

---

### 解説記事が今はある

- LR構文解析の分かりやすい図解はある
- 神戸大学の人のTypeScriptで作ったLR構文解析とその解説も分かりやすい
- 移植してみよう

---

### 今日のお話

1. LR構文解析は難しい
2. **OCamlへの移植**
3. 分かりやすい解説

---

### 成果物

- 字句解析100行
- 構文解析100行
- パーサジェネレータは600行
- 合計 800行
- テスト 1000行
- 全体で1800行程度のプログラムを作りました。
- 1ソースにまとめて900行で動かせました。

---

### 移植の計画

- 解説記事をみつつソースを理解する
- 比較的TypeScriptに近いScalaに移植する
- そのあと、OCamlに移植する
- リファクタリングする

---

### Scalaへの移植

- ScalaはOOPとFPのハイブリット言語
- 移植は結構楽だった
- Caseクラスに書き換える
- Anyにする
- とにかくテストを通す

---

### 次の目標

- 関数的に書き換える
- クラスはすべてcase Class にする
- メソッドはシングルトンの関数に書き換えてOCamlのモジュールのように
- テストがあるから安心

---

### 出来た

- 問題なく動くようになった
- IntelliJはデバッガ動かせて便利だった
- しかし、貧弱な環境では重かった
- VS Code + SBT でも、貧弱な環境では重かった
- オブジェクト指向的なコードは残っている

---

### OCaml への移植

- Scalaより軽くなるはず
- OCaml の O はオブジェクト。だが使わない
- できるだけ破壊的変更はなくしたいが
- 破壊的変更は必要なら使う
- とにかくまず移植

---

### Any型をどうしよう問題

- Obj.magic を使う
- type any=string
- 躊躇なく let a = (Obj.magic 1 : any)
- OCamlはプリミティブとポインタを混在可能
- ボックス化のめんどくささとかGCの不安はない

---

### 移植結果

- OCaml 軽い。ビルドテストはすぐ終わる
- かなり関数的に書き換えたのでエンバグした
  - Scalaに逆移植してデバッグが楽だった

---

### 分かりやすくする

- 移植は出来たが分かりづらい
- 何が起こっているのか作者なのにわからない
- 徐々にリファクタリング

---

### 字句解析

- 単純化した
- 独立して動くようにした
- テストをつけた

---

### 構文解析

- 独立して動く
- ステートマシンとして表現
- スタックはリストを使ってパターンマッチ
- 末尾最適化されていて高速
- 構文解析表付きの小さい動くサンプル
- 動きにReduce,Gotoの表の引き方も付けた
- AST自動生成機能は別なディレクトリに移動

---

### パーサジェネレータ

- 字句解析や構文解析と分離
- 高速性よりわかりやすさを優先
- 配列をあえてリストに
- Map,Setモジュールなどを使って単純化
- LALR1のアルゴリズムを分離
- たらい回しにしないように関数を移動
- for,whileループはなくした。複雑化したかも

---

### 今日のお話

1. LR構文解析は難しい
2. OCamlへの移植
3. **分かりやすい解説**

---

### 分かりやすい解説

- 本当に分かりやすいかどうかはわからりません。
- しかし、分かりやすいと思う話をします。

---

### パーサ

```
let rec parser(gr,pt,(t,v)::ts,s::ss,rs) =
  dispatch(List.assoc t pt.(s),gr,pt,(t,v)::ts,s::ss,rs)
and dispatch = function
  | A  ,gr,pt,        _,ss,r::_-> r
  | S s,gr,pt,(_,v)::ts,ss,rs  ->parser(gr,pt,ts,s::ss,v::rs)
  | G s,gr,pt,(_,_)::ts,ss,rs  ->parser(gr,pt,ts,s::ss,   rs)
  | R g,gr,pt,       ts,ss,rs  ->
    let t,ptn,f=gr.(g)      in let len=List.length ptn in
    let _,ss=pop(len,[],ss) in let rs1,rs=pop(len,[],rs)in
    parser(gr,pt,(t,E)::ts,ss,f rs1::rs)
```

- 10行足らずで書けて簡単です。

---

### 字句解析器

- <dup>これも１０行でかけて簡単です。</dup>

```ocaml
type i = I of int | E
let rec lexer lex = function
  | "" -> ["$",E]
  | i ->
    let t,_,f = List.find(fun(t,p,f)->
      Str.string_match(Str.regexp p) i 0
    ) lex in
    match t, Str.string_after i (Str.match_end()) with
    | "ws", i -> lexer lex i
    | _   , i -> (t,f (Str.matched_string i))::lexer lex i
```

---

### 使い方 字句定義と、構文定義、メイン処理

```
type i = I of int | E (* 型合わせのためのデータ構造 *)
(* 字句定義 *)
let lex = ["ws","[ \\r\\n\\t]+",(fun i->E);
           "N", "[0-9]+",       (fun i->I(int_of_string i));
           "+", "+",            (fun i->E);
           "*", "*",            (fun i->E);                ]
(* 構文定義 *)
let grammar= [|
  "E",["E";"+";"T"],(fun[I a;_;I b]->I(a+b));(*s0*)
  "E",["T"],        (fun[a]    ->a);         (*s1*)
  "T",["T";"*";"N"],(fun[I a;_;I b]->I(a*b));(*s2*)
  "T",["N"],        (fun[a]    ->a);         (*s3*)|]
let parse inp = parser(grammar, table, lexer lex inp,[0],[])
let _ = assert(parse"1+2*3+4"=I 11)
```

こうやって使えます。

---

### 構文解析表

```
let table = [|
  ["N",S 2;                        "E",G 1;"T",G 3];(*0*)
  [        "+",S 4;        "$",A  ;               ];(*1*)
  [        "+",R 3;"*",R 3;"$",R 3;               ];(*2*)
  [        "+",R 1;"*",S 5;"$",R 1;               ];(*3*)
  ["N",S 2;                                "T",G 6];(*4*)
  ["N",S 7;                                       ];(*5*)
  [        "+",R 0;"*",S 5;"$",R 0;               ];(*6*)
  [        "+",R 2;"*",R 2;"$",R 2;               ];(*7*)|]
```

- LR構文解析にはこのような表が必要になります。
- この表は通常Yaccが生成したものを使います。

---

#### 字句解析器を詳しく見ます

- lexerは字句定義と文字列を字句リストに変換
- Strモジュールで正規表現を処理します。

```ocaml
type i = I of int | E
let rec lexer lex = function
  | "" -> ["$",E] (* 文字列終了でEOF($)を返却 *)
  | i -> (* ↓マッチするルールを検索して名前tと関数fを取得 *)
    let t,_,f = List.find(fun(t,p,f)->
      Str.string_match(Str.regexp p) i 0
    ) lex in (* ↓ 後続の文字列を取得 *)
    match t, Str.string_after i (Str.match_end()) with
    | "ws", i -> lexer lex i (* wsは空白なので飛ばす *)
    | _   , i -> (t,f (Str.matched_string i))::lexer lex i
                 (*↑マッチ文字列取得後fで変換し、先頭に*)
```

---

#### パーサの命令

```
type op = A | S of int | R of int | G of int
```

- A がアクセプト 解析終了
- S がシフト 状態遷移します。関数呼出しに似ている
- R がリデュース 関数のleave処理に似ている
- G がGoto 関数のリターン処理に似ている

```
let rec pop=function (* n 番目でリストを２つに分離 *)
  | 0,ls,s -> ls,s | n,ls,a::s -> pop(n-1,a::ls,s)
```

- immutableなPOP関数も作っておきます。

---

### パーサを詳しく見る

```
let rec parser(gr,pt,(t,v)::ts,s::ss,rs) =
  dispatch(List.assoc t pt.(s),gr,pt,(t,v)::ts,s::ss,rs)
and dispatch = function
  | A  ,gr,pt,        _,ss,r::_-> r (* アクセプト 完了 *)
  | S s,gr,pt,(_,v)::ts,ss,rs  ->parser(gr,pt,ts,s::ss,v::rs)
  | G s,gr,pt,(_,_)::ts,ss,rs  ->parser(gr,pt,ts,s::ss,   rs)
  | R g,gr,pt,       ts,ss,rs  ->
    let t,ptn,f=gr.(g)      in let len=List.length ptn in
    let _,ss=pop(len,[],ss) in let rs1,rs=pop(len,[],rs)in
    parser(gr,pt,(t,E)::ts,ss,f rs1::rs)
```

- parserはssのトップをみて命令を取出し分配する
- dispatchは各命令を実行します。
- S シフト,G Gotoは状態を変えSは入力を結果に
- R リデュースは文法の長さだけpopして結果をコールバックしてrsに加え、字句に文法名をpushback。

---

### LR 構文解析

```
構文解析表                                    
   N     +       *       $      E     T     文法
s0 Shift2                       Goto1 Goto3 g0 E->E+T{$1+$2}
s1       Shift 4         Accept             g1 E->T  {$1}
s2       Reduce3 Reduce3 Reduce3            g2 T->T*N{$1*$2}
s3       Reduce1 Shift 5 Reduce1            g3 T->N  {$1}
s4 Shift2                       Goto6
s5 Shift7                         
s6       Reduce0 Shift 5 Reduce0
s7       Reduce2 Reduce2 Reduce2
```

- LR構文解析は構文解析表を使って構文解析します。

---

### LR 構文解析器

- LR構文解析器は、構文解析表と字句解析の関数を受け取って構文解析を行います。
- 字句解析の関数は文字列を受け取って字句解析結果を返す関数であれば何でも良いので字句解析の実装に依存しません。

---

### ファイル一覧

- language.ml 言語定義
- parser.ml LR構文解析器
- test/calc_test.ml 言語定義パーサのテスト
- Makefile メイクファイル

---

## 構文解析器の動作

- LR構文解析の構文解析器はオートマトンです。
- 5つの命令があります:

  ```
  type op = Accept | Shift of int | Reduce of int
    | Goto of int | Conflict of int list * int list
  ```

- それぞれ解析終了, シフト, 還元, 状態遷移, パーサが衝突を起こした場合の動作を表します。
- シフトは関数呼び出し、リデュースは関数リターンに似ています。

---

### オートマトンのプログラムの最初の部分:

```
let rec automaton parser inputs states results = 
  match (parser, states, inputs) with
  | (_, _, []) -> ("", results)
  | ((grammar,table,callback), state::_,
   (token,value)::inp) ->
    begin try match List.assoc token
      (List.nth table state) with
```

- automaton は parserとinputs(入力リスト)とstates(状態スタック)とresults(結果スタック)を持ちます。
- parserの中身はgrammar(文法)とtable(構文解析表)とcallbackです。
- 入力リストがなければ結果を返し、あればその入力に従って何かしらの動作を行います。

---


### 各命令の動作

- 状態スタックのトップと入力のトップを見て構文解析表のステートとトークンに対応する命令を取り出して実行します。
- ただし、Goto命令はReduce命令に対応した文法の文法名で検索します。

---

### Accept

```ocaml
| Accept -> ("", results) (* 完了 *)
```

本当に何もしません。結果を返すだけです。

---

### Shift

```
| Shift(to1) ->
  automaton parser inp (to1 :: states) (value :: results)
```

- ステータススタックにシフト先のステータスをpushし、
- 結果スタックに入力値をpushするだけです。

---

### Reduce

```
| Reduce(grammar_id) ->
  (* 文法表を参照 *)
  let (ltoken,pattern,_) = List.nth grammar grammar_id in
  (* 右辺の記号の数だけポップ *)
  let rnum = List.length pattern in
  let (children, results) = splitAt rnum results in
  let ((state::_) as states) = pop rnum states in
  (* callbackを実行して結果をresultにpush *)
  let result = callback(grammar_id, children) :: result in
```

- 表を参照して右辺の記号数だけPopします。
- コールバックを実行した後、後続のGoto命令を実行します。

---

### Goto
```
  (* Reduceの後は必ずGoto *)
  begin match List.assoc ltoken (List.nth table state) with
  | Goto(to1) -> (* ステータスにpush *)
    automaton parser inputs (to1 :: states) results
  | _ -> ("parse failed: goto opera...", results) (* エラー *)
  end
```

- 動作内容は単純にstatusにpushするだけです。
- 他の命令と違って、statusのトップとReduce命令の文法名から命令が呼び出されます。

---

## Conflict

- Conflictはエラー処理をするだけなので省略します。

---

## 実際の動作

以下に文法と構文解析表と `8`、`1 + 2`、`1 + 2 * 3` の動作を示します。ここで、`($)` は`EOF` を表します。

    文法
    g0 E -> E + T         { $1 + $2 }
    g1 E -> T             { $1 }
    g2 T -> T * N         { $1 * $2 }
    g3 T -> N             { $1 }
    構文解析表
    s0  N : Shift 2                                            E : Goto 1  T : Goto 3
    s1               + : Shift  4                $ : Accept                          
    s2               + : Reduce 3  * : Reduce 3  $ : Reduce 3                        
    s3               + : Reduce 1  * : Shift  5  $ : Reduce 1                        
    s4  N : Shift 2                                                        T : Goto 6
    s5  N : Shift 7                                                                  
    s6               + : Reduce 0  * : Shift  5  $ : Reduce 0                        
    s7               + : Reduce 2  * : Reduce 2  $ : Reduce 2                        
              in    st   res 動作                                     次の命令
              8 $   0        開始時はstに0をセット,                   inのtop Nとstのtop 0で表s0を引いて
    Shift  2  $     2 0  8   stに2をpush,resにinの8をpush,            inのtop $とs2から
    Reduce 3  $     0    8   g3の右辺数1だけpop,callback値をresにpush,g3の左辺Tとs0から
    Goto   3  $     3 0  8   stに3をpush,       ↑$1=8 {$1}=8         inのtop $とs3から
    Reduce 1  $     0    8   g1の右辺数1だけpop,callback値をresにpush,g1の左辺Eとs0から
    Goto   1  $     1 0  8   stに1をpush,       ↑$1=8 {$1}=8         inのtop $とs1から
    Accept    $     1 0  8   完了

    文法
    g0 E -> E + T         { $1 + $2 }
    g1 E -> T             { $1 }
    g2 T -> T * N         { $1 * $2 }
    g3 T -> N             { $1 }
    構文解析表
    s0  N : Shift 2                                            E : Goto 1  T : Goto 3
    s1               + : Shift  4                $ : Accept                          
    s2               + : Reduce 3  * : Reduce 3  $ : Reduce 3                        
    s3               + : Reduce 1  * : Shift  5  $ : Reduce 1                        
    s4  N : Shift 2                                                        T : Goto 6
    s5  N : Shift 7                                                                  
    s6               + : Reduce 0  * : Shift  5  $ : Reduce 0                        
    s7               + : Reduce 2  * : Reduce 2  $ : Reduce 2                        
    命令      in       st       res   動作                                     次の命令
              1 + 2 $  0              開始時はstに0をセット,                   inのtop Nとs0から
    Shift  2  + 2 $    2 0      1     stに2をpush,resにinの1をpush,            inのtop +とs2から
    Reduce 3  + 2 $    0        1     g3の右辺数1だけpop,callback値をresにpush,g3の左辺Tとs0から
    Goto   3  + 2 $    3 0      1     stに3をpush,       ↑$1=1 {$1}=1         inのtop +とs3から
    Reduce 1  + 2 $    0        1     g1の右辺数1だけpop,callback値をresにpush,g1の左辺Eとs0から
    Goto   1  + 2 $    1 0      1     stに1をpush,       ↑$1=1 {$1}=1         inのtop +とs1から
    Shift  4  2 $      4 1 0    + 1   stに4をpush,resにinの+をpush,            inのtop Nとs4から
    Shift  2  $        2 4 1 0  2 + 1 stに2をpush,resにinの2をpush,            inのtop $とs2から
    Reduce 3  $        4 1 0    2 + 1 g3の右辺数1だけpop,callback値をresにpush,g3の左辺Tとs4から
    Goto   6  $        6 4 1 0  2 + 1 stに6をpush,       ↑$1=2 {$1}=2         inのtop $とs6から
    Reduce 0  $        0        3     g0の右辺数3だけpop,callback値をresにpush,g0の左辺Eとs0から
    Goto   1  $        1 0      3     stに1をpush,       ↑$1=2 $3=1 {$1+$2}=3 inのtop $とs1から
    Accept 1  $        1 0      3     完了

    文法
    g0 E -> E + T         { $1 + $2 }
    g1 E -> T             { $1 }
    g2 T -> T * N         { $1 * $2 }
    g3 T -> N             { $1 }
    構文解析表
    s0  N : Shift 2                                            E : Goto 1  T : Goto 3
    s1               + : Shift  4                $ : Accept                          
    s2               + : Reduce 3  * : Reduce 3  $ : Reduce 3                        
    s3               + : Reduce 1  * : Shift  5  $ : Reduce 1                        
    s4  N : Shift 2                                                        T : Goto 6
    s5  N : Shift 7                                                                  
    s6               + : Reduce 0  * : Shift  5  $ : Reduce 0                        
    s7               + : Reduce 2  * : Reduce 2  $ : Reduce 2                        
    命令      in           st           res       動作                                     次の命令
              1 + 2 * 3 $  0                      開始時はstに0をセット,                   inのtop Nとs0から
    Shift  2  + 2 * 3 $    2 0          1         stに2をpush,resにinの1をpush,            inのtop +とs2から
    Reduce 3  + 2 * 3 $    0            1         g3の右辺数1だけpop,callback値をresにpush,g3の左辺Tとs0から
    Goto   3  + 2 * 3 $    3 0          1         stに3をpush,       ↑$1=1 {$1}=1         inのtop +とs3から
    Reduce 1  + 2 * 3 $    0            1         g1の右辺数1だけpop,callback値をresにpush,g1の左辺Eとs0から
    Goto   1  + 2 * 3 $    1 0          1         stに1をpush,       ↑$1=1 {$1}=1         inのtop +とs1から
    Shift  4  2 * 3 $      4 1 0        + 1       stに4をpush,resにinの+をpush,            inのtop Nとs4から
    Shift  2  * 3 $        2 4 1 0      2 + 1     stに2をpush,resにinの2をpush,            inのtop *とs2から
    Reduce 3  * 3 $        4 1 0        2 + 1     g3の右辺数1だけpop,callback値をresにpush,g3の左辺Tとs4から
    Goto   6  * 3 $        6 4 1 0      2 + 1     stに6をpush,       ↑$1=2 {$1}=2         inのtop *とs6から
    Shift  5  3 $          5 6 4 1 0    * 2 + 1   stに5をpush,resにinの*をpush,            inのtop Nとs5から
    Shift  7  $            7 5 6 4 1 0  3 * 2 + 1 stに7をpush resにinの3をpush,            inのtop $とs7から
    Reduce 2  $            4 1 0        6 + 1     g2の右辺数3だけpop,callback値をresにpush,g2の左辺Tとs4から
    Goto   6  $            6 4 1 0      6 + 1     stに6をpush,       ↑$1=3 $3=2 {$1+$2}=6 inのtop $とs6から
    Reduce 0  $            0            7         g0の右辺数3だけpop,callback値をresにpush,g0の左辺Eとs0から
    Goto   1  $            1 0          7         stに1をpush,       ↑$1=6 $3=1 {$1*$2}=7 inのtop $とs1から
    Accept    $            1 0          7         完了                                     


### LR 構文解析 "8"

```
構文解析表                                    
   N     +       *       $      E     T     文法
s0[Shift2]                      Goto1 Goto3 g0 E->E+T{$1+$2}
s1       Shift 4         Accept             g1 E->T  {$1}
s2       Reduce3 Reduce3 Reduce3            g2 T->T*N{$1*$2}
s3       Reduce1 Shift 5 Reduce1            g3 T->N  {$1}
s4 Shift2                       Goto6 in  : 8 $
s5 Shift7                             st  : 0
s6       Reduce0 Shift 5 Reduce0      res :
s7       Reduce2 Reduce2 Reduce2  op:<       > next:[Shift 2]
```

- "8" を構文解析してみましょう。
- 開始時はstに0をセットします。
- 次の命令はinのtop N(8)とstのtop 0で表s0を引いてShift2です。

---

### LR 構文解析

```
構文解析表                                    
   N     +       *       $      E     T     文法
s0<Shift2>                      Goto1 Goto3 g0 E->E+T{$1+$2}
s1       Shift 4         Accept             g1 E->T  {$1}
s2       Reduce3 Reduce3[Reduce3]           g2 T->T*N{$1*$2}
s3       Reduce1 Shift 5 Reduce1            g3 T->N  {$1}
s4 Shift2                       Goto6 in  : $
s5 Shift7                             st  : 2 0
s6       Reduce0 Shift 5 Reduce0      res : 8
s7       Reduce2 Reduce2 Reduce2  op:<Shift 2> next:[Reduce3]
```

- Shift2はstに2をpush,inからresに8をpush
- 次の命令は inのtop $とs2から Reduce3です

---

### LR 構文解析

```
構文解析表                                    
   N     +       *       $      E     T     文法
s0 Shift2                       Goto1[Goto3]g0 E->E+T{$1+$2}
s1       Shift 4         Accept             g1 E->T  {$1}
s2       Reduce3 Reduce3<Reduce3>           g2 T->T*N{$1*$2}
s3       Reduce1 Shift 5 Reduce1            g3*T->N  {$1}   *
s4 Shift2                       Goto6 in  : $
s5 Shift7                             st  : 0
s6       Reduce0 Shift 5 Reduce0      res : 8
s7       Reduce2 Reduce2 Reduce2  op:<Reduce3> next:[Goto  3]
```

- Reduce 3 g3の右辺数1だけpop
- callback値をresにpush
- g3の左辺Tとs0から次の命令はGoto3です。

---

### LR 構文解析

```
構文解析表                                    
   N     +       *       $      E     T     文法
s0 Shift2                      Goto1<Goto3>g0 E->E+T{$1+$2}
s1       Shift 4         Accept            g1 E->T  {$1}
s2       Reduce3 Reduce3 Reduce3           g2 T->T*N{$1*$2}
s3       Reduce1 Shift 5[Reduce1]          g3 T->N  {$1}
s4 Shift2                       Goto6 in  : $
s5 Shift7                             st  : 3 0
s6       Reduce0 Shift 5 Reduce0      res : 8
s7       Reduce2 Reduce2 Reduce2  op:<Goto  3> next:[Reduce1]
```

- Goto 3 は Stに 3をpush するだけです。
- 次の命令はinのtop $ と s3 から Reduce1です。

---

### LR 構文解析

```
構文解析表                                    
   N     +       *       $      E     T     文法
s0 Shift2                      [Goto1]Goto3 g0 E->E+T{$1+$2}
s1       Shift 4         Accept             g1*E->T  {$1}   *
s2       Reduce3 Reduce3 Reduce3            g2 T->T*N{$1*$2}
s3       Reduce1 Shift 5<Reduce1>           g3 T->N  {$1}
s4 Shift2                       Goto6 in  : $
s5 Shift7                             st  : 0
s6       Reduce0 Shift 5 Reduce0      res : 8
s7       Reduce2 Reduce2 Reduce2  op:<Reduce1> next:[Goto  1]
```

- Reduce 1 は g1の右辺数1だけpop,callback値をresにpush
- g1の左辺Eとs0から Goto1です


---

### LR 構文解析

```
構文解析表                                    
   N     +       *       $      E     T     文法
s0<Shift2>                      Goto1 Goto3 g0 E->E+T{$1+$2}
s1       Shift 4         Accept             g1 E->T  {$1}
s2       Reduce3 Reduce3[Reduce3]           g2 T->T*N{$1*$2}
s3       Reduce1 Shift 5 Reduce1            g3 T->N  {$1}
s4 Shift2                       Goto6 in  : $
s5 Shift7                             st  : 1 0
s6       Reduce0 Shift 5 Reduce0      res : 8
s7       Reduce2 Reduce2 Reduce2  op:<Reduce1> next:[Goto  1]
```

- Goto1  $     1 0  8   stに1をpush,       ↑$1=8 {$1}=8         inのtop $とs1から

- Shift2はstに2をpush,inからresに8をpush
- 次の命令は inのtop $とs2から Reduce3です


---

### LR 構文解析

```
構文解析表                                    
   N     +       *       $      E     T     文法
s0<Shift2>                      Goto1 Goto3 g0 E->E+T{$1+$2}
s1       Shift 4         Accept             g1 E->T  {$1}
s2       Reduce3 Reduce3[Reduce3]           g2 T->T*N{$1*$2}
s3       Reduce1 Shift 5 Reduce1            g3 T->N  {$1}
s4 Shift2                       Goto6 in  : $
s5 Shift7                             st  : 2 0
s6       Reduce0 Shift 5 Reduce0      res : 8
s7       Reduce2 Reduce2 Reduce2      next: Shift2
```

Accept    $     1 0  8   完了

- Shift2はstに2をpush,inからresに8をpush
- 次の命令は inのtop $とs2から Reduce3です


---


    文法
    g0 E -> E + T         { $1 + $2 }
    g1 E -> T             { $1 }
    g2 T -> T * N         { $1 * $2 }
    g3 T -> N             { $1 }
    構文解析表
    s0  N : Shift 2                                            E : Goto 1  T : Goto 3
    s1               + : Shift  4                $ : Accept                          
    s2               + : Reduce 3  * : Reduce 3  $ : Reduce 3                        
    s3               + : Reduce 1  * : Shift  5  $ : Reduce 1                        
    s4  N : Shift 2                                                        T : Goto 6
    s5  N : Shift 7                                                                  
    s6               + : Reduce 0  * : Shift  5  $ : Reduce 0                        
    s7               + : Reduce 2  * : Reduce 2  $ : Reduce 2                        
    命令      in       st       res   動作                                     次の命令
              1 + 2 $  0              開始時はstに0をセット,                   inのtop Nとs0から
    Shift  2  + 2 $    2 0      1     stに2をpush,resにinの1をpush,            inのtop +とs2から
    Reduce 3  + 2 $    0        1     g3の右辺数1だけpop,callback値をresにpush,g3の左辺Tとs0から
    Goto   3  + 2 $    3 0      1     stに3をpush,       ↑$1=1 {$1}=1         inのtop +とs3から
    Reduce 1  + 2 $    0        1     g1の右辺数1だけpop,callback値をresにpush,g1の左辺Eとs0から
    Goto   1  + 2 $    1 0      1     stに1をpush,       ↑$1=1 {$1}=1         inのtop +とs1から
    Shift  4  2 $      4 1 0    + 1   stに4をpush,resにinの+をpush,            inのtop Nとs4から
    Shift  2  $        2 4 1 0  2 + 1 stに2をpush,resにinの2をpush,            inのtop $とs2から
    Reduce 3  $        4 1 0    2 + 1 g3の右辺数1だけpop,callback値をresにpush,g3の左辺Tとs4から
    Goto   6  $        6 4 1 0  2 + 1 stに6をpush,       ↑$1=2 {$1}=2         inのtop $とs6から
    Reduce 0  $        0        3     g0の右辺数3だけpop,callback値をresにpush,g0の左辺Eとs0から
    Goto   1  $        1 0      3     stに1をpush,       ↑$1=2 $3=1 {$1+$2}=3 inのtop $とs1から
    Accept 1  $        1 0      3     完了

    文法
    g0 E -> E + T         { $1 + $2 }
    g1 E -> T             { $1 }
    g2 T -> T * N         { $1 * $2 }
    g3 T -> N             { $1 }
    構文解析表
    s0  N : Shift 2                                            E : Goto 1  T : Goto 3
    s1               + : Shift  4                $ : Accept                          
    s2               + : Reduce 3  * : Reduce 3  $ : Reduce 3                        
    s3               + : Reduce 1  * : Shift  5  $ : Reduce 1                        
    s4  N : Shift 2                                                        T : Goto 6
    s5  N : Shift 7                                                                  
    s6               + : Reduce 0  * : Shift  5  $ : Reduce 0                        
    s7               + : Reduce 2  * : Reduce 2  $ : Reduce 2                        
    命令      in           st           res       動作                                     次の命令
              1 + 2 * 3 $  0                      開始時はstに0をセット,                   inのtop Nとs0から
    Shift  2  + 2 * 3 $    2 0          1         stに2をpush,resにinの1をpush,            inのtop +とs2から
    Reduce 3  + 2 * 3 $    0            1         g3の右辺数1だけpop,callback値をresにpush,g3の左辺Tとs0から
    Goto   3  + 2 * 3 $    3 0          1         stに3をpush,       ↑$1=1 {$1}=1         inのtop +とs3から
    Reduce 1  + 2 * 3 $    0            1         g1の右辺数1だけpop,callback値をresにpush,g1の左辺Eとs0から
    Goto   1  + 2 * 3 $    1 0          1         stに1をpush,       ↑$1=1 {$1}=1         inのtop +とs1から
    Shift  4  2 * 3 $      4 1 0        + 1       stに4をpush,resにinの+をpush,            inのtop Nとs4から
    Shift  2  * 3 $        2 4 1 0      2 + 1     stに2をpush,resにinの2をpush,            inのtop *とs2から
    Reduce 3  * 3 $        4 1 0        2 + 1     g3の右辺数1だけpop,callback値をresにpush,g3の左辺Tとs4から
    Goto   6  * 3 $        6 4 1 0      2 + 1     stに6をpush,       ↑$1=2 {$1}=2         inのtop *とs6から
    Shift  5  3 $          5 6 4 1 0    * 2 + 1   stに5をpush,resにinの*をpush,            inのtop Nとs5から
    Shift  7  $            7 5 6 4 1 0  3 * 2 + 1 stに7をpush resにinの3をpush,            inのtop $とs7から
    Reduce 2  $            4 1 0        6 + 1     g2の右辺数3だけpop,callback値をresにpush,g2の左辺Tとs4から
    Goto   6  $            6 4 1 0      6 + 1     stに6をpush,       ↑$1=3 $3=2 {$1+$2}=6 inのtop $とs6から
    Reduce 0  $            0            7         g0の右辺数3だけpop,callback値をresにpush,g0の左辺Eとs0から
    Goto   1  $            1 0          7         stに1をpush,       ↑$1=6 $3=1 {$1*$2}=7 inのtop $とs1から
    Accept    $            1 0          7         完了                                     
