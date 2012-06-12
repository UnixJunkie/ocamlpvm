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
(* $Id: pvm.ml 2825 2006-07-12 13:22:22Z olive $ *)

type tid = int
type encoding = DataDefault | DataRaw | DataInPlace
type bufid=int
type msgtag=int
type stride = int
type eventkind = HostDelete | HostAdd | TaskExit
type mboxindex = int
type instnum = int
type groupname = string
type processor={
  proc_name:string;
  proc_arch:string;
  proc_speed:int
  }

type mboxinfo = {
    mi_name : string;
    mi_indices : int array;
    mi_owners : tid array
  } ;;

type catching = 
    No_Catch
  | Stdout_Catch;;
type spawn_flag =
    TaskDefault
  | TaskHost		(* specify host *)
  | TaskArch		(* specify architecture *)
  | TaskDebug	(* start task in debugger *)
  | TaskTrace	(* process generates trace data *)
  | MppFront		(* spawn task on service node *)
  | HostCompl	(* complement host set *)
  | NoSpawnParent    (* for parent-less spawning *)

type spawn_result = Tid of tid | Fault of exn

type taskinfo = {
    ti_tid : tid;	(* Task id *)
    ti_ptid : tid;	(* parent tid *)
    ti_host : tid;	(* pvmd tid *)
    ti_flag : int ;	(* status flags *)
    ti_a_out : string;	(* a.out name *)
    ti_pid : int       (* task (O/S dependent) process id *)
}

type mbox_flags =
    MboxDefault	(* put: single locked instance *)
		(* recv: 1st entry *)
                (* start w/index=0 *)
  | MboxPersistent	(* entry remains after owner exit *)
  | MboxMultiInstance        (* multiple entries in class *)
  | MboxOverWritable		(* can write over this entry *)
  | MboxFirstAvail		(* select 1st index >= specified *)
  | MboxReadAndDelete		(* atomic read / delete *)
                                        (* requires read & delete rights *)

let int_of_msgtag x = x
let msgtag_of_int x = x
let stride_of_int x = x
let int_of_tid x = x
let int_of_bufid x = x

let invalidBuf  = 0


