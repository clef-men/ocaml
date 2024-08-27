# Atomic record fields

Example:

```ocaml
type t = {
  mutable current : int;
  mutable readers: int [@atomic];
}

let add_new_reader v =
  Atomic.Loc.incr [%atomic.loc v.readers]
```

This PR is implemented by myself (@clef-men) with help from @gasche, including for this PR description.

It is ready for review. We did our best to have a clean git history, so reading the PR commit-by-commit is recommended.

This PR sits on top of #13396, #13397 and #13398.
(Helping make decisions on those PRs will help the present PR move forward.)

(cc @OlivierNicole, @polytypic)

## Why

Current OCaml 5 only supports atomic operations on a special type `'a Atomic.t` of atomic references, which are like `'a ref` except that access operations are atomic. When implementing concurrent data structures, it would be desirable for performance to have records with atomic fields, instead of having an indirection on each atomic field -- just like `mutable x : foo` is more efficient than `x : foo ref`. This is also helpful when combined with inline records inside variant construcors.

## Design

This PR implements the "Atomic Record Fields" RFC
  https://github.com/ocaml/RFCs/pull/39
more specifically the "design number 2" from
  https://github.com/ocaml/RFCs/pull/39#issuecomment-2165173583
proposed by @bclement-ocp.

(The description below is self-contained, reading the RFC and is discussion is not necessary.)

We implement two features in sequence, as described in the RFC.

First, atomic record fields are just record fields marked with an `[@atomic]` attribute. Reads and writes to these fields are compiled to atomic operations. In our example, the field `readers` is marked atomic, to `v.readers` and `v.readers <- 42` will be compiled to an atomic read and an atomic write.

Second, we implement "atomic locations", which is a compiler-supported way to describe an atomic field within a record to perform other atomic operations than read and write. Continuing this example, `[%atomic.loc v.readers]` has type `int Atomic.Loc.t`, which indicates an atomic location of type `int`. The submodule `Atomic.Loc` exposes operations similar to `Atomic`, but on this new type `Atomic.Loc.t`.

Currently the only atomic locations supported are atomic record fields. In the future we hope to expose atomic arrays using a similar approach, but we limit the scope of the current PR to record fields.


## Implementation (high-level)

- In trunk, `Atomic.get` is implemented by a direct memory access, but all other `Atomic` primitives are implemented in C, for example:
  
   `value caml_atomic_exchange(value ref, value newval)`
  
   We preserve this design, but introduce new C functions that take a pointer and an offset instead of just an atomic reference, for example:
   
   `value caml_atomic_exchange_field(value obj, value vfield, value newval)`

   (The old functions are kept around for backward-compatibility reasons, redefined from the new ones with offset `0`.)

- Internally, a value of type `'a Atomic.Loc.t` is a pair of a block and an offset inside the block. With the example above, `[%atomic.loc v.readers]` is the pair `(v, 1)`, indicating the second field of the record `v`. The call `Atomic.Loc.exchange [%atomic.loc v.readers] x` gets rewritten to something like `%atomic_exchange_field v 1 x`, which will eventually become the C call `caml_atomic_exchange_field(v, Val_long(1), x)`. (When an atomic primitive is directly applied to an `[%atomic.loc ...]` expression, the compiler eliminates the pair construction on the fly. If it is passed around as a first-class location, then the pair may be constructed.)

- We reimplement the `Atomic.t` type as a record with a single atomic field, and the corresponding functions become calls to the `Atomic.Loc.t` primitives, with offset `0`.

After this PR, the entire code of `stdlib/atomic.ml` is as follows. (`'a atomic_loc` is a new builtin/predef type, used to typecheck the `[%atomic.loc ..]` construction.)

```ocaml
external ignore : 'a -> unit = "%ignore"

module Loc = struct
  type 'a t = 'a atomic_loc

  external get : 'a t -> 'a = "%atomic_load_loc"
  external exchange : 'a t -> 'a -> 'a = "%atomic_exchange_loc"
  external compare_and_set : 'a t -> 'a -> 'a -> bool = "%atomic_cas_loc"
  external fetch_and_add : int t -> int -> int = "%atomic_fetch_add_loc"

  let set t v =
    ignore (exchange t v)
  let incr t =
    ignore (fetch_and_add t 1)
  let decr t =
    ignore (fetch_and_add t (-1))
end

type !'a t = { mutable contents: 'a [@atomic]; }

let make v = { contents= v }

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
let incr t =
  Loc.incr [%atomic.loc t.contents]
let decr t =
  Loc.decr [%atomic.loc t.contents]
```

There is currently no support for something similar to `Atomic.make_contented` (placing values on isolated cache lines to avoid false sharing) for records with atomic fields . Workflows that require `make_contended` must stick to the existing `Atomic.t` type. Allocation directives for records or record fields could be future work -- outside the scope of the present PR.
