# LR 構文解析器

lexerディレクトリの字句解析を使ったLR構文解析器がここにはあります。
LR構文解析器は、構文解析表と字句解析器を受け取って構文解析を行います。
構文解析表を作る作業はここではしません。構文解析表を作る仕組みはyaccディレクトリにあります。

ファイル一覧

- language.ml 言語定義
- parser.ml LR構文解析器
- ast.ml ASTノードを自動生成するパーサの生成
- data/rule_parser.ml 言語定義のパーサ
- data/language_language.ml 言語定義のパーサからコールバックを省いたもの
- test/rule\_parsing\_test.ml 言語定義パーサのテスト
- Makefile メイクファイル
- README.md このファイル

ast.ml ファイルは便利ライブラリなので特に無くても困りません。

LR構文解析のアルゴリズムは構文解析表を元にオートマトンを実行するだけなので簡単です。
パーサの行数は100行未満で出来ています。

LR構文解析の難しいところはそのオートマトンの動きの理解と、構文解析表を生成するアルゴリズムでしょう。
そのうちオートマトンの動きそのものについてここにあるプログラムは理解の助けになるかも知れません。

## 構文解析器の動作

オートマトンのプログラムの最初の部分を見てみましょう:

```
let rec automaton parser inputs states results = 
  match (parser, states, inputs) with
  | (_, _, []) -> ("", results)
  | ((grammar,parsingtable,callback), state::_, (token,value)::inp) ->
    begin try match List.assoc token (List.nth parsingtable state) with
```

オートマトンはパーサと入力リストと状態スタックと結果スタックを持ちます。
入力リストがなくなれば結果を返します。
パーサの中身はさらに文法と構文解析表とコールバックが含まれています。
ワンステップごとの動作は状態スタックのトップと入力のトップを見て構文解析表のステートとトークンに対応する命令を取り出して実行します。

```
type op =
  | Accept
  | Shift of int
  | Reduce of int
  | Goto of int
  | Conflict of int list * int list (* Shift/Reduceコンフリクト *)
```

オートマトンの命令は5つあります。Acceptは解析終了を、Shiftはシフト動作を、Reduceは還元動作を、Gotoは常態の遷移を、Conflictはパーサがコンフリクトを起こした場合の動作を実行します。

Acceptのプログラムを見てみましょう:

```
    | Accept -> ("", results) (* 完了 *)
```

本当に何もしません。結果を返すだけです。

Shiftのプログラムも、とても簡単です:

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

とはいえそんなに長くはありません。文法番号がパラメータにあるのでそこから文法を取り出してパターン数を取得します。
その長さだけ、結果およびステータススタックからポップします。ステータスのスタックは捨てちゃいますが、結果のスタック内容は必要なのでまとめておいてコールバックを呼び出して結果スタックに積みます。
リデュースしたあとは必ずgoto命令があるはずなのでパーサテーブルのステート番号の命令を取り出して、
ステータススタックに飛び先を設定します。

コンフリクトはエラー処理をするので省略します。

これだけです。

## todo

- テストの充実

  現状のテストはあったものをおいてありますが、四則演算のテストなどがあったほうが良さそうです。
  テーブルを作るのが大変なのでジェネレータが吐き出したものを用意したいところです。

- ast.ml の移動

  ディレクトリ作って移動したいところです。

- rule_parsingの移動

  これもディレクトリ作って移動したいです。
