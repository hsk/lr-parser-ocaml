# LR 構文解析器

lexerディレクトリの字句解析を使ったLR構文解析器がここにはあります。
LR構文解析器は、構文解析表と字句解析器を受け取って構文解析を行います。
構文解析表を作る作業はここではしません。構文解析表を作る仕組みはyaccディレクトリにあります。

ファイル一覧

- language.ml 言語定義
- parser.ml LR構文解析器
- test/calc_test.ml 言語定義パーサのテスト
- Makefile メイクファイル
- README.md このファイル

LR構文解析のアルゴリズムは構文解析表を元にオートマトンを実行するだけなので簡単です。
パーサの行数は100行未満で出来ています。

LR構文解析の難しいところはそのオートマトンの動きの理解と、構文解析表を生成するアルゴリズムでしょう。
そのうちオートマトンの動きそのものについてここにあるプログラムは理解の助けになるかも知れません。

## 構文解析器の動作

LR構文解析の構文解析器は単純なオートマトンとして実装できます。

オートマトンには5つの命令があります:

```
type op =
  | Accept
  | Shift of int
  | Reduce of int
  | Goto of int
  | Conflict of int list * int list (* Shift/Reduceコンフリクト *)
```

Acceptは解析終了を、Shiftはシフト動作を、Reduceは還元動作を、Gotoは状態の遷移を、Conflictはパーサがコンフリクトを起こした場合の動作を実行します。
シフトは要は関数呼び出しで、リデュースは関数リターンのようなものです。

オートマトンのプログラムの最初の部分を見てみましょう:

```
let rec automaton parser inputs states results = 
  match (parser, states, inputs) with
  | (_, _, []) -> ("", results)
  | ((grammar,parsingtable,callback), state::_, (token,value)::inp) ->
    begin try match List.assoc token (List.nth parsingtable state) with
```

automaton は parserとinputs(入力リスト)とstates(状態スタック)とresults(結果スタック)を持ちます。
まず、入力リストがなくなれば結果を返します。入力リストが残っていればその入力に従って何かしらの動作を行います。
パーサの中身はさらにgrammar(文法)とparsingtable(構文解析表)とcallbackが含まれています。

ワンステップごとの動作は状態スタックのトップと入力のトップを見て構文解析表のステートとトークンに対応する命令を取り出して実行します。

Accept場合は:

```
    | Accept -> ("", results) (* 完了 *)
```

本当に何もしません。結果を返すだけです。

Shiftも、とても簡単です:

```
    | Shift(to1) -> automaton parser inp (to1 :: states) (value :: results)
```

ステータススタックにシフト先のステータスをpushして結果スタックに入力値をpushするだけです。

Reduceの動作が一番複雑です:

```
    | Reduce(grammar_id) ->
      let (ltoken,pattern,_) = List.nth grammar grammar_id in (* 文法表を参照 *)
      let rnum = List.length pattern in (*  *)
      let (children, results) = pop2 rnum results in (* 右辺の記号の数だけポップ *)
      let ((state::_) as states) = pop rnum states in (* 対応する規則の右辺の記号の数だけポップ *)
      let result = callback(grammar_id, children) :: result in (* callbackを実行して結果をresultにpush *)
      (* 次は必ず Goto *)
      begin match List.assoc ltoken (List.nth parsingtable state) with
      | Goto(to1) -> automaton parser inputs (to1 :: states) results (* ステータスにpush *)
      | _ -> ("parse failed: goto operation expected after reduce operation", results)
      end
```

とはいえそんなに長くはありません。grammar_id文法番号がパラメータにあるのでそこから文法を取り出してパターン数を取得します。
その長さだけ、結果およびステータススタックからポップします。ステータスのスタックは捨てちゃいますが、結果のスタック内容はまとめてコールバックを呼び出し結果を結果スタックに積みなおします。
リデュースしたあとは必ずgoto命令があるはずなのでパーサテーブルのステート番号の命令を取り出して、
ステータススタックに飛び先を設定します。

コンフリクトはエラー処理をするだけなので省略します。

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
