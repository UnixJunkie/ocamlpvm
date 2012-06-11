type groupname = string
type 'a group
val init_master : groupname -> string -> string array -> 'init -> 'init group
  (* [init_master group_name slave_command argv init] creates a group of name
     [group_name], spawns [slave_command argv] on available hosts, sends
     [init] to every run slave and returns a group id *)
val eval : 'init group -> 'a -> (unit -> 'b)
  (* [eval group data] sends [data] to one ready host (a "slave") and returns
     a function which waits for the value sent back by this slave (intended
     to be used with Lazy.Delayed constructor).
     This function is also able to connect with to slaves run by hand (the
     [init] argument of [init_master] is sent first to a new slave) *)
val end_master : 'init group -> unit
  (* [end_master group] Sends byebye to all members of the group *)

type spartacus
val init_slave : groupname -> 'init * spartacus
  (* [init_slave groupname] joins the group created by the master. Returns
     the init value and a slave id to be used by function [slave] *)
val slave : spartacus -> ('a -> 'b) -> unit
  (* [slave slave_id f] starts a loop which sends a ready tag to the master,
     waits for a request from the master, applies [f] on it and sends back
     the result to the master. *)
