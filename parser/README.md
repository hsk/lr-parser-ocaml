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
      let child = callback(grammar_id, children) in (* callback 実行 *)
      (* 次は必ず Goto *)
      begin match List.assoc ltoken (List.nth parsingtable state) with
      | Goto(to1) -> automaton parser inputs (to1 :: states) (child :: results)
      | _ -> ("parse failed: goto operation expected after reduce operation", child :: results)
      end
```

とはいえそんなに長くはありません。grammar_id文法番号がパラメータにあるのでそこから文法を取り出してパターン数を取得します。
その長さだけ、結果およびステータススタックからポップします。ステータスのスタックは捨てちゃいますが、結果のスタック内容はまとめてコールバックを呼び出し結果を結果スタックに積みなおします。
リデュースしたあとは必ずgoto命令があるはずなのでパーサテーブルのステート番号の命令を取り出して、
ステータススタックに飛び先を設定します。

コンフリクトはエラー処理をするだけなので省略します。