let error_messages = [
  (0, "PvmOk");		(* Success *)
  (-2, "PvmBadParam");	(* Bad parameter *)
  (-3, "PvmMismatch");	(* Parameter mismatch *)
  (-4, "PvmOverflow");	(* Value too large *)
  (-5, "PvmNoData");	(* End of buffer *)
  (-6, "PvmNoHost");	(* No such host *)
  (-7, "PvmNoFile");	(* No such file *)
  (-8, "PvmDenied");	(* Permission denied *)
  (-10, "PvmNoMem");	(* Malloc failed *)
  (-12, "PvmBadMsg");	(* Can't decode message *)
  (-14, "PvmSysErr");	(* Can't contact local daemon *)
  (-15, "PvmNoBuf");	(* No current buffer *)
  (-16, "PvmNoSuchBuf");	(* No such buffer *)
  (-17, "PvmNullGroup");	(* Null group name *)
  (-18, "PvmDupGroup");	(* Already in group *)
  (-19, "PvmNoGroup");	(* No such group *)
  (-20, "PvmNotInGroup");	(* Not in group *)
  (-21, "PvmNoInst");	(* No such instance *)
  (-22, "PvmHostFail");	(* Host failed *)
  (-23, "PvmNoParent");	(* No parent task *)
  (-24, "PvmNotImpl");	(* Not implemented *)
  (-25, "PvmDSysErr");	(* Pvmd system error *)
  (-26, "PvmBadVersion");	(* Version mismatch *)
  (-27, "PvmOutOfRes");	(* Out of resources *)
  (-28, "PvmDupHost");	(* Duplicate host *)
  (-29, "PvmCantStart");	(* Can't start pvmd *)
  (-30, "PvmAlready");	(* Already in progress *)
  (-31, "PvmNoTask");	(* No such task *)
  (-32, "PvmNotFound");	(* Not Found *)
  (-33, "PvmExists");	(* Already exists *)
  (-34, "PvmHostrNMstr");	(* Hoster run on non-master host *)
  (-35, "PvmParentNotSet")(* Spawning parent set PvmNoSpawnParent *)
];;		

external mytid : unit ->tid = "Pvm_mytid"
external config : unit -> processor array = "Pvm_config"

external getmboxinfo : string -> mboxinfo array = "Pvm_getmboxinfo"
external putinfo : string -> bufid -> mboxindex = "Pvm_putinfo"
external delinfo : string -> mboxindex -> unit = "Pvm_delinfo"
external recvinfo : string -> mboxindex -> mbox_flags list -> bufid = "Pvm_recvinfo"

external cspawn : string -> string array -> int -> string -> int -> int array -> int= "Pvm_cspawn" "Pvm_spawn_native"

type c = unit
external recvf : (bufid -> tid -> msgtag -> int) -> c = "Pvm_recvf"
external reset_recvf : c -> unit = "Pvm_reset_recvf"

let spawn task argv flags host ntasks =
  assert(ntasks >= 0);
  let code_flags =
    [TaskDefault,0; TaskHost, 1; TaskArch, 2; TaskDebug, 4;
      TaskTrace, 8; MppFront,16; HostCompl,32; NoSpawnParent,64] in
  let encoded_flags = List.fold_right (fun x r -> List.assoc x code_flags + r) flags 0 in
  let tids = Array.create ntasks 0 in
  let numt = cspawn task argv encoded_flags host ntasks tids in
  Array.map
    (fun tid ->
      if tid < 0
      then Fault (Failure (List.assoc tid error_messages))
      else Tid tid)
    tids;;

let simple_spawn task host =
  match (if host <> "" then spawn task [||] [TaskHost] host 1 else spawn task [||] [TaskDefault] "" 1).(0) with
    Tid t -> t
  | Fault e -> raise e

external initsend : encoding -> bufid = "Pvm_initsend"
let anyMsgTag : msgtag= -1
let anyTid : tid= -1
external send : tid -> msgtag -> unit = "Pvm_send"
external mcast :  tid array -> msgtag -> unit = "Pvm_mcast"
external recv : tid -> msgtag -> bufid = "Pvm_recv"
external trecv : tid -> msgtag -> int -> int -> bufid = "Pvm_trecv"
  (* [trecv tid tag sec usec] *)
external nrecv : tid -> msgtag -> bufid = "Pvm_nrecv"
external freebuf : bufid -> unit = "Pvm_freebuf"
external exit : unit -> unit = "Pvm_exit"
external catchout : catching -> unit = "Pvm_catchout"
external probe : tid -> msgtag -> bufid = "Pvm_probe"
external bufinfo : bufid -> int * msgtag * tid = "Pvm_bufinfo"
external parent : unit -> tid = "Pvm_parent"
external mstat : string -> unit = "Pvm_mstat"
external notify :  eventkind -> msgtag -> tid array -> unit = "Pvm_notify"

external pkstring : string -> unit = "Pvm_pkstring"
external upkstring : unit -> string = "Pvm_upkstring"

let pkobj x =
  (pkstring (Marshal.to_string  x []));;

let upkobj () =
  Marshal.from_string (upkstring ()) 0;;

external barrier : groupname -> int -> unit = "Pvm_barrier"
external bcast : groupname -> msgtag -> unit = "Pvm_bcast"
external getinst : groupname -> tid -> instnum = "Pvm_getinst"
external gettid : groupname -> instnum -> tid = "Pvm_gettid"
external joingroup : groupname -> instnum = "Pvm_joingroup"
external lvgroup : groupname -> unit = "Pvm_lvgroup"
external pstat : tid -> unit  = "Pvm_pstat"
external gsize : groupname -> int = "Pvm_gsize"
let instnum_of_int x = x
and int_of_instnum x = x

external addhost : string -> unit = "Pvm_addhost"
external delhost : string -> unit = "Pvm_delhost"
external getrbuf : unit -> bufid = "Pvm_getrbuf"
external setrbuf : bufid -> unit = "Pvm_setrbuf"
external getsbuf : unit -> bufid = "Pvm_getsbuf"
external setsbuf : bufid -> unit = "Pvm_setsbuf"

external mcast : tid array -> msgtag -> unit = "Pvm_mcast"
external mkbuf : encoding -> bufid  = "Pvm_mkbuf"

external sendsig : tid -> int -> unit = "Pvm_sendsig"

type where = All | TaskTid of tid | HostTid of tid
external ctasks : int -> taskinfo array = "Pvm_ctasks"

let tasks = function
    All -> ctasks 0
  | TaskTid t -> ctasks t
  | HostTid t -> ctasks t

external tidtohost : tid -> tid = "Pvm_tidtohost"

external pkint : int array -> unit = "Pvm_pkint"
external pkdouble : float array -> unit = "Pvm_pkdouble"
external pkstr : string -> unit = "Pvm_pkstr"
external pkbyte : char array -> unit = "Pvm_pkbyte"
external upkint : int -> int array = "Pvm_upkint"
external upkdouble : int -> float array = "Pvm_upkdouble"
external upkstr : int -> string = "Pvm_upkstr"
external upkbyte : int -> char array = "Pvm_upkbyte"
