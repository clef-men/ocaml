(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*                Clément Allain, projet Cambium, INRIA Paris             *)
(*               Gabriel Scherer, projet Cambium, INRIA Paris             *)
(*                                                                        *)
(*   Copyright 2024 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

type _ t =
  Obj.t array

external atomic_unsafe_index
  : 'a t -> int -> 'a Atomic.Loc.t
  = "%atomic_unsafe_index"
external atomic_index
  : 'a t -> int -> 'a Atomic.Loc.t
  = "%atomic_index"

let length =
  Array.length

let unsafe_get t i =
  Atomic.Loc.get (atomic_unsafe_index t i)
let get t i =
  Atomic.Loc.get (atomic_index t i)

let unsafe_set t i v =
  Atomic.Loc.set (atomic_unsafe_index t i) v
let set t i v =
  Atomic.Loc.set (atomic_index t i) v

let unsafe_exchange t i v =
  Atomic.Loc.exchange (atomic_unsafe_index t i) v
let exchange t i v =
  Atomic.Loc.exchange (atomic_index t i) v

let unsafe_compare_and_set t i old new_ =
  Atomic.Loc.compare_and_set (atomic_unsafe_index t i) old new_
let compare_and_set t i old new_ =
  Atomic.Loc.compare_and_set (atomic_index t i) old new_

let unsafe_fetch_and_add t i incr =
  Atomic.Loc.fetch_and_add (atomic_unsafe_index t i) incr
let fetch_and_add t i incr =
  Atomic.Loc.fetch_and_add (atomic_index t i) incr

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
