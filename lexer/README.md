# OCaml でLR構文解析の為の字句解析器

ファイル一覧

- token.ml トークン定義
- lexer.ml 字句解析器
- test/lexer_test.ml テスト
- Makefile メイク＆テスト

## TODO

- PCRE を使う

    Strモジュールを使えばOPAMを使ってPCREなどを使わずとも一応、正規表現が使えるので現状はStrモジュールを用いていますが、いずれ、PCREを使うように書き換える。
