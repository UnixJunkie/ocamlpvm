(* $Id: pvm.mli,v 1.7 2003/09/19 14:04:03 brisset Exp $ *)

type tid
type bufid
type msgtag
type stride
type mboxindex
type instnum
type groupname = string
type encoding = DataDefault | DataRaw | DataInPlace
type eventkind = HostDelete | HostAdd | TaskExit
type processor={
    proc_name:string;
    proc_arch:string;
    proc_speed:int
  }
type catching = 
    No_Catch
  | Stdout_Catch
type mboxinfo = {
    mi_name : string;
    mi_indices : mboxindex array;
    mi_owners : tid array
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
type spawn_flag =
    TaskDefault
  | TaskHost		(* specify host *)
  | TaskArch		(* specify architecture *)
  | TaskDebug	(* start task in debugger *)
  | TaskTrace	(* process generates trace data *)
  | MppFront		(* spawn task on service node *)
  | HostCompl	(* complement host set *)
  | NoSpawnParent

type spawn_result = Tid of tid | Fault of exn

type taskinfo = {
    ti_tid : tid;	(* Task id *)
    ti_ptid : tid;	(* parent tid *)
    ti_host : tid;	(* pvmd tid *)
    ti_flag : int ;	(* status flags *)
    ti_a_out : string;	(* a.out name *)
    ti_pid : int       (* task (O/S dependent) process id *)
}
type where = All | TaskTid of tid | HostTid of tid

val msgtag_of_int : int -> msgtag
val int_of_msgtag :  msgtag -> int
val int_of_tid :  tid -> int
val stride_of_int : int -> stride
val invalidBuf : bufid
val mytid : unit -> tid
val config : unit -> processor array
val getmboxinfo : string -> mboxinfo array
val putinfo : string -> bufid -> mboxindex
val delinfo : string -> mboxindex -> unit
val recvinfo : string -> mboxindex -> mbox_flags list -> bufid
val simple_spawn : string -> string -> tid
val spawn : string -> string array -> spawn_flag list -> string -> int -> spawn_result array
  (* [spawn task argv flag host ntask] *)
val initsend : encoding -> bufid
val anyMsgTag : msgtag
val anyTid : tid
val send : tid -> msgtag -> unit
val mcast :  tid array -> msgtag -> unit
val recv : tid -> msgtag -> bufid
val nrecv : tid -> msgtag -> bufid
val freebuf : bufid -> unit
val exit : unit -> unit
val catchout : catching -> unit
val probe : tid -> msgtag -> bufid
val bufinfo : bufid -> int * msgtag * tid
val parent : unit -> tid
val mstat : string -> unit
val notify :  eventkind -> msgtag -> tid array -> unit
val pkobj : 'a -> unit
val upkobj : unit -> 'a

val barrier : groupname -> int -> unit
val bcast : groupname -> msgtag -> unit
val getinst : groupname -> tid -> instnum
val gettid : groupname -> instnum -> tid
val joingroup : groupname -> instnum
val lvgroup : groupname -> unit
val pstat : tid -> unit (* Failure ... *)
val gsize : groupname -> int

val int_of_instnum : instnum -> int
val instnum_of_int : int -> instnum

type c
val recvf : (bufid -> tid -> msgtag -> int) -> c
val reset_recvf : c -> unit
val addhost : string -> unit
val delhost : string -> unit
val mcast : tid array -> msgtag -> unit
val mkbuf : encoding -> bufid
val sendsig : tid -> int -> unit
val tasks : where -> taskinfo array
val tidtohost : tid -> tid
val trecv : tid -> msgtag -> int -> int -> bufid
  (* [trecv tid tag sec usec] sec < 0 ou usec < 0 pour un recv standard *)
val pkint : int array -> unit
val pkdouble : float array -> unit
val pkstr : string -> unit
val pkbyte : char array -> unit
val upkint : int -> int array
val upkdouble : int -> float array
val upkstr : int -> string
val upkbyte : int -> char array

