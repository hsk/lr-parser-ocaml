  (**
   * Parserを生成するためのファクトリクラス
   *)
module Make(D:sig
  val language: Language.language
  val parsingtable: Parsingtable.parsingTable
end) = struct

  module C = Callback.DefaultCallbackController.Make(struct let language=D.language end)
  module P = Parser.Make(C)
  module P2 = P.Make(struct let parsingtable=D.parsingtable end)
  include P2
end

module MakeAst(D:sig
  val language: Language.language
  val parsingtable: Parsingtable.parsingTable
end) = struct

  module C = Callback.ASTConstructor.Make(struct let language=D.language end)
  module P = Parser.Make(C)
  module P2 = P.Make(struct let parsingtable=D.parsingtable end)
  include P2
end
