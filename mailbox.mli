(* $Id: mailbox.mli,v 1.2 2003/09/19 14:04:03 brisset Exp $ *)

module type T =
    sig
      type t
    end

module type P = 
    sig
      type t
      type idm
      type idt
      val connect : string -> idm
      val put : idm -> t -> idt
      val get : idm -> idt -> t
      val delete : idm -> idt -> unit
      val delete_all_mine : idm -> unit
      val choose_other : idm -> t
      val iter_all : idm ->  (t -> unit) -> unit
      val iter_other : idm ->  (t -> unit) -> unit
      val iter_mine : idm ->  (t -> unit) -> unit
    end

module Make (T:T) : (P with type t = T.t)
