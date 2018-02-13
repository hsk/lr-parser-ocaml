---
transition: none
---

# 1

--

## Shift s2

    inputs 1 $ 
    status 0
    results 
![fig](images/s0.png)


--

## Shift s2

    inputs 1 $ ステータスに2をpush 入力1を結果に移動
    status 0
    results 
![fig](images/s0-78.png)


--

## Reduce g3

    inputs $ 
    status 2 0
    results 1
![fig](images/s2.png)


--

## Reduce g3

    inputs $ 文法g3を見て、1個Pop、{$1}を結果にpush、文法名Tを入力にpush
    status 2 0
    results 1
![fig](images/g3-36.png)


--

## Goto s3

    inputs T $ 
    status 0
    results 1
![fig](images/s0.png)


--

## Goto s3

    inputs T $ ステータスに3をpush,入力Tを捨てる
    status 0
    results 1
![fig](images/s0-84.png)


--

## Reduce g1

    inputs $ 
    status 3 0
    results 1
![fig](images/s3.png)


--

## Reduce g1

    inputs $ 文法g1を見て、1個Pop、{$1}を結果にpush、文法名Eを入力にpush
    status 3 0
    results 1
![fig](images/g1-36.png)


--

## Goto s1

    inputs E $ 
    status 0
    results 1
![fig](images/s0.png)


--

## Goto s1

    inputs E $ ステータスに1をpush,入力Eを捨てる
    status 0
    results 1
![fig](images/s0-69.png)


--

## Accept

    inputs $ 
    status 1 0
    results 1
![fig](images/s1.png)


--

## Accept

    inputs $ アクセプト
    status 1 0
    results 1
![fig](images/s1-36.png)


--

## Accept

    inputs $ 結果 1 です
    status 1 0
    results 1
![fig](images/end.png)


--

# result 1 = 1

---

# 2\*3

--

## Shift s2

    inputs 2 * 3 $ 
    status 0
    results 
![fig](images/s0.png)


--

## Shift s2

    inputs 2 * 3 $ ステータスに2をpush 入力2を結果に移動
    status 0
    results 
![fig](images/s0-78.png)


--

## Reduce g3

    inputs * 3 $ 
    status 2 0
    results 2
![fig](images/s2.png)


--

## Reduce g3

    inputs * 3 $ 文法g3を見て、1個Pop、{$1}を結果にpush、文法名Tを入力にpush
    status 2 0
    results 2
![fig](images/g3-42.png)


--

## Goto s3

    inputs T * 3 $ 
    status 0
    results 2
![fig](images/s0.png)


--

## Goto s3

    inputs T * 3 $ ステータスに3をpush,入力Tを捨てる
    status 0
    results 2
![fig](images/s0-84.png)


--

## Shift s5

    inputs * 3 $ 
    status 3 0
    results 2
![fig](images/s3.png)


--

## Shift s5

    inputs * 3 $ ステータスに5をpush 入力*を結果に移動
    status 3 0
    results 2
![fig](images/s3-42.png)


--

## Shift s7

    inputs 3 $ 
    status 5 3 0
    results * 2
![fig](images/s5.png)


--

## Shift s7

    inputs 3 $ ステータスに7をpush 入力3を結果に移動
    status 5 3 0
    results * 2
![fig](images/s5-78.png)


--

## Reduce g2

    inputs $ 
    status 7 5 3 0
    results 3 * 2
![fig](images/s7.png)


--

## Reduce g2

    inputs $ 文法g2を見て、3個Pop、{$1*$2}を結果にpush、文法名Tを入力にpush
    status 7 5 3 0
    results 3 * 2
![fig](images/g2-36.png)


--

## Goto s3

    inputs T $ 
    status 0
    results 6
![fig](images/s0.png)


--

## Goto s3

    inputs T $ ステータスに3をpush,入力Tを捨てる
    status 0
    results 6
![fig](images/s0-84.png)


--

## Reduce g1

    inputs $ 
    status 3 0
    results 6
![fig](images/s3.png)


--

## Reduce g1

    inputs $ 文法g1を見て、1個Pop、{$1}を結果にpush、文法名Eを入力にpush
    status 3 0
    results 6
