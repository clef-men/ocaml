type 'a t

val length :
  'a t -> int

val unsafe_get :
  'a t -> int -> 'a
val get :
  'a t -> int -> 'a

val unsafe_set :
  'a t -> int -> 'a -> unit
val set :
  'a t -> int -> 'a -> unit

val unsafe_exchange :
  'a t -> int -> 'a -> 'a
val exchange :
  'a t -> int -> 'a -> 'a

val unsafe_compare_and_set :
  'a t -> int -> 'a -> 'a -> bool
val compare_and_set :
  'a t -> int -> 'a -> 'a -> bool

val unsafe_fetch_and_add :
  int t -> int -> int -> int
val fetch_and_add :
  int t -> int -> int -> int

val make :
  int -> 'a -> 'a t

val init :
  int -> (int -> 'a) -> 'a t
