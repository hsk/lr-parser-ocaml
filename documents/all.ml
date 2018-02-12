(* usage : ocaml -w -8-40 str.cma all.ml *)

module Token = struct
  type token = string (* トークン名 *)
  type any = string
  type tokenizedInput = token * any (* トークン名と、字句規則にマッチした元々の入力 *)

  type lexer = string -> tokenizedInput list

  let show_ts ts = "[" ^ String.concat ";" (List.map (fun t -> Printf.sprintf "%S" t) ts) ^ "]"
  let show_tokeninputs tis = "[" ^ String.concat ";" (List.map (fun (t,i) -> Printf.sprintf "%s" i) tis) ^ "]"
end
module Language = struct
  open Token

  type grammarCallback = (any list * token) -> any (* 構文のreduce時に呼び出されるコールバック *)
  type grammarRule = token * token list * grammarCallback option (* 単一の構文ルール *)
  type grammarDefinition = grammarRule list (* 構文規則 *)
  type language = grammarDefinition * token (* 言語定義 *)
  let language(grammar,start)=(grammar,start)

  let show_grammarRule = function
    | (token,ts,None) -> Printf.sprintf "(%S,%s,None)"  token (show_ts ts)
    | (token,ts,Some(_)) -> Printf.sprintf "(%S,%s,Some(_))" token (show_ts ts)  
  let show_grammarDef ls = "[" ^ String.concat ";" (List.map show_grammarRule ls) ^ "]"

  let show (grammar,start) =
    Printf.sprintf "(%s,%S)" (show_grammarDef grammar) start
end
module Parser = struct
  open Token
  open Language

  (* 構文解析器の実行する命令群 *)
  type op =
    | Accept
    | Shift of int
    | Reduce of int
    | Goto of int
    | Conflict of int list * int list (* Shift/Reduceコンフリクト *)

  let show_ls ls = "[" ^ String.concat ";" ls ^ "]"
  let show_ints ls =show_ls (List.map string_of_int ls)
  let show_op = function
    | Accept -> Printf.sprintf "Accept"
    | Shift(i) -> Printf.sprintf "Shift(%d)" i
    | Reduce(i) -> Printf.sprintf "Reduce(%d)" i
    | Goto(i) -> Printf.sprintf "Goto(%d)" i
    | Conflict(l,r) -> Printf.sprintf "Conflict(%s,%s)" (show_ints l) (show_ints r)

  (* 構文解析表 *)
  type parsingTable = (Token.token * op) list list

  let show1(p: (Token.token * op) list):string =
    show_ls (List.map (fun(t,op)->Printf.sprintf "%S,%s" t (show_op op)) p)

  let show (p:parsingTable) = show_ls (List.map show1 p)

  (* 構文解析器 *)
  type parserCallback = grammarDefinition -> (int * any list) -> any
  type parser = (grammarDefinition * parsingTable * parserCallback)

  let rec splitAt0 = function
    | (0, acc, res) -> (acc, res)
    | (n, acc, a :: res) -> splitAt0 (n - 1, a::acc, res)
    | _ -> failwith "stack is empty"

  let rec splitAt num stack = splitAt0 (num, [], stack)
  let rec pop num stack = let (_,stack) = splitAt num stack in stack

  let debug_mode = ref false

  let debug_out str = Printf.printf "%s\n%!" str
  let log fmt = Printf.kprintf (fun str -> debug_out str) fmt
  let logState(i,s,r) =
    if !debug_mode then
    log "%s %s %s" (show_tokeninputs i) (show_ls (List.map string_of_int s)) (show_ls r)
  let logOp op =
    if !debug_mode then log "%s" (show_op op); op
  (* 構文解析ステートマシン *)
  (* states 現在読んでいる構文解析表の状態番号を置くスタック *)
  (* results 解析中のASTノードを置くスタック *)
  let rec automaton parser inputs states results =
    logState(inputs,states,results);
    match (inputs,parser,states) with
    | ([], _, _) -> ("", results)
    | ((token,value)::inp,(grammar,parsingtable,callback), state::_) ->
      begin try match logOp(List.assoc token (List.nth parsingtable state)) with
      | Accept -> ("", results) (* 完了 *)
      | Shift(to1) -> automaton parser inp (to1 :: states) (value :: results)
      | Reduce(grammar_id) ->
        let (ltoken,pattern,_) = List.nth grammar grammar_id in
        let rnum = List.length pattern in
        let (children, results) = splitAt rnum results in  (* 右辺の記号の数だけポップ *)
        let ((state::_) as states) = pop rnum states in (* 対応する規則の右辺の記号の数だけポップ *)
        let results = callback(grammar_id, children) :: results in (* callback 実行 *)
        logState(inputs,states,results);
        (* 次は必ず Goto *)
        begin match logOp(List.assoc ltoken (List.nth parsingtable state)) with
        | Goto(to1) -> automaton parser inputs (to1 :: states) results
        | _ -> ("parse failed: goto operation expected after reduce operation", results)
        end
      | Conflict(shift_to, reduce_grammar) ->
        let err = Buffer.create 80 in
        let log str = Buffer.add_string err (str ^ "\n") in
        log "conflict found:";
        log ("current state " ^ string_of_int state ^ ":" ^ (show1 (List.nth parsingtable state)));
        log ("shift:" ^ show_ints shift_to ^ ",reduce:" ^ show_ints reduce_grammar);
        List.iter (fun to1 ->
          log (Printf.sprintf "shift to %d:%s" to1 (show1 (List.nth parsingtable to1)))
        ) shift_to;
        List.iter (fun (id: int) ->
          log (Printf.sprintf "reduce grammar %d:%s" id (show1 (List.nth parsingtable id)))
        ) reduce_grammar;
        log "parser cannot parse conflicted grammar";
        (Buffer.contents err, results)
      with Not_found ->
        (Printf.sprintf "parse failed: unexpected token:%s state: %d" token state, results) (* 未定義 *)
      end

  let parse grammar parsingtable callback (lexer:lexer) input =
    let (error,result_stack) = automaton (grammar,parsingtable,callback) (lexer input) [0] [] in
    if error <> "" then Printf.printf "%s\nparse failed.\n" error;
    if List.length result_stack <> 1 then Printf.printf "failed to construct tree.\n";
    List.nth result_stack 0

  (* Parserを生成するためのファクトリ *)
  let create grammar (_,parsingtable) =
    parse grammar parsingtable (fun (id, children) ->
      match List.nth grammar id with
      | (ltoken,_,Some(callback)) -> callback(children, ltoken)
      | _ -> List.nth children 0
    )