![fig](images/g1-36.png)


--

## Goto s1

    inputs E $ 
    status 0
    results 6
![fig](images/s0.png)


--

## Goto s1

    inputs E $ ステータスに1をpush,入力Eを捨てる
    status 0
    results 6
![fig](images/s0-69.png)


--

## Accept

    inputs $ 
    status 1 0
    results 6
![fig](images/s1.png)


--

## Accept

    inputs $ アクセプト
    status 1 0
    results 6
![fig](images/s1-36.png)


--

## Accept

    inputs $ 結果 6 です
    status 1 0
    results 6
![fig](images/end.png)


--

# result 2\*3 = 6

---

# 2\*3\*4

--

## Shift s2

    inputs 2 * 3 * 4 $ 
    status 0
    results 
![fig](images/s0.png)


--

## Shift s2

    inputs 2 * 3 * 4 $ ステータスに2をpush 入力2を結果に移動
    status 0
    results 
![fig](images/s0-78.png)


--

## Reduce g3

    inputs * 3 * 4 $ 
    status 2 0
    results 2
![fig](images/s2.png)


--

## Reduce g3

    inputs * 3 * 4 $ 文法g3を見て、1個Pop、{$1}を結果にpush、文法名Tを入力にpush
    status 2 0
    results 2
![fig](images/g3-42.png)


--

## Goto s3

    inputs T * 3 * 4 $ 
    status 0
    results 2
![fig](images/s0.png)


--

## Goto s3

    inputs T * 3 * 4 $ ステータスに3をpush,入力Tを捨てる
    status 0
    results 2
![fig](images/s0-84.png)


--

## Shift s5

    inputs * 3 * 4 $ 
    status 3 0
    results 2
![fig](images/s3.png)


--

## Shift s5

    inputs * 3 * 4 $ ステータスに5をpush 入力*を結果に移動
    status 3 0
    results 2
![fig](images/s3-42.png)


--

## Shift s7

    inputs 3 * 4 $ 
    status 5 3 0
    results * 2
![fig](images/s5.png)


--

## Shift s7

    inputs 3 * 4 $ ステータスに7をpush 入力3を結果に移動
    status 5 3 0
    results * 2
![fig](images/s5-78.png)


--

## Reduce g2

    inputs * 4 $ 
    status 7 5 3 0
    results 3 * 2
![fig](images/s7.png)


--

## Reduce g2

    inputs * 4 $ 文法g2を見て、3個Pop、{$1*$2}を結果にpush、文法名Tを入力にpush
    status 7 5 3 0
    results 3 * 2
![fig](images/g2-42.png)


--

## Goto s3

    inputs T * 4 $ 
    status 0
    results 6
![fig](images/s0.png)


--

## Goto s3

    inputs T * 4 $ ステータスに3をpush,入力Tを捨てる
    status 0
    results 6
![fig](images/s0-84.png)


--

## Shift s5

    inputs * 4 $ 
    status 3 0
    results 6
![fig](images/s3.png)


--

## Shift s5

    inputs * 4 $ ステータスに5をpush 入力*を結果に移動
    status 3 0
    results 6
![fig](images/s3-42.png)


--

## Shift s7

    inputs 4 $ 
    status 5 3 0
    results * 6
![fig](images/s5.png)


--

## Shift s7

    inputs 4 $ ステータスに7をpush 入力4を結果に移動
    status 5 3 0
    results * 6
![fig](images/s5-78.png)


--

## Reduce g2

    inputs $ 
    status 7 5 3 0
    results 4 * 6
![fig](images/s7.png)


--

## Reduce g2

    inputs $ 文法g2を見て、3個Pop、{$1*$2}を結果にpush、文法名Tを入力にpush
    status 7 5 3 0
    results 4 * 6
![fig](images/g2-36.png)


--

## Goto s3

    inputs T $ 
    status 0
    results 24
![fig](images/s0.png)


--

## Goto s3

    inputs T $ ステータスに3をpush,入力Tを捨てる
    status 0
    results 24
![fig](images/s0-84.png)


