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
