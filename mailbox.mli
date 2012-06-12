(*
    Copyright 1999-2011 Pascal Brisset / Jean-Marc Alliot

    This file is part of the ocaml pvm library.

    The ocaml pvm library is free software: 
    you can redistribute it and/or modify it under the terms of 
    the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    The ocaml pvm library is distributed in the hope that it will be 
    useful,but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public 
    License along with the ocaml pvm library.  
    If not, see <http://www.gnu.org/licenses/>.
*)
(* $Id: mailbox.mli 2824 2003-09-19 14:04:03Z brisset $ *)

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