--

## Reduce g1

    inputs $ 
    status 3 0
    results 24
![fig](images/s3.png)


--

## Reduce g1

    inputs $ 文法g1を見て、1個Pop、{$1}を結果にpush、文法名Eを入力にpush
    status 3 0
    results 24
![fig](images/g1-36.png)


--

## Goto s1

    inputs E $ 
    status 0
    results 24
![fig](images/s0.png)


--

## Goto s1

    inputs E $ ステータスに1をpush,入力Eを捨てる
    status 0
    results 24
![fig](images/s0-69.png)


--

## Accept

    inputs $ 
    status 1 0
    results 24
![fig](images/s1.png)


--

## Accept

    inputs $ アクセプト
    status 1 0
    results 24
![fig](images/s1-36.png)


--

## Accept

    inputs $ 結果 24 です
    status 1 0
    results 24
![fig](images/end.png)


--

# result 2\*3\*4 = 24

---

# 1\+2

--

## Shift s2

    inputs 1 + 2 $ 
    status 0
    results 
![fig](images/s0.png)


--

## Shift s2

    inputs 1 + 2 $ ステータスに2をpush 入力1を結果に移動
    status 0
    results 
![fig](images/s0-78.png)


--

## Reduce g3

    inputs + 2 $ 
    status 2 0
    results 1
![fig](images/s2.png)


--

## Reduce g3

    inputs + 2 $ 文法g3を見て、1個Pop、{$1}を結果にpush、文法名Tを入力にpush
    status 2 0
    results 1
![fig](images/g3-43.png)


--

## Goto s3

    inputs T + 2 $ 
    status 0
    results 1
![fig](images/s0.png)


--

## Goto s3

    inputs T + 2 $ ステータスに3をpush,入力Tを捨てる
    status 0
    results 1
![fig](images/s0-84.png)


--

## Reduce g1

    inputs + 2 $ 
    status 3 0
    results 1
![fig](images/s3.png)


--

## Reduce g1

    inputs + 2 $ 文法g1を見て、1個Pop、{$1}を結果にpush、文法名Eを入力にpush
    status 3 0
    results 1
![fig](images/g1-43.png)


--

## Goto s1

    inputs E + 2 $ 
    status 0
    results 1
![fig](images/s0.png)


--

## Goto s1

    inputs E + 2 $ ステータスに1をpush,入力Eを捨てる
    status 0
    results 1
![fig](images/s0-69.png)


--

## Shift s4

    inputs + 2 $ 
    status 1 0
    results 1
![fig](images/s1.png)


--

## Shift s4

    inputs + 2 $ ステータスに4をpush 入力+を結果に移動
    status 1 0
    results 1
![fig](images/s1-43.png)


--

## Shift s2

    inputs 2 $ 
    status 4 1 0
    results + 1
![fig](images/s4.png)


--

## Shift s2

    inputs 2 $ ステータスに2をpush 入力2を結果に移動
    status 4 1 0
    results + 1
![fig](images/s4-78.png)


--

## Reduce g3

    inputs $ 
    status 2 4 1 0
    results 2 + 1
![fig](images/s2.png)


--

## Reduce g3

    inputs $ 文法g3を見て、1個Pop、{$1}を結果にpush、文法名Tを入力にpush
    status 2 4 1 0
    results 2 + 1
![fig](images/g3-36.png)


--

## Goto s6

    inputs T $ 
    status 4 1 0
    results 2 + 1
![fig](images/s4.png)


--

## Goto s6

    inputs T $ ステータスに6をpush,入力Tを捨てる
    status 4 1 0
    results 2 + 1
![fig](images/s4-84.png)


--

## Reduce g0

    inputs $ 
    status 6 4 1 0
    results 2 + 1
![fig](images/s6.png)


--

## Reduce g0

    inputs $ 文法g0を見て、3個Pop、{$1+$2}を結果にpush、文法名Eを入力にpush
    status 6 4 1 0
    results 2 + 1
![fig](images/g0-36.png)


--

## Goto s1

    inputs E $ 
    status 0
    results 3
![fig](images/s0.png)


--

