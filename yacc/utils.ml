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
end

module MI = struct
  module MI = Map.Make(struct
    type t=int
    let compare i ii = i - ii
  end)
  include MI
  let fold_left f v t = List.fold_left f v (M.bindings t)
end
