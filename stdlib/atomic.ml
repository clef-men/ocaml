(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*                 Stephen Dolan, University of Cambridge                 *)
(*                                                                        *)
(*   Copyright 2017-2018 University of Cambridge.                         *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

module Loc = struct
  type 'a t =
    'a atomic_loc

  external exchange : 'a t -> 'a -> 'a = "%atomic_exchange_loc"
  external compare_and_set : 'a t -> 'a -> 'a -> bool = "%atomic_cas_loc"
  external fetch_and_add : int t -> int -> int = "%atomic_fetch_add_loc"
end

type 'a t =
  { mutable contents: 'a [@atomic];
  }

let make v =
  { contents= v }

external make_contended : 'a -> 'a t = "caml_atomic_make_contended"

let get t =
  t.contents
let set t v =
  t.contents <- v

let exchange t v =
  Loc.exchange [%atomic.loc t.contents] v
let compare_and_set t old new_ =
  Loc.compare_and_set [%atomic.loc t.contents] old new_
let fetch_and_add t incr =
  Loc.fetch_and_add [%atomic.loc t.contents] incr

external ignore : 'a -> unit = "%ignore"
let incr r =
  ignore (fetch_and_add r 1)
let decr r =
  ignore (fetch_and_add r (-1))