## Goto s1

    inputs E $ ステータスに1をpush,入力Eを捨てる
    status 0
    results 3
![fig](images/s0-69.png)


--

## Accept

    inputs $ 
    status 1 0
    results 3
![fig](images/s1.png)


--

## Accept

    inputs $ アクセプト
    status 1 0
    results 3
![fig](images/s1-36.png)


--

## Accept

    inputs $ 結果 3 です
    status 1 0
    results 3
![fig](images/end.png)


--

# result 1\+2 = 3

---

# 1\+2\+3

--

## Shift s2

    inputs 1 + 2 + 3 $ 
    status 0
    results 
![fig](images/s0.png)


--

## Shift s2

    inputs 1 + 2 + 3 $ ステータスに2をpush 入力1を結果に移動
    status 0
    results 
![fig](images/s0-78.png)


--

## Reduce g3

    inputs + 2 + 3 $ 
    status 2 0
    results 1
![fig](images/s2.png)


--

## Reduce g3

    inputs + 2 + 3 $ 文法g3を見て、1個Pop、{$1}を結果にpush、文法名Tを入力にpush
    status 2 0
    results 1
![fig](images/g3-43.png)


--

## Goto s3

    inputs T + 2 + 3 $ 
    status 0
    results 1
![fig](images/s0.png)


--

## Goto s3

    inputs T + 2 + 3 $ ステータスに3をpush,入力Tを捨てる
    status 0
    results 1
![fig](images/s0-84.png)


--

## Reduce g1

    inputs + 2 + 3 $ 
    status 3 0
    results 1
![fig](images/s3.png)


--

## Reduce g1

    inputs + 2 + 3 $ 文法g1を見て、1個Pop、{$1}を結果にpush、文法名Eを入力にpush
    status 3 0
    results 1
![fig](images/g1-43.png)


--

## Goto s1

    inputs E + 2 + 3 $ 
    status 0
    results 1
![fig](images/s0.png)


--

## Goto s1

    inputs E + 2 + 3 $ ステータスに1をpush,入力Eを捨てる
    status 0
    results 1
![fig](images/s0-69.png)


--

## Shift s4

    inputs + 2 + 3 $ 
    status 1 0
    results 1
![fig](images/s1.png)


--

## Shift s4

    inputs + 2 + 3 $ ステータスに4をpush 入力+を結果に移動
    status 1 0
    results 1
![fig](images/s1-43.png)


--

## Shift s2

    inputs 2 + 3 $ 
    status 4 1 0
    results + 1
![fig](images/s4.png)


--

## Shift s2

    inputs 2 + 3 $ ステータスに2をpush 入力2を結果に移動
    status 4 1 0
    results + 1
![fig](images/s4-78.png)


--

## Reduce g3

    inputs + 3 $ 
    status 2 4 1 0
    results 2 + 1
![fig](images/s2.png)


--

## Reduce g3

    inputs + 3 $ 文法g3を見て、1個Pop、{$1}を結果にpush、文法名Tを入力にpush
    status 2 4 1 0
    results 2 + 1
![fig](images/g3-43.png)


--

## Goto s6

    inputs T + 3 $ 
    status 4 1 0
    results 2 + 1
![fig](images/s4.png)


--

## Goto s6

    inputs T + 3 $ ステータスに6をpush,入力Tを捨てる
    status 4 1 0
    results 2 + 1
![fig](images/s4-84.png)


--

## Reduce g0

    inputs + 3 $ 
    status 6 4 1 0
    results 2 + 1
![fig](images/s6.png)


--

## Reduce g0

    inputs + 3 $ 文法g0を見て、3個Pop、{$1+$2}を結果にpush、文法名Eを入力にpush
    status 6 4 1 0
    results 2 + 1
![fig](images/g0-43.png)


--

## Goto s1

    inputs E + 3 $ 
    status 0
    results 3
![fig](images/s0.png)


--

## Goto s1

    inputs E + 3 $ ステータスに1をpush,入力Eを捨てる
    status 0
    results 3
![fig](images/s0-69.png)


--

## Shift s4

    inputs + 3 $ 
    status 1 0
    results 3