end
module Lexer = struct
  open Token

  type ptn = Str of string | Reg of string (* パターン *)
  type lexCallback = (any * any) -> any (* 字句規則マッチ時に呼び出されるコールバック *)
  type lexRule = token * ptn * lexCallback option (* 単一の字句ルール *)
  type lexDefinition = lexRule list(* 字句規則 *)

  let show_ptn = function
    | Str(s) -> Printf.sprintf "Str(%S)" s
    | Reg(s) -> Printf.sprintf "Reg(%S)" s
  let show_lexRule = function
    | (token,ptn,None) -> Printf.sprintf "(%S,%s,None)"  token (show_ptn ptn)
    | (token,ptn,Some(_)) -> Printf.sprintf "(%S,%s,Some(_))" token (show_ptn ptn)
  let show_lexDef ls = "[" ^ String.concat ";" (List.map show_lexRule ls) ^ "]"

  (* 入力からトークン1つ分読み込む *)
  let step lex callback (input:string): (string * tokenizedInput) =
    if input = "" then (input, ("EOF", "")) else (* 最後にEOFトークンを付与 *)
    (* プライオリティ付きで、最長一致かつ、文字列指定の場合は特別な制限付きなので全部探索する *)
    let (_,rv,rid) = lex |> ((0,"",-1) |> List.fold_left(
      fun (id,rv,rid) (token,ptn,_) ->
        let m = match ptn with
          | Reg ptn when Str.string_match (Str.regexp ptn) input 0 -> Some(Str.matched_string input)
          | Str ptn when String.length ptn > String.length input -> None
          | Str ptn when ptn = input -> Some ptn
          | Str ptn when String.sub input 0 (String.length ptn) <> ptn -> None
          (* マッチした文字列の末尾が\wで、その直後の文字が\wの場合はスキップ *)
          | Str ptn when not(Str.string_match (Str.regexp ".*[a-zA-Z_0-9]$") ptn 0) -> Some ptn
          | Str ptn when not(Str.string_match (Str.regexp "[a-zA-Z_0-9]") (Str.string_after input (String.length ptn)) 0) -> Some ptn
          | _ -> None
        in
        match (m, rid) with
        | (Some v,-1) ->                                        (id+1, v, id) (* 初めて見つかった場合 *)
        | (Some v,_) when String.length v > String.length rv -> (id+1, v, id) (* 同じ優先順のときは最長一致 *)
        | _ ->                                                  (id+1,rv,rid) (* それ以外は以前のものを使用 *)
    )) in
    match rid with
    | -1 -> Printf.printf "error [%s] %d\n%!" input (int_of_char (String.get input 0));
            failwith("no pattern matched") (* マッチする規則がなかった *)
    | rid -> (Str.string_after input (String.length rv), (List.nth lex rid |>(fun(token,_,_)->token), callback(rid, rv)))

  (* 与えられた入力をすべて解析し、トークン列を返す *)
  let exec lex callback input =
    let rec loop input res =
      match step lex callback input with
      | (i,(("EOF",_) as r)) -> List.rev (r::res)
      | (i, (""   ,_)      ) -> loop i res
      | (i,              r ) -> loop i (r::res)
    in
    loop input []

  (* exec の結果を文字列化 *)
  let show ls = "[" ^ String.concat ";" (List.map (fun (a,b)-> a^","^b) ls) ^ "]"

  (* 文字列を返す字句解析器を生成 *)
  let create lex:lexer = exec lex (fun (id, value) ->
    match List.nth lex id with
    | (token,_,Some(callback)) -> callback(value, token)
    | _ -> value
  )
