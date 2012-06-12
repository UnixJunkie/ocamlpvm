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
(* $Id: mailbox.ml 2824 2003-09-19 14:04:03Z brisset $ *)

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

module Make (T:T) = struct
  type t = T.t

  module IndexSet = 
    Set.Make(struct 
      type t =  Pvm.mboxindex
      let compare x y = compare x y end)
      
  type idm = string *  IndexSet.t ref
  type idt = Pvm.mboxindex
	
  let mytid = Pvm.mytid ()


  let connect mboxname = (mboxname,ref IndexSet.empty)

  let put (mboxname,s) t =
    let bufid = Pvm.initsend Pvm.DataDefault in
    let _ = Pvm.pkobj t in
    let index = Pvm.putinfo mboxname bufid in
    s := IndexSet.add index !s;
    index

  let get (mboxname,s) idt = 
    let bufid = Pvm.recvinfo mboxname idt in
    (Pvm.upkobj ())

  let delete (mboxname,s) idt = 
    Pvm.delinfo mboxname idt;
    s := IndexSet.remove idt !s

  let delete_all_mine (mboxname,s) = 
    IndexSet.iter (fun idt -> Pvm.delinfo mboxname idt) !s;
    s := IndexSet.empty

  let get_all mboxname =
    let infos = Pvm.getmboxinfo mboxname in
    let s2 = ref IndexSet.empty in
    Array.iter (fun x-> s2 := IndexSet.add x !s2) infos.(0).Pvm.mi_indices;
    !s2;;
    
  let choose_other (mboxname,s) = 
    let s2 = get_all mboxname in
    if  IndexSet.cardinal s2 > IndexSet.cardinal !s then begin
      let s3 = IndexSet.diff s2 !s in
      let idt = IndexSet.choose s3 in
      let bufid = Pvm.recvinfo mboxname idt in
      Pvm.upkobj ()
    end
    else raise Not_found

  let iter_other (mboxname,s) f = 
    IndexSet.iter 
      (fun idt -> f (get (mboxname,s) idt))
      (IndexSet.diff (get_all mboxname) !s)

  let iter_all (mboxname,s) f = 
    IndexSet.iter 
      (fun idt -> f (get (mboxname,s) idt))
      (get_all mboxname)

  let iter_mine (mboxname,s) f = 
    IndexSet.iter 
      (fun idt -> f (get (mboxname,s) idt))
      !s

end

(*
  let exchange_elts m =
    (match !mboxindex with
      None -> ()
    | Some index -> Pvm.delinfo mboxname index);
    let bufid = Pvm.initsend Pvm.pvmDataDefault in
    let _ = Pvm.pkobj m in
    let index = Pvm.putinfo mboxname bufid in
    mboxindex := Some index;
    try
      let infos = Pvm.getmboxinfo mboxname in
      let nb = Array.length infos.(0).Pvm.mi_indices in
      if  nb > 1 then begin
      	let num = Random.int nb in
      	let rnum =       	
	  if infos.(0).Pvm.mi_indices.(num) = index
	  then (num+1) mod nb
      	  else num in
      	let bufid = Pvm.recvinfo 
	    mboxname infos.(0).Pvm.mi_indices.(rnum) in
      	(Pvm.upkobj ())
      end
      else
	raise Not_Found
    with 
      Failure s -> 
      	Printf.fprintf stderr "Erreur dans reception:%s\n" s;flush stdout
*)