![fig](images/s1.png)


--

## Shift s4

    inputs + 3 $ ステータスに4をpush 入力+を結果に移動
    status 1 0
    results 3
![fig](images/s1-43.png)


--

## Shift s2

    inputs 3 $ 
    status 4 1 0
    results + 3
![fig](images/s4.png)


--

## Shift s2

    inputs 3 $ ステータスに2をpush 入力3を結果に移動
    status 4 1 0
    results + 3
![fig](images/s4-78.png)


--

## Reduce g3

    inputs $ 
    status 2 4 1 0
    results 3 + 3
![fig](images/s2.png)


--

## Reduce g3

    inputs $ 文法g3を見て、1個Pop、{$1}を結果にpush、文法名Tを入力にpush
    status 2 4 1 0
    results 3 + 3
![fig](images/g3-36.png)


--

## Goto s6

    inputs T $ 
    status 4 1 0
    results 3 + 3
![fig](images/s4.png)


--

## Goto s6

    inputs T $ ステータスに6をpush,入力Tを捨てる
    status 4 1 0
    results 3 + 3
![fig](images/s4-84.png)


--

## Reduce g0

    inputs $ 
    status 6 4 1 0
    results 3 + 3
![fig](images/s6.png)


--

## Reduce g0

    inputs $ 文法g0を見て、3個Pop、{$1+$2}を結果にpush、文法名Eを入力にpush
    status 6 4 1 0
    results 3 + 3
![fig](images/g0-36.png)


--

## Goto s1

    inputs E $ 
    status 0
    results 6
![fig](images/s0.png)


--

## Goto s1

    inputs E $ ステータスに1をpush,入力Eを捨てる
    status 0
    results 6
![fig](images/s0-69.png)


--

## Accept

    inputs $ 
    status 1 0
    results 6
![fig](images/s1.png)


--

## Accept

    inputs $ アクセプト
    status 1 0
    results 6
![fig](images/s1-36.png)


--

## Accept

    inputs $ 結果 6 です
    status 1 0
    results 6
![fig](images/end.png)


--

# result 1\+2\+3 = 6

---

# 1\+2\*3

--

## Shift s2

    inputs 1 + 2 * 3 $ 
    status 0
    results 
![fig](images/s0.png)


--

## Shift s2

    inputs 1 + 2 * 3 $ ステータスに2をpush 入力1を結果に移動
    status 0
    results 
![fig](images/s0-78.png)


--

## Reduce g3

    inputs + 2 * 3 $ 
    status 2 0
    results 1
![fig](images/s2.png)


--

## Reduce g3

    inputs + 2 * 3 $ 文法g3を見て、1個Pop、{$1}を結果にpush、文法名Tを入力にpush
    status 2 0
    results 1
![fig](images/g3-43.png)


--

## Goto s3

    inputs T + 2 * 3 $ 
    status 0
    results 1
![fig](images/s0.png)


--

## Goto s3

    inputs T + 2 * 3 $ ステータスに3をpush,入力Tを捨てる
    status 0
    results 1
![fig](images/s0-84.png)


--

## Reduce g1

    inputs + 2 * 3 $ 
    status 3 0
    results 1
![fig](images/s3.png)


--

## Reduce g1

    inputs + 2 * 3 $ 文法g1を見て、1個Pop、{$1}を結果にpush、文法名Eを入力にpush
    status 3 0
    results 1
![fig](images/g1-43.png)


--

## Goto s1

    inputs E + 2 * 3 $ 
    status 0
    results 1
![fig](images/s0.png)


--

## Goto s1

    inputs E + 2 * 3 $ ステータスに1をpush,入力Eを捨てる
    status 0
    results 1
![fig](images/s0-69.png)


--

## Shift s4

    inputs + 2 * 3 $ 
    status 1 0
    results 1
![fig](images/s1.png)


--

## Shift s4

    inputs + 2 * 3 $ ステータスに4をpush 入力+を結果に移動
    status 1 0
    results 1
![fig](images/s1-43.png)


--

## Shift s2

    inputs 2 * 3 $ 
    status 4 1 0
    results + 1
