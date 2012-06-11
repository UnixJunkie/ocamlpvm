type groupname = string
type 'a group = string * 'a

let tag_slave_to_master = Pvm.msgtag_of_int 1
and tag_master_to_slave = Pvm.msgtag_of_int 2
and tag_stop = Pvm.msgtag_of_int 3
and tag_ready = Pvm.msgtag_of_int 4
and tag_init = Pvm.msgtag_of_int 5


let init_master group slave args init =
  let mytid = Pvm.mytid () in
  let instnum = Pvm.joingroup group in
  assert(instnum = (Pvm.instnum_of_int 0));
  let machines = Array.map (fun x -> x.Pvm.proc_name) (Pvm.config ()) in
  let tids = Array.map (fun m -> match (Pvm.spawn slave args [Pvm.TaskHost] m 1).(0) with Pvm.Tid t -> t | Pvm.Fault x -> raise x) machines in
  Array.iter
    (fun tid ->
      let _ = Pvm.initsend Pvm.DataRaw in
      Pvm.pkobj init;
      Pvm.send tid tag_master_to_slave)
    tids;
  (group, init)


let recv_or_notified tid_ready tag_slave_to_master tag_exit =
  let task_is_stopped = ref false in
  let c =
    Pvm.recvf
      (fun bufid tid tag ->
	let (_,tag2, tid2) = Pvm.bufinfo bufid in
	if tag2 = tag_exit
	then (task_is_stopped := true; 1)
	else
	  if (tid = Pvm.anyTid || tid == tid2) &&
	    (tag = Pvm.anyMsgTag || tag = tag2)
	  then 1
	  else 0) in
  let b = Pvm.recv tid_ready tag_slave_to_master in
  Pvm.reset_recvf c;
  if !task_is_stopped then failwith "TaskIsStopped" else b

(* Attente sur anyTid et (tag1 || tag2) *)
let recv2tags tag1 tag2 =
  let c =
    Pvm.recvf
      (fun bufid _ _ ->
	let (_,tag, _) = Pvm.bufinfo bufid in
	if tag = tag1 || tag2 = tag
	then 1
	else 0) in
  let b = Pvm.recv Pvm.anyTid tag1 in
  Pvm.reset_recvf c;
  b;;


let rec eval (group, init) x =
  let b = recv2tags tag_ready tag_init in
  let (_, tag, tid_ready) = Pvm.bufinfo b in
  if tag = tag_ready
  then (* Celui ci est pret a calculer *)
    let _ = Pvm.initsend Pvm.DataRaw in
    Pvm.pkobj x;
    Pvm.send tid_ready tag_master_to_slave;
    let tag_exit = Pvm.msgtag_of_int (Pvm.int_of_tid tid_ready) in
    Pvm.notify Pvm.TaskExit tag_exit [|tid_ready|];
    let receive () = 
      try
      	let b = recv_or_notified tid_ready tag_slave_to_master tag_exit in
      	Pvm.upkobj ()
      with
      	(Failure "TaskIsStopped" | Failure "PvmNoData") -> eval (group,init) x () in
    receive
  else begin (* Oh, un nouveau volontaire pour bosser *)
    assert (tag = tag_init);
    let _ = Pvm.initsend Pvm.DataRaw in
    Pvm.pkobj init; (* On lui envoie son initialisation *)
    Pvm.send tid_ready tag_master_to_slave;
    eval (group, init) x
  end

let end_master (group,_) =
  try
    while true do
      let b = Pvm.nrecv Pvm.anyTid tag_ready in
      if b = Pvm.invalidBuf
      then raise Exit
      else
	let (_, _, tid) = Pvm.bufinfo b in
  	let _ = Pvm.initsend Pvm.DataRaw in
  	Pvm.pkobj ();
  	Pvm.send tid tag_stop
    done
  with
    Exit -> Pvm.exit ()

let master_instnum = (Pvm.instnum_of_int 0)

type spartacus = Pvm.tid

let init_slave group = 
  let _ = Pvm.mytid () in
  let parent =
    try Pvm.parent () with
      Failure _ -> (* J'ai été lancé à la main, je m'annonce *)
	let parent = Pvm.gettid group master_instnum in
	let _ = Pvm.initsend Pvm.DataRaw in
      	Pvm.pkobj ();
      	Pvm.send parent tag_init;
	parent in
  Pvm.notify Pvm.TaskExit tag_stop [|parent|];
  let buffer = Pvm.recv parent tag_master_to_slave in
  Pvm.upkobj (), parent;;

let slave parent f =
  try
    while true do
      let _ = Pvm.initsend Pvm.DataRaw in
      Pvm.pkobj ();
      Pvm.send parent tag_ready; (* je suis pret a calculer *)
      
      let buffer = Pvm.recv Pvm.anyTid Pvm.anyMsgTag in
      let (_,tag,_) = Pvm.bufinfo buffer in
      if tag <> tag_stop
      then begin
      	assert (tag = tag_master_to_slave);
      	let v = Pvm.upkobj () in
      	let res = f v in
      	let _ = Pvm.initsend Pvm.DataRaw in
      	Pvm.pkobj res;
      	Pvm.send parent tag_slave_to_master
      end
      else raise Exit
    done
  with Exit -> Pvm.exit ();;