end
module Yacc = struct
  module Utils = struct
    module Array = struct
      include Array
      let findIndex f array =
        let rec loop i = if f array.(i) then i else loop (i+1) in
        loop 0
      let slice arr s e = sub arr s (e - s)
      let add arr v = append arr [|v|]
    end
    module List = struct
      include List
      let rec splitAt0 = function
      | (0, acc, res) -> (acc, res)
      | (n, acc, a :: res) -> splitAt0 (n - 1, a::acc, res)
      | _ -> failwith "stack is empty"
      let rec splitAt num stack = splitAt0 (num, [], stack)
      let rec drop num stack = let (_,stack) = splitAt num stack in stack
    end
    module S = Set.Make(struct
      type t=string
      let compare=String.compare
    end)
    module M = struct
      module M = Map.Make(struct
        type t=string
        let compare=String.compare
      end)
      include M
      let fold_left f v t = List.fold_left f v (M.bindings t)
      let add_array k v map = add k (try Array.add (find k map) v with _ -> [|v|]) map
      let add_list k v list = add k (try (find k list) @ [v] with _ -> [v]) list
    end
    module MI = struct
      module MI = Map.Make(struct
        type t=int
        let compare i ii = i - ii
      end)
      include MI
      let fold_left f v t = List.fold_left f v (MI.bindings t)
    end
  end
  module Symboldiscriminator = struct
    open Language
    open Token
    open Utils

    (* 終端/非終端記号の判別を行う *)
    type symbolDiscriminator = {terminal_symbols: S.t; nonterminal_symbols: S.t}

    let genSymbolDiscriminator grammar : symbolDiscriminator =
      let nonterminal_symbols = grammar |>(* 構文規則の左辺に現れる記号は非終端記号 *)
        List.map(fun (ltoken,_,_)->ltoken) |> S.of_list
      in
      let terminal_symbols = List.fold_left(fun set (_,pattern,_) ->
        (* 非終端記号でない(=左辺値に現れない)場合、終端記号である *)
        pattern |>
          List.filter (fun symbol->not(S.mem symbol nonterminal_symbols)) |>
          (fun ptn -> List.fold_right S.add ptn set)
      ) S.empty grammar in
      {terminal_symbols; nonterminal_symbols}

    (* 与えられた記号が終端記号かどうかを調べる *)
    let isTerminalSymbol d symbol = S.mem symbol d.terminal_symbols

    (* 与えられた記号が非終端記号かどうかを調べる *)
    let isNonterminalSymbol d symbol = S.mem symbol d.nonterminal_symbols
  end
  module Nullableset = struct
    open Language
    open Token
    open Utils

    (* ある非終端記号から空列が導かれうるかどうかを判定する *)
    type nullableSet = S.t

    (* 空列になりうる記号の集合 nulls を導出 *)
    let generateNulls grammar : nullableSet =
      (* 右辺の記号の数が0の規則を持つ記号は空列になる *)
      let nulls = grammar |>
        List.filter(fun (_,pattern,_)->List.length pattern=0) |>
        List.map(fun (ltoken,_,_)->ltoken) |>
        S.of_list
      in
      (* さらに、空になる文法しか呼び出さない文法要素を追加する *)
      (* 要素を追加したらもう一回調べ直す必要があるのでループ *)
      let rec loop nulls =
        let add_grammer = grammar |> List.filter(fun (ltoken,pattern,_)-> (* 追加するのは *)
          not (S.mem ltoken nulls) && (* nullsに含まれておらず *)
          (* 右辺がすべてnullのもの。つまり、nullにならない要素が含まれないもの *)
          not (List.exists (fun a-> not (S.mem a nulls)) pattern)
        ) in
        if add_grammer = [] then nulls else(* 加えるものがなくなったら終了 *)
        (* 加える文法要素があれば、文法名を取り出し、追加してループします *)
        loop (add_grammer|>(List.fold_left (fun nulls (ltoken,_,_) -> S.add ltoken nulls) nulls))
      in
      loop nulls

    (* Token が Nullable かどうか *)
    let isNullable nulls token : bool = S.mem token nulls
  end
  module Firstset = struct
    open Language
    open Token
    open Utils
    open Nullableset
    open Symboldiscriminator

    (* First集合 *)
    type firstSet = {first_map: S.t M.t; nulls: nullableSet}

    type cons = token * token

    (* First集合を生成する *)
    let generateFirst grammar (symbols: symbolDiscriminator):firstSet =
      let nulls = generateNulls grammar in (* null集合を生成 *)
      (* 初期化 *)
      (* EOF は EOFだけ追加 *)
      let first_map = M.singleton "EOF" (S.singleton "EOF") in
      (* 終端記号 は自分そのものを追加 *)
      let first_map = List.fold_left (fun first_map value ->
        M.add value (S.singleton value) first_map
      ) first_map (S.elements symbols.terminal_symbols) in
      (* 非終端記号は空を追加 *)
      let first_map = List.fold_left (fun first_map value ->
        M.add value S.empty first_map
      ) first_map (S.elements symbols.nonterminal_symbols) in

      (* 右辺のnon-nullableな記号までを制約として収集 *)
      let constraints = grammar |> (List.fold_left (fun constraints (sup,pattern,_) ->
        let rec loop constraints = function
          | [] -> constraints
          | sub::pattern ->
            (* 自分の文法名以外を制約に含め *)
            let constraints = if sup = sub then constraints else (sup, sub)::constraints in
            (* nullable なら続ける *)
            if isNullable nulls sub then loop constraints pattern else constraints
        in
        loop constraints pattern
      ) []) in
      let constraints = List.rev constraints in

      (* 制約解消 *)
      let rec loop (first_map:S.t M.t) =
        (* 制約でループしてfirst集合を更新 *)
        let (changed,first_map) = constraints |> List.fold_left(fun (changed, first_map) (sup,sub) ->
            let old_set = M.find sup first_map in
            let new_set = S.union old_set (M.find sub first_map) in (* 制約の集合を追加 *)
            if S.equal old_set new_set then (changed, first_map) (* 変化なし *)
            else (true, M.add sup new_set first_map) (* 変化有りなので更新 *)
        ) (false,first_map) in
        if changed then loop first_map else first_map (* 変更あったら繰り返す *)
      in
      {first_map = loop first_map; nulls}


    (* 記号から非終端記号の集合を取得 *)
    let get (set:firstSet) token: S.t =
      try M.find token set.first_map with _ -> failwith("invalid token found: " ^ token)

    (* 記号列から最初に導かれる非終端記号の集合を取得 *)
    let getFromList (set:firstSet) tokens: S.t =
      let (_,result) = tokens |> ((false, S.empty)|>List.fold_left (fun (stop,result) token ->
        (* 不正な記号を発見 *)
        if not (M.mem token set.first_map) then failwith("invalid token found: " ^ token);
        if stop then (stop, result) else
        (* トークン列の先頭から順にFirst集合を取得 *)
        let result = S.union result (M.find token set.first_map) in (* 追加 *)
        let stop = not (isNullable set.nulls token) in (* 現在のトークン ∉ Nulls ならばここでストップ *)
        (stop, result)
      )) in
      result
  end
  module Grammardb = struct
    open Language
    open Token
    open Utils
    open Firstset
    open Symboldiscriminator

    (* 言語定義から得られる、構文規則に関する情報を管理するクラス *)
    type grammarDB = {
      grammar: grammarDefinition;
      start_symbol: token;
      first: firstSet;
      symbols: symbolDiscriminator;
      tokenmap: int M.t;
      rulemap: (int * grammarRule) array M.t
    }

    (* それぞれの記号にidを割り振り、Token->numberの対応を生成 *)
    let initTokenMap grammar : int M.t =
      let tokenid_counter = ref (-1) in
      let new_tokenid () =
        incr tokenid_counter;
        !tokenid_counter
      in
      let tokenmap = M.singleton "EOF" (new_tokenid()) in (* 入力の終端$の登録 *)
      let tokenmap = M.add "S'" (new_tokenid()) tokenmap in (* 仮の開始記号S'の登録 *)

      (* 左辺値の登録 *)
      let tokenmap = List.fold_left(fun (tokenmap:int M.t) (ltoken,_,_) ->
        (* 構文規則の左辺に現れる記号は非終端記号 *)
        if M.mem ltoken tokenmap then tokenmap else
        M.add ltoken (new_tokenid()) tokenmap
      ) tokenmap grammar in
      (* 右辺値の登録 *)
      List.fold_left(fun tokenmap (_,pattern,_) ->
        List.fold_left(fun tokenmap symbol ->
          if M.mem symbol tokenmap then tokenmap else
          (* 非終端記号でない(=左辺値に現れない)場合、終端記号である *)
          M.add symbol (new_tokenid()) tokenmap
        ) tokenmap pattern
      ) tokenmap grammar

    (* ある記号を左辺とするような構文ルールとそのidの対応を生成 *)
    let initDefMap grammar : (int * grammarRule) array M.t =
      let (_,rulemap) = List.fold_left(fun (i,(rulemap:(int * grammarRule) array M.t)) ((ltoken,_,_) as rule) ->
        (i+1, rulemap |> M.add_array ltoken (i, rule))
      ) (0,M.empty) grammar in
      rulemap

    let genGrammarDB ((grammar,start): language) :grammarDB =
      let symbols = genSymbolDiscriminator grammar in
      {
        grammar = grammar;
        start_symbol = start;
        first = generateFirst grammar symbols;
        symbols = symbols;
        tokenmap = initTokenMap grammar;
        rulemap = initDefMap grammar;
      }


    (* 構文規則がいくつあるかを返す ただし-1番の規則は含めない *)
    let rule_size db : int = List.length db.grammar

    (* 与えられたidの規則が存在するかどうかを調べる *)
    let hasRuleId db id : bool = id >= -1 && id < rule_size(db)

    (* 非終端記号xに対し、それが左辺として対応する定義を得る *)
    (* 対応する定義が存在しない場合は空の配列を返す *)
    let findRules db x : (int * grammarRule) array =
      try M.find x db.rulemap with _ -> [||]

    (* idから規則取得 *)
    let getRuleById db id : grammarRule =
      (* -1が与えられた時は S' -> S $の規則を返す *)
      if id = -1 then ("S'", [db.start_symbol], None)
      else if id >= 0 && id < List.length db.grammar then List.nth db.grammar id
      else failwith("grammar id out of range")

    (* tokenからid取得 *)
    let getTokenId db token =
      if not (M.mem token db.tokenmap) then failwith("invalid token " ^ token) else
      M.find token db.tokenmap
  end
  module Closureitem = struct
    open Token
    open Grammardb

    (* `S -> A . B [$]` のような LRアイテム *)
    type closureItem = {
      rule_id: int; dot_index: int; lookaheads: token list; (* 規則id・ドット位置・先読記号集合 *)
      lr0_hash: string; lr1_hash: string                     (* LR(0)、LR(1)アイテムのハッシュ値 *)
    }
    let show db {rule_id;dot_index;lookaheads} =
      let (label,param,_) = getRuleById db rule_id in
      let param = param |> List.mapi(fun i t -> if dot_index=i then ". "^t else t) in
      let param = if dot_index = List.length param then param @["."] else param in
      Printf.sprintf "%2d %s -> %s [%s]" rule_id label (String.concat " " param) (String.concat "," lookaheads)

    (* ハッシュ文字列を生成する *)
    let genHash db rule_id dot_index lookaheads =
      let la_hash = lookaheads |> List.map(fun t -> string_of_int (getTokenId db t)) in
      let lr0_hash = Printf.sprintf "%d,%d" rule_id dot_index in
      let lr1_hash = Printf.sprintf "%s,[%s]" lr0_hash (String.concat "," la_hash) in
      (lr0_hash, lr1_hash)

    let isSameLR0 ci1 ci2 = ci1.lr0_hash = ci2.lr0_hash
    let isSameLR1 ci1 ci2 = ci1.lr1_hash = ci2.lr1_hash

    (* 先読記号配列を、トークンid順にソート *)
    let sortLA db lookaheads =
      List.sort (fun t1 t2 -> getTokenId db t1 - getTokenId db t2) lookaheads

    let genClosureItem db rule_id dot_index lookaheads =
      if not (hasRuleId db rule_id) then failwith "invalid grammar id";
      if (dot_index < 0 || dot_index > List.length (let (_,pattern,_) = getRuleById db rule_id in pattern))
      then failwith "dot index out of range";
      if lookaheads = [] then failwith "one or more lookahead symbols needed";
      let lookaheads = sortLA db lookaheads in
      let (lr0_hash,lr1_hash) = genHash db rule_id dot_index lookaheads in
      {rule_id; dot_index; lookaheads; lr0_hash; lr1_hash}
  end
  module Closureset = struct
    open Token
    open Utils
    open Closureitem
    open Grammardb
    open Firstset
    open Symboldiscriminator

    (* 複数のLRアイテムを保持するアイテム集合 *)
    type closureSet = {items: closureItem list; lr0_hash: string; lr1_hash: string}

    let shows db items =
      items |> List.map (fun ci -> (Closureitem.show db ci) ^ "\n") |> String.concat ""

    let showis db items =
      items |> List.mapi (fun i ci -> Printf.sprintf "%d %s\n" i (Closureitem.show db ci)) |> String.concat ""

    let show db {items} = shows db items

    let showi db {items} = showis db items

    (* ハッシュ文字列を生成 *)
    let genHash cis =
      let lr0_hash = cis |> List.map (fun i->i.Closureitem.lr0_hash) in
      let lr1_hash = cis |> List.map (fun i->i.Closureitem.lr1_hash) in
      (String.concat "|" lr0_hash, String.concat "|" lr1_hash)

    let isSameLR0 cs1 cs2 = cs1.lr0_hash = cs2.lr0_hash
    let isSameLR1 cs1 cs2 = cs1.lr1_hash = cs2.lr1_hash

    (* 保持するClosureItemは、常にLR(1)ハッシュでソート *)
    let sort cis =
      List.sort(fun i1 i2 -> String.compare i1.Closureitem.lr1_hash i2.Closureitem.lr1_hash) cis

    let flat_items db (cis:closureItem list) =
      let separete (ci:closureItem):closureItem list = (* ClosureItemのlookaheadsを1つに分解 *)
        ci.lookaheads |> List.map (fun t -> genClosureItem db ci.rule_id ci.dot_index [ t ])
      in
      cis|>List.map separete|>List.concat

    (* クロージャー展開 *)
    let expand_closure db cis ci symbols follow_dot_symbol =
      let symbols = List.drop (ci.dot_index+1) symbols @ ci.lookaheads in
      let symbols = symbols |> Firstset.getFromList db.first |> S.elements in
      let symbols = symbols |> List.sort (fun t1 t2 -> getTokenId db t1 - getTokenId db t2) in
      (* follow_dot_symbol を左辺にもつ全ての規則を、先読み記号を付与して追加 *)
      findRules db follow_dot_symbol |>(cis|>Array.fold_left (fun cis (id,_) ->
        symbols|>(cis|>List.fold_left (fun cis symbol ->
          let new_ci = genClosureItem db id 0 [symbol] in
          if List.exists(fun ci -> Closureitem.isSameLR1 new_ci ci) cis then cis
          (* 重複がなければ新しいアイテムを追加する *)
          else cis @ [new_ci]
        ))
      ))

    (* クロージャー展開ループ *)
    let rec expand_closure_loop db i cis =
      (* Printf.printf "expand %d\n%s" i (showis db cis); *)
      (* 配列を拡張しながら配列がなくなるまでループ *)
      if i >= List.length cis then cis else expand_closure_loop db (i+1) (
        let ci = List.nth cis i in
        let symbols = getRuleById db ci.rule_id |> (fun (_,symbols,_) -> symbols) in
        if ci.dot_index >= List.length symbols then cis else (* .が末尾にある *)
        let follow_dot_symbol = List.nth symbols ci.dot_index in
        if isNonterminalSymbol db.symbols follow_dot_symbol then
          expand_closure db cis ci symbols follow_dot_symbol (* .の次の記号が非終端記号ならばクロージャー展開を行う *)
        else cis
      )

    (* ClosureItemの先読み部分をマージする *)
    let merge db cis =
      let rec loop ncis ts = function
        | [] -> List.rev ncis
        | ci::ci2::cis when Closureitem.isSameLR0 ci ci2 -> loop ncis (ts @ ci.lookaheads) (ci2::cis)
        | ci::cis -> loop (genClosureItem db ci.rule_id ci.dot_index (ts @ ci.lookaheads) :: ncis) [] cis
      in loop [] [] cis

    let genClosureSet db cis: closureSet =
      let cis = flat_items db cis |> sort in (* アイテム配列全体を分割してフラットにする *)
      let cis = expand_closure_loop db 0 cis |> sort in (* クロージャ展開をアイテム配列を拡張しながら行う *)
      let cis = merge db cis |> sort in (* マージする *)
      let (lr0_hash,lr1_hash) = genHash cis in (* ハッシュを生成する *)
      {items=cis; lr0_hash; lr1_hash}

    (* LRアイテムが集合に含まれているかどうかを調べる *)
    let includes(cs, ci) = List.exists(fun i -> Closureitem.isSameLR1 i ci) cs.items
  end
  module Dfagenerator = struct
    open Token
    open Utils
    open Closureitem
    open Closureset
    open Grammardb

    type edge = int M.t 
    type node = {closure: closureSet; edge: edge (* トークンからDFAのインデックスを示す *) }
    type dfa = node list

    let show_edge (edge:edge) =
      let s = edge |> M.bindings |> List.map(fun (t,i)-> Printf.sprintf "%s -> %d;" t i) |> String.concat "" in
      "[" ^ s ^ "]"

    let show db dfa =
      dfa |> List.map(fun{closure;edge}->
        Printf.sprintf "{closure=\n%sedge=%s\n}\n"
          (Closureset.showi db closure) (show_edge edge)
      ) |> String.concat ""
    let showi db dfa =
      dfa |> List.mapi(fun i {closure;edge}->
        Printf.sprintf "%d {closure=\n%sedge=%s\n}\n" i
          (Closureset.showi db closure) (show_edge edge)
      ) |> String.concat ""

    (* .を進めた記号からアイテム集合へのマップを生成 *)
    let generate_follow_dot_csmap db cs: closureSet M.t =
      cs.items |> (M.empty |> List.fold_left (fun map ci ->
        let (_,pattern,_) = getRuleById db ci.rule_id in
        if ci.dot_index = List.length pattern then map else (* .が末尾にある場合はスキップ *)
        let label = List.nth pattern ci.dot_index in
        map |> M.add_list label (genClosureItem db ci.rule_id (ci.dot_index + 1) ci.lookaheads)
      )) |> M.map (genClosureSet db) (* ClosureItemの配列からClosureSetに変換 *)

    let rec updateDFA db i (dfa, flg) =
      if i >= Array.length dfa then (dfa,flg) else updateDFA db (i+1) (
        (* .を進めた記号からアイテム集合へのマップを生成 *)
        let follow_dot_cs_map = generate_follow_dot_csmap db dfa.(i).closure in
        (* DFAノードを生成する *)
        follow_dot_cs_map |> ((dfa,flg) |> M.fold_left(fun (dfa,flg) (follow_label, follow_dot_cs) ->
          let (index,dfa,flg) = (* 既存のNodeのなかに同一のClosureSetを持つindexを検索 *)
            try (Array.findIndex(fun node -> Closureset.isSameLR1 follow_dot_cs node.closure) dfa,dfa,flg)
            with _ -> (* ない時はdfaを拡張する *)
              (Array.length dfa, Array.add dfa {closure=follow_dot_cs; edge=M.empty}, true)
          in
          if M.mem follow_label dfa.(i).edge then (dfa,flg) else begin (* 辺が含まれていないとき *)
            dfa.(i) <- {dfa.(i) with edge = M.add follow_label index dfa.(i).edge}; (* dfaに辺を追加 *)
            (dfa,true)
          end
        ))
      )

    (* DFAの生成 *)
    let generateLR1DFA db : dfa =
      [| { closure = genClosureSet db [genClosureItem db (-1) 0 ["EOF"]]; edge = M.empty} |] |>
      (* 変更がなくなるまでループ *)
      let rec loop dfa =
        (* Printf.printf "DFA\n%s" (showi db (Array.to_list dfa)); *)
        match updateDFA db 0 (dfa, false) with
        | dfa,true -> loop dfa
        | dfa,_ -> Array.to_list dfa
      in loop
  end
  module Lalr1dfa = struct
    open Utils
    open Dfagenerator
    open Grammardb
    open Closureitem

    (* LR0部分が同じ2つのClosureItemから先読部分をマージ *)
    let merge_item db ci1 ci2 =
      if not (isSameLR0 ci1 ci2) then failwith "null" else (* LR0部分が違う *)
      if isSameLR1 ci1 ci2 then ci1 else (* 完全一致 *)
      genClosureItem db ci1.rule_id ci1.dot_index ( (* ソートはgenClosureItem 内部で行われる *)
        S.union (S.of_list ci1.lookaheads) (S.of_list ci2.lookaheads) |> S.elements
      )

    (* LR(0)部分が同じ2つのClosureSetについて、先読み部分を統合した新しいClosureSetを生成 *)
    let merge_set db cs1 cs2: Closureset.closureSet =
      if not (Closureset.isSameLR0 cs1 cs2) then failwith "null" else (* LR0部分が違う *)
      (if Closureset.isSameLR1 cs1 cs2 then cs1 else (* LR1部分まで同じ *)
      Closureset.genClosureSet db (List.map2 (fun ci1 ci2 ->
        merge_item db ci1 ci2) cs1.Closureset.items cs2.Closureset.items))
      |> (fun p -> Printf.printf "merge\n[\n%s][\n%s]->[\n%s]\n"
                    (Closureset.show db cs1) (Closureset.show db cs2) (Closureset.show db p); p)

    (* LR(1)オートマトンの先読み部分をマージして、LALR(1)オートマトンを作る *)
    let generateLALR1DFA db lr_dfa : dfa =
      (* 配列をマージ *)
      let base = Array.of_list lr_dfa in
      let history = MI.empty|>(0|>let rec mergeLoop1 i history = (* i番目のマージ処理 *)
      if i >= Array.length base then history else mergeLoop1 (i+1) begin
        if MI.mem i history then history else (* マージ済 *)
        history|>((i+1)|>let rec mergeLoop2 ii history = (* i番とi番目以降のアイテム集合とマージ *)
        if ii >= Array.length base then history else mergeLoop2 (ii+1) begin
          if MI.mem ii history then history else (* マージ済 *)
          try (* とにかくマージを試みる *)
            base.(i) <- {base.(i) with closure=merge_set db base.(i).closure base.(ii).closure}; (* マージ *)
            MI.add ii i history (* 履歴更新 *)
          with _ -> history (* 失敗したら何もしない *)
        end in mergeLoop2)
      end in mergeLoop1) in
      (* マージした部分を取り出しつつ新旧対応表を作る *)
      let rec find_history o = (* マージ履歴を再帰的に検索 *)
        try find_history (MI.find o history) with _ -> o
      in
      let (_,_,nodes,old2new) = Array.fold_left (fun (o,n,nodes,old2new) node ->
        try (o+1,n,nodes,old2new|>MI.add o (old2new|>MI.find(find_history o))) (* マージ先oをold2newに保存する *)
        with _ -> (o+1,n+1,node::nodes,old2new|>MI.add o n) (* 検索失敗時はマージされていない *)
      ) (0,0,[],MI.empty) base in
      (* old2new対応表をもとに辺情報を書き換える *)
      nodes|>List.rev|>List.map (fun node -> {node with edge=node.edge |> M.map (fun o -> MI.find o old2new)})
  end
  module Parsergenerator = struct
    open Language
    open Token
    open Utils
    open Parser
    open Dfagenerator
    open Lalr1dfa
    open Grammardb
    open Closureset
    open Closureitem
    open Symboldiscriminator

    (* DFAから構文解析表を構築する *)
    let generateParsingTable db dfa table_type : (string * parsingTable) =
      let table_type = ref table_type in
      let dfa_to_table_element node =
        (* 辺をもとにshiftとgotoオペレーションを追加 *)
        let table_row = M.fold_left(fun table_row (label, to1) ->
          if isTerminalSymbol db.symbols label then M.add label (Shift(to1)) table_row
          else if isNonterminalSymbol db.symbols label then M.add label (Goto(to1)) table_row
          else table_row
        ) M.empty node.edge in
        (* Closureをもとにacceptとreduceオペレーションを追加していく *)
        let table_row = List.fold_left (fun table_row (item:closureItem) ->
          let (_,pattern,_) = getRuleById db item.rule_id in
          (* 規則末尾が.でないならスキップ *)
          if item.dot_index <> List.length pattern then table_row else
          if item.rule_id = -1 then M.add "EOF" Accept table_row else
          List.fold_left(fun table_row label ->
            (* 既に同じ記号でオペレーションが登録されていないか確認 *)
            if not (M.mem label table_row) then M.add label (Reduce(item.rule_id)) table_row
            else begin (* コンフリクトが発生 *)
              table_type := "CONFLICTED"; (* 構文解析に失敗 *)
              let conflicted =
                match M.find label table_row with
                | Shift(to1) -> Conflict([to1],[item.rule_id]) (* shift/reduce コンフリクト *)
                | Reduce(grammar_id) -> Conflict([], [grammar_id; item.rule_id]) (* reduce/reduce コンフリクト *)
                | Conflict(shift_to, reduce_grammar) ->
                  Conflict(shift_to, reduce_grammar @ [item.rule_id]) (* もっとやばい衝突 *)
                | _ -> Conflict([], [])
              in
              (* とりあえず衝突したオペレーションを登録しておく *)
              M.add label conflicted table_row
            end
          ) table_row item.lookaheads
        ) table_row node.closure.items in
        M.bindings table_row
      in
      let table = dfa |> List.map dfa_to_table_element in
      (!table_type, table)

    (* 言語定義から構文解析表および構文解析器を生成するパーサジェネレータ *)
    let generate language : (string * parsingTable) =
      let db = genGrammarDB language in
      let (lr_dfa:dfa) = generateLR1DFA db in
      let (lalr_dfa:dfa) = generateLALR1DFA db lr_dfa in
      let (table_type, lalr_table) = generateParsingTable db lalr_dfa "LALR1" in
      if table_type <> "CONFLICTED" then (table_type, lalr_table)
      else begin
        (* LALR(1)構文解析表の生成に失敗 *)
        (* LR(1)構文解析表の生成を試みる *)
        Printf.printf "LALR parsing conflict found. use LR(1) table.\n";
        let (table_type, lr_table) = generateParsingTable db lr_dfa "LR1" in
        if table_type <> "CONFLICTED" then (table_type, lr_table)
        else begin
          (* LR(1)構文解析表の生成に失敗 *)
          Printf.fprintf stderr "LR(1) parsing conflict found. use LR(1) conflicted table.\n";
          (table_type, lr_table)
        end
      end
    (* 言語定義から構文解析表および構文解析器を生成するパーサジェネレータ *)
    let generateLR1 language : (string * parsingTable) =
      let db = genGrammarDB language in
      let lr_dfa = generateLR1DFA db in
      generateParsingTable db lr_dfa "LR1"

    (* 生成された構文解析表に衝突が発生しているかどうかを調べる *)
    let isConflicted (table_type, _): bool = table_type = "CONFLICTED"
  end
end

open Token
open Language
open Parser

let lex: Lexer.lexDefinition = [
  "",        Reg"\\(\\r\\n\\|\\r\\|\\n\\)+",None;
  "",        Reg"[ \\t]+",                  None;
  "NUM",     Reg"[1-9][0-9]*",              None;
  "+",       Str"+",                        None;
  "*",       Str"*",                        None;
  "INVALID", Reg".",                        None;
]

let grammar: grammarDefinition = [
  "E",["E";"+";"T"],  Some(fun([c0;_;c2],_) -> string_of_int((int_of_string c0) + (int_of_string c2)));
  "E",["T"],          Some(fun([c0],_) -> c0);
  "T",["T";"*";"NUM"],Some(fun([c0;_;c2],_) -> string_of_int((int_of_string c0) * (int_of_string c2)));
  "T",["NUM"],        Some(fun([c0],_) -> c0);
]

let language = (grammar,"E")

let parsing_table : parsingTable = [
  ["NUM",Shift(2);                                            "E",Goto(1);"T",Goto(3);]; (* 0 *)
  [               "+",Shift (4);              "EOF",Accept   ;                        ]; (* 1 *)
  [               "+",Reduce(3);"*",Reduce(3);"EOF",Reduce(3);                        ]; (* 2 *)
  [               "+",Reduce(1);"*",Shift (5);"EOF",Reduce(1);                        ]; (* 3 *)
  ["NUM",Shift(2);                                                        "T",Goto(6);]; (* 4 *)
  ["NUM",Shift(7);                                                                    ]; (* 5 *)
  [               "+",Reduce(0);"*",Shift (5);"EOF",Reduce(0);                        ]; (* 6 *)
  [               "+",Reduce(2);"*",Reduce(2);"EOF",Reduce(2);                        ]; (* 7 *)
]

let test parser =
  assert(parser "8"       = "8");
  assert(parser "2*3+4"   = "10");
  assert(parser "1+2*3"   = "7");
  assert(parser "1+2"     = "3");
  ()

let _ =
  (*Parser.debug_mode := true;*)
  let parser = Parser.create grammar ("",parsing_table) (Lexer.create lex) in
  test parser

let _ =
  let table = Yacc.Parsergenerator.generate language in
  let parser = Parser.create grammar table (Lexer.create lex) in
  test parser