![fig](images/s4.png)


--

## Shift s2

    inputs 2 * 3 $ ステータスに2をpush 入力2を結果に移動
    status 4 1 0
    results + 1
![fig](images/s4-78.png)


--

## Reduce g3

    inputs * 3 $ 
    status 2 4 1 0
    results 2 + 1
![fig](images/s2.png)


--

## Reduce g3

    inputs * 3 $ 文法g3を見て、1個Pop、{$1}を結果にpush、文法名Tを入力にpush
    status 2 4 1 0
    results 2 + 1
![fig](images/g3-42.png)


--

## Goto s6

    inputs T * 3 $ 
    status 4 1 0
    results 2 + 1
![fig](images/s4.png)


--

## Goto s6

    inputs T * 3 $ ステータスに6をpush,入力Tを捨てる
    status 4 1 0
    results 2 + 1
![fig](images/s4-84.png)


--

## Shift s5

    inputs * 3 $ 
    status 6 4 1 0
    results 2 + 1
![fig](images/s6.png)


--

## Shift s5

    inputs * 3 $ ステータスに5をpush 入力*を結果に移動
    status 6 4 1 0
    results 2 + 1
![fig](images/s6-42.png)


--

## Shift s7

    inputs 3 $ 
    status 5 6 4 1 0
    results * 2 + 1
![fig](images/s5.png)


--

## Shift s7

    inputs 3 $ ステータスに7をpush 入力3を結果に移動
    status 5 6 4 1 0
    results * 2 + 1
![fig](images/s5-78.png)


--

## Reduce g2

    inputs $ 
    status 7 5 6 4 1 0
    results 3 * 2 + 1
![fig](images/s7.png)


--

## Reduce g2

    inputs $ 文法g2を見て、3個Pop、{$1*$2}を結果にpush、文法名Tを入力にpush
    status 7 5 6 4 1 0
    results 3 * 2 + 1
![fig](images/g2-36.png)


--

## Goto s6

    inputs T $ 
    status 4 1 0
    results 6 + 1
![fig](images/s4.png)


--

## Goto s6

    inputs T $ ステータスに6をpush,入力Tを捨てる
    status 4 1 0
    results 6 + 1
![fig](images/s4-84.png)


--

## Reduce g0

    inputs $ 
    status 6 4 1 0
    results 6 + 1
![fig](images/s6.png)


--

## Reduce g0

    inputs $ 文法g0を見て、3個Pop、{$1+$2}を結果にpush、文法名Eを入力にpush
    status 6 4 1 0
    results 6 + 1
![fig](images/g0-36.png)


--

## Goto s1

    inputs E $ 
    status 0
    results 7
![fig](images/s0.png)


--

## Goto s1

    inputs E $ ステータスに1をpush,入力Eを捨てる
    status 0
    results 7
![fig](images/s0-69.png)


--

## Accept

    inputs $ 
    status 1 0
    results 7
![fig](images/s1.png)


--

## Accept

    inputs $ アクセプト
    status 1 0
    results 7
![fig](images/s1-36.png)


--

## Accept

    inputs $ 結果 7 です
    status 1 0
    results 7
![fig](images/end.png)


--

# result 1\+2\*3 = 7

---

# 2\*3\+4

--

## Shift s2

    inputs 2 * 3 + 4 $ 
    status 0
    results 
![fig](images/s0.png)


--

## Shift s2

    inputs 2 * 3 + 4 $ ステータスに2をpush 入力2を結果に移動
    status 0
    results 
![fig](images/s0-78.png)


--

## Reduce g3

    inputs * 3 + 4 $ 
    status 2 0
    results 2
![fig](images/s2.png)


--

## Reduce g3

    inputs * 3 + 4 $ 文法g3を見て、1個Pop、{$1}を結果にpush、文法名Tを入力にpush
    status 2 0
    results 2
![fig](images/g3-42.png)


--

## Goto s3

    inputs T * 3 + 4 $ 
    status 0
    results 2
![fig](images/s0.png)


--

## Goto s3

    inputs T * 3 + 4 $ ステータスに3をpush,入力Tを捨てる
    status 0
    results 2
