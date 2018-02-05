module Array = struct
  include Array
  let findIndex f array =
    let rec loop i = if f array.(i) then i else loop (i+1) in
    loop 0
  let slice arr s e = sub arr s (e - s)
  let add arr v = append arr [|v|]
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
end

module MI = struct
  module MI = Map.Make(struct
    type t=int
    let compare i ii = i - ii
  end)
  include MI
  let fold_left f v t = List.fold_left f v (MI.bindings t)
end
