# LRパーサジェネレータ

これは何？
LR1 LALR1 のパーサジェネレータです。元のTypeScriptのパーサジェネレータを Scala に移植した後に OCaml に移植したものです。
リファクタリングしてできるだけわかりやすくするようにしています。

目指したいところは、字句解析と、パーサと、パーサジェネレータを分離してしまいたいというところです。

現状、lexerのフォルダがまずあって、