![fig](images/s0-84.png)


--

## Shift s5

    inputs * 3 + 4 $ 
    status 3 0
    results 2
![fig](images/s3.png)


--

## Shift s5

    inputs * 3 + 4 $ ステータスに5をpush 入力*を結果に移動
    status 3 0
    results 2
![fig](images/s3-42.png)


--

## Shift s7

    inputs 3 + 4 $ 
    status 5 3 0
    results * 2
![fig](images/s5.png)


--

## Shift s7

    inputs 3 + 4 $ ステータスに7をpush 入力3を結果に移動
    status 5 3 0
    results * 2
![fig](images/s5-78.png)


--

## Reduce g2

    inputs + 4 $ 
    status 7 5 3 0
    results 3 * 2
![fig](images/s7.png)


--

## Reduce g2

    inputs + 4 $ 文法g2を見て、3個Pop、{$1*$2}を結果にpush、文法名Tを入力にpush
    status 7 5 3 0
    results 3 * 2
![fig](images/g2-43.png)


--

## Goto s3

    inputs T + 4 $ 
    status 0
    results 6
![fig](images/s0.png)


--

## Goto s3

    inputs T + 4 $ ステータスに3をpush,入力Tを捨てる
    status 0
    results 6
![fig](images/s0-84.png)


--

## Reduce g1

    inputs + 4 $ 
    status 3 0
    results 6
![fig](images/s3.png)


--

## Reduce g1

    inputs + 4 $ 文法g1を見て、1個Pop、{$1}を結果にpush、文法名Eを入力にpush
    status 3 0
    results 6
![fig](images/g1-43.png)


--

## Goto s1

    inputs E + 4 $ 
    status 0
    results 6
![fig](images/s0.png)


--

## Goto s1

    inputs E + 4 $ ステータスに1をpush,入力Eを捨てる
    status 0
    results 6
![fig](images/s0-69.png)


--

## Shift s4

    inputs + 4 $ 
    status 1 0
    results 6
![fig](images/s1.png)


--

## Shift s4

    inputs + 4 $ ステータスに4をpush 入力+を結果に移動
    status 1 0
    results 6
![fig](images/s1-43.png)


--

## Shift s2

    inputs 4 $ 
    status 4 1 0
    results + 6
![fig](images/s4.png)


--

## Shift s2

    inputs 4 $ ステータスに2をpush 入力4を結果に移動
    status 4 1 0
    results + 6
![fig](images/s4-78.png)


--

## Reduce g3

    inputs $ 
    status 2 4 1 0
    results 4 + 6
![fig](images/s2.png)


--

## Reduce g3

    inputs $ 文法g3を見て、1個Pop、{$1}を結果にpush、文法名Tを入力にpush
    status 2 4 1 0
    results 4 + 6
![fig](images/g3-36.png)


--

## Goto s6

    inputs T $ 
    status 4 1 0
    results 4 + 6
![fig](images/s4.png)


--

## Goto s6

    inputs T $ ステータスに6をpush,入力Tを捨てる
    status 4 1 0
    results 4 + 6
![fig](images/s4-84.png)


--

## Reduce g0

    inputs $ 
    status 6 4 1 0
    results 4 + 6
![fig](images/s6.png)


--

## Reduce g0

    inputs $ 文法g0を見て、3個Pop、{$1+$2}を結果にpush、文法名Eを入力にpush
    status 6 4 1 0
    results 4 + 6
![fig](images/g0-36.png)


--

## Goto s1

    inputs E $ 
    status 0
    results 10
![fig](images/s0.png)


--

## Goto s1

    inputs E $ ステータスに1をpush,入力Eを捨てる
    status 0
    results 10
![fig](images/s0-69.png)


--

## Accept

    inputs $ 
    status 1 0
    results 10
![fig](images/s1.png)


--

## Accept

    inputs $ アクセプト
    status 1 0
    results 10
![fig](images/s1-36.png)


--

## Accept

    inputs $ 結果 10 です
    status 1 0
    results 10
![fig](images/end.png)


--

# result 2\*3\+4 = 10

---

