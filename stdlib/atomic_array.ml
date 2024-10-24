type _ t =
  Obj.t array

external isout : int -> int -> bool = "%isout"
external atomic_index : 'a t -> int -> 'a Atomic.Loc.t = "%atomic_index"

let length =
  Array.length

let[@inline] check_index t i msg =
  let len = length t in
  if len <= 0 || isout (len - 1) i then
    invalid_arg msg

let[@inline] unsafe_get t i =
  Atomic.Loc.get (atomic_index t i)
let get t i =
  check_index t i "Atomic_array.get" ;
  unsafe_get t i

let[@inline] unsafe_set t i v =
  Atomic.Loc.set (atomic_index t i) v
let set t i v =
  check_index t i "Atomic_array.set" ;
  unsafe_set t i v

let[@inline] unsafe_exchange t i v =
  Atomic.Loc.exchange (atomic_index t i) v
let exchange t i v =
  check_index t i "Atomic_array.exchange" ;
  unsafe_exchange t i v

let[@inline] unsafe_compare_and_set t i old new_ =
  Atomic.Loc.compare_and_set (atomic_index t i) old new_
let compare_and_set t i old new_ =
  check_index t i "Atomic_array.compare_and_set" ;
  unsafe_compare_and_set t i old new_

let[@inline] unsafe_fetch_and_add t i incr =
  Atomic.Loc.fetch_and_add (atomic_index t i) incr
let fetch_and_add t i incr =
  check_index t i "Atomic_array.fetch_and_add" ;
  unsafe_fetch_and_add t i incr

let make len v =
  if len < 0 then
    invalid_arg "Atomic_array.make" ;
  if Obj.(tag @@ repr v == double_tag) then
    let t = Array.make len (Obj.magic ()) in
    for i = 0 to len - 1 do
      unsafe_set t i v
    done ;
    t
  else
    Array.make len (Obj.repr v)

let init len fn =
  if len < 0 then
    invalid_arg "Atomic_array.init" ;
  let t = Array.make len (Obj.magic ()) in
  for i = 0 to len - 1 do
    unsafe_set t i (fn i)
  done ;
  t
