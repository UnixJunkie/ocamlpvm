/*
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
*/

/*
  $Id: pvmc.c 2825 2006-07-12 13:22:22Z olive $
  $Log$
  Revision 1.8  2000/02/09 08:48:22  brisset
  Histoires de PushRoot

  Revision 1.7  2000/02/08 16:21:54  brisset
  Histoires de PushRoot

  Revision 1.6  1999/05/19 15:04:15  barnier
  free

  Revision 1.5  1999/05/11 15:33:23  brisset
  Beaucoup de nouvelles fonctions

  Revision 1.4  1999/05/10 15:06:23  brisset
  Petit menage (utilisation String_val, ...)

 */
#include <stdio.h>
#include <string.h>
#include <pvm3.h>
#include <mlvalues.h>
#include <alloc.h>
#include <memory.h>


void TreatError( int err )
{
  switch (err)
    {
    case PvmBadParam : failwith("PvmBadParam");break;
    case PvmMismatch : failwith("PvmMismatch");break;
    case PvmOverflow : failwith("PvmOverflow");break;
    case PvmNoData : failwith("PvmNoData");break;
    case PvmNoHost : failwith("PvmNoHost");break;
    case PvmNoFile : failwith("PvmNoFile");break;
    case PvmDenied : failwith("PvmDenied");break;
    case PvmNoMem : failwith("PvmNoMem");break;
    case PvmBadMsg : failwith("PvmBadMsg");break;
    case PvmSysErr : failwith("PvmSysErr");break;
    case PvmNoBuf : failwith("PvmNoBuf");break;
    case PvmNoSuchBuf : failwith("PvmNoSuchBuf");break;
    case PvmNullGroup : failwith("PvmNullGroup");break;
    case PvmDupGroup : failwith("PvmDupGroup");break;
    case PvmNoGroup : failwith("PvmNoGroup");break;
    case PvmNotInGroup : failwith("PvmNotInGroup");break;
    case PvmNoInst : failwith("PvmNoInst");break;
    case PvmHostFail : failwith("PvmHostFail");break;
    case PvmNoParent : failwith("PvmNoParent");break;
    case PvmNotImpl : failwith("PvmNotImpl");break;
    case PvmDSysErr : failwith("PvmDSysErr");break;
    case PvmBadVersion : failwith("PvmBadVersion");break;
    case PvmOutOfRes : failwith("PvmOutOfRes");break;
    case PvmDupHost : failwith("PvmDupHost");break;
    case PvmCantStart : failwith("PvmCantStart");break;
    case PvmAlready : failwith("PvmAlready");break;
    case PvmNoTask : failwith("PvmNoTask");break;
    case PvmNotFound : failwith("PvmNotFound");break;
    case PvmExists : failwith("PvmExists");break;
    case PvmHostrNMstr : failwith("PvmHostrNMstr");break;
    case PvmParentNotSet : failwith("PvmParentNotSet");break;
    default : if (err<0) failwith("PvmUnknownError"); break; 
  }
}

value
Pvm_config (void)
{
  CAMLparam0();
  int res,bytes;
  int nhost,narch;
  int i,j;
  struct pvmhostinfo *p;
  value v;
  CAMLlocal1(r);
  
  r = alloc(3, 0);

  res=pvm_config(&nhost,&narch,&p);
  if (res<0) 
    TreatError(res);

  Store_field (r, 2, alloc_shr(nhost,0));
  for (i=0;i<nhost;i++)
    initialize(&Field(Field(r, 2),i),Val_int(0));

  for (i=0;i<nhost;i++)
    {
      bytes=strlen(p[i].hi_name);
      Store_field (r, 0, alloc_string(bytes));
      for (j=0;j<bytes;j++) 
	Byte(Field(r, 0),j)=p[i].hi_name[j];
      bytes=strlen(p[i].hi_arch);
      Store_field (r, 1, alloc_string(bytes));
      for (j=0;j<bytes;j++) 
	Byte(Field(r, 1),j)=p[i].hi_arch[j];
      v=alloc_tuple(3);
      Store_field(v, 0, Field(r, 0));
      Store_field(v, 1, Field(r, 1));
      Store_field(v, 2, Val_int(p[i].hi_speed));
      modify(&Field(Field(r, 2),i),v);
    }
  CAMLreturn(Field(r, 2));
}

value
Pvm_getmboxinfo (value s1)
{
  CAMLparam1(s1);
  int res,bytes,nb,n;
  int nclasses;
  int i,j,k;
  struct pvmmboxinfo *p;
  value v;
  CAMLlocal1(r);

  r = alloc(4, 0);

  res=pvm_getmboxinfo(String_val(s1),&nclasses,&p);

  if (res<0) 
    TreatError(res);

  Store_field (r, 0, alloc_shr(nclasses,0));
  for (i=0;i<nclasses;i++)
    initialize(&Field(Field(r, 0),i),Val_int(0));

  for (i=0;i<nclasses;i++)
    {
      bytes=strlen(p[i].mi_name);
      Store_field (r, 1, alloc_string(bytes));
      for (j=0;j<bytes;j++) 
	Byte(Field(r, 1),j)=p[i].mi_name[j];

      nb=p[i].mi_nentries;
      /*      printf("nb=%d\n",nb);*/
      Store_field (r, 2, alloc_shr(nb,0));
      for (j=0;j<nb;j++) 
	initialize(&Field(Field(r, 2),j),Val_int(p[i].mi_indices[j]));

      Store_field (r, 3, alloc_shr(nb,0));
      for (j=0;j<nb;j++) 
	initialize(&Field(Field(r, 3),j),Val_int(p[i].mi_owners[j]));

      v=alloc_tuple(3);
      Store_field(v,0, Field(r, 1));
      /*      Field(v,1)=Val_int(nb);*/
      Store_field(v,1, Field(r, 2));
      Store_field(v,2, Field(r, 3));
      modify(&Field(Field(r, 0),i),v);
    }
  CAMLreturn(Field(r, 0));
}

value
Pvm_mytid(void)
{
  int mytid;
  mytid=pvm_mytid();
  if (mytid<0) 
    TreatError(mytid);
  return Val_int(mytid);
}

value
Pvm_spawn_native(value task, value argv, value flag, value host,
		  value ntasks, value tids)
{
  char **cargv;
  unsigned i;
  int numt;
  unsigned cntasks = Int_val(ntasks);
  int *ctids;
  char *chost;

  cargv = malloc((Wosize_val(argv)+1)*sizeof(char*));
  ctids = malloc(cntasks*sizeof(int));
  for(i = 0; i < Wosize_val(argv); i++) cargv[i] = String_val(Field(argv, i));
  cargv[Wosize_val(argv)] = NULL;

  chost = (string_length(host) == 0 ? NULL : String_val(host));
  numt = pvm_spawn(String_val(task), cargv, Int_val(flag),chost,cntasks,ctids);
  if (numt<0) {free(cargv); free(ctids);TreatError(numt);}

  for(i = 0; i < cntasks; i++) modify(&Field(tids, i), Val_int(ctids[i]));
  free(cargv); free(ctids);
  return Val_int(numt);
}

value
Pvm_cspawn(value * argv, int argn)
{
  return Pvm_spawn_native(argv[0],argv[1], argv[2], argv[3], argv[4],argv[5]);
}

value
Pvm_mstat(value s1)
{
  int res = pvm_mstat(String_val(s1));
  if (res<0) TreatError(res);
  return;
}

static int encodings[] = {PvmDataDefault, PvmDataRaw, PvmDataInPlace};
value
Pvm_initsend(value encoding)
{
  CAMLparam0();
  CAMLlocal1(res);
  int enc;
  enc = encodings[Int_val(encoding)];
  res=pvm_initsend(enc);
  if (res<0) TreatError(res);
  CAMLreturn (res);
}

value
Pvm_send(value tid,value msgtag)
{
  int res = pvm_send(Int_val(tid), Int_val(msgtag));
  if (res<0) TreatError(res);
  return;
}

value
Pvm_putinfo(value name, value bufid)
{
  int res = pvm_putinfo(String_val(name),Int_val(bufid),
			PvmMboxDefault|PvmMboxMultiInstance);
  if (res<0) TreatError(res);
  return(Val_int(res));
}

value
Pvm_delinfo(value name,value index)
{
  int res = pvm_delinfo(String_val(name),Int_val(index),0);
  if (res<0) TreatError(res);
  return;
}

static int mbox_flags[6] = {PvmMboxDefault, PvmMboxPersistent, PvmMboxMultiInstance, PvmMboxOverWritable, PvmMboxFirstAvail, PvmMboxReadAndDelete};

value
Pvm_recvinfo(value name,value index, value flags)
{
  int res;
  int sum_flags = 0;
  
  while (Is_block(flags)) { /* CONS */
    sum_flags += mbox_flags[Int_val(Field(flags, 0))];
    flags = Field(flags, 1);
  }

  res = pvm_recvinfo(String_val(name), Int_val(index), sum_flags);
  if (res<0) TreatError(res);
  return(Val_int(res));
}

value
Pvm_freebuf(value bufid)
{
  int res = pvm_freebuf(Int_val(bufid));
  if (res<0) TreatError(res);
  return;
}

value
Pvm_recv(value tid,value msgtag)
{
  enter_blocking_section();
  int res = pvm_recv(Int_val(tid), Int_val(msgtag));
  leave_blocking_section();
  if (res<0) TreatError(res);
  return(Val_int(res));
}

value
Pvm_trecv(value tid, value msgtag, value sec, value usec)
{
  int res;
  struct timeval t;

  if (sec < 0 || usec < 0) {
    t.tv_sec = Int_val(sec); t.tv_usec = Int_val(usec);
    res = pvm_trecv(Int_val(tid), Int_val(msgtag), &t);
  } else
    res = pvm_trecv(Int_val(tid), Int_val(msgtag), NULL);
  if (res<0) TreatError(res);
  return(Val_int(res));
}

value
Pvm_nrecv(value tid,value msgtag)
{
  int res = pvm_nrecv(Int_val(tid),Int_val(msgtag));
  if (res<0) TreatError(res);
  return(Val_int(res));
}

value
Pvm_probe(value tid,value msgtag)
{
  int res=pvm_probe(Int_val(tid),Int_val(msgtag));
  if (res<0) TreatError(res);
  return(Val_int(res));
}

value
Pvm_bufinfo(value bufid)
{
  CAMLparam1(bufid);
  int cbufid,res,bytes,msgtag,tid;
  CAMLlocal1(v);

  res = pvm_bufinfo(Int_val(bufid), &bytes, &msgtag, &tid);
  if (res<0) TreatError(res);
  v = alloc_tuple(3);
  Field(v,0)=Val_int(bytes);
  Field(v,1)=Val_int(msgtag);
  Field(v,2)=Val_int(tid);
  CAMLreturn(v);
}

value
Pvm_exit(void)
{
  int res = pvm_exit();
  if (res<0) TreatError(res);
  return;
}

value
Pvm_catchout(value catching)
{
  int res,val;
  switch (Int_val(catching)) {
  case 0 :
    res = pvm_catchout(NULL);
    break;
  case 1 :
    res = pvm_catchout(stdout);
    break;
  default:
    fprintf(stderr,"Erreur dans Pvm_catchout en C\n");
    exit(-1);
  }
  if (res<0) TreatError(res);
  return;
}

value Pvm_parent(void)
{
  int parent;
  parent=pvm_parent();
  if (parent<0) 
    TreatError(parent);
  return Val_int(parent);
}



value
Pvm_notify(value kind,value msgtag,value tids)
{
  int msgtagc,kindc,tabsize,res,i;
  int *tabc;
  static int kinds[] = {PvmHostDelete, PvmHostAdd, PvmTaskExit};

  kindc = kinds[Int_val(kind)];
  tabsize = Wosize_val(tids);
  tabc = (int *)malloc(tabsize*sizeof(int));
  for (i=0;i<tabsize;i++)
    tabc[i] = Int_val(Field(tids,i));
  res = pvm_notify(kindc,Int_val(msgtag),tabsize,tabc);
  free(tabc);
  if (res<0)
    TreatError(res);
  return;
}


value
Pvm_pkstring(value s)
{
  int i,n,res;

  n=string_length(s);
  res=pvm_pkint(&n,1,1);
  if (res<0)
    TreatError(res);
  res=pvm_pkbyte(String_val(s),n,1);  
  if (res<0)
    TreatError(res);
  return;
}

value
Pvm_upkstring(void)
{
  CAMLparam0();
  int bufid,bytes,msgtag,tid;
  char *tab;
  CAMLlocal1(s);
  int res,i;

  res=pvm_upkint(&bytes,1,1);
  if (res<0)
    TreatError(res);
  tab=(char *)malloc(sizeof(char)*bytes);
  res = pvm_upkbyte(tab,bytes,1);  
  if (res<0)
    {
      free(tab);
      TreatError(res);
    }

  s = alloc_string(bytes);
  for (i=0;i<bytes;i++) Byte(s,i)=tab[i];
  free(tab);
  CAMLreturn(s);
}

value
Pvm_barrier(value groupname, value count)
{
  int err = pvm_barrier(String_val(groupname), Int_val(count));
  if (err < 0) TreatError(err);
  return;
}

value
Pvm_bcast(value groupname, value msgtag)
{
  int err = pvm_bcast(String_val(groupname), Int_val(msgtag));
  if (err < 0) TreatError(err);
  return;
}

value
Pvm_mcast(value tids, value msgtag)
{
  int *ctids, i, err;
  int n = Wosize_val(tids);

  ctids = (int*)malloc(sizeof(int)*(n+1));
  for(i = 0; i < n; i++) ctids[i] = Int_val(Field(tids, i));

  err = pvm_mcast(ctids, n, Int_val(msgtag));
  free(ctids);
  if (err < 0) TreatError(err);
  return;
}

value
Pvm_getinst(value groupname, value tid)
{
  int err = pvm_getinst(String_val(groupname), Int_val(tid));
  if (err < 0) TreatError(err);
  return Val_int(err);
}
value
Pvm_gettid(value groupname, value instnum)
{
  int err = pvm_gettid(String_val(groupname), Int_val(instnum));
  if (err < 0) TreatError(err);
  return Val_int(err);
}

value
Pvm_joingroup(value groupname)
{
  int err = pvm_joingroup(String_val(groupname));
  if (err < 0) TreatError(err);
  return Val_int(err);
}

value
Pvm_lvgroup(value groupname)
{
  int err = pvm_lvgroup(String_val(groupname));
  if (err < 0) TreatError(err);
  return;
}

value
Pvm_pstat(value tid)
{
  int err = pvm_pstat(Int_val(tid));
  if (err < 0) TreatError(err);
  return;
}

value
Pvm_gsize(value groupname)
{
  int err = pvm_gsize(String_val(groupname));
  if (err < 0) TreatError(err);
  return Val_int(err);
}

static int (*default_recvf)() = NULL;

static value mlf;

int
ml_recvf(int bufid, int tid, int tag)
{
  return Int_val(callback3(mlf, Val_int(bufid), Val_int(tid), Val_int(tag)));
}

value
Pvm_recvf(value new)
{
  int (*old)();
  mlf = new;
  old = pvm_recvf(ml_recvf);
  if (default_recvf == NULL) default_recvf = old;
  return;
}

value
Pvm_reset_recvf()
{
  if (default_recvf != NULL) pvm_recvf(default_recvf);
  return;
}

value
Pvm_addhost(value hostname)
{
  char* hosts[1] = {String_val(hostname)};
  int infos[1];
  int err = pvm_addhosts(hosts, 1, infos);
  if (err == 0) TreatError(infos[0]);
  else if (err < 0) TreatError(err);
  return;
}

value
Pvm_delhost(value hostname)
{
  char* hosts[1] = {String_val(hostname)};
  int infos[1];
  int err = pvm_delhosts(hosts, 1, infos);
  if (err == 0) TreatError(infos[0]);
  else if (err < 0) TreatError(err);
  return;
}

value
Pvm_getrbuf()
{
  int res = pvm_getrbuf();
  if (res < 0) TreatError(res);
  return Val_int(res);
}
value
Pvm_setrbuf(value bufid)
{
  int res = pvm_setrbuf(Int_val(bufid));
  if (res < 0) TreatError(res); 
  return;
}

value
Pvm_getsbuf()
{
  int res = pvm_getsbuf();
  if (res < 0) TreatError(res);
  return Val_int(res);
}
value
Pvm_setsbuf(value bufid)
{
  int res = pvm_setsbuf(Int_val(bufid));
  if (res < 0) TreatError(res);
  return;
}

value
Pvm_mkbuf(value encoding)
{
  int enc = encodings[Int_val(encoding)];

  int res = pvm_mkbuf(enc);
  if (res < 0) TreatError(res);
  return Val_int(res);
}

value
Pvm_sendsig(value tid, value signum)
{
  int err = pvm_sendsig(Int_val(tid), Int_val(signum));
  if (err < 0) TreatError(err);
  return;
}

#define SIZE_TASKINFO 6
#define TI_TID   0
#define TI_PTID  1
#define TI_HOST  2
#define TI_FLAG  3
#define TI_A_OUT 4
#define TI_PID   5
value
Pvm_ctasks(value where)
{
  CAMLparam1 (where);
  CAMLlocal1 (array);
  int ntask, i;
  struct pvmtaskinfo *taskp;

  int err = pvm_tasks(Int_val(where), &ntask, &taskp);
  if (err < 0) TreatError(err);

  array = alloc(ntask, 0);
  for(i = 0; i < ntask; i++) {
    CAMLlocal1 (taskinfo);
    taskinfo = alloc(SIZE_TASKINFO, 0);
      
    Store_field(taskinfo, TI_TID, Val_int(taskp[i].ti_tid));
    Store_field(taskinfo, TI_PTID, Val_int(taskp[i].ti_ptid));
    Store_field(taskinfo, TI_HOST, Val_int(taskp[i].ti_host));
    Store_field(taskinfo, TI_FLAG, Val_int(taskp[i].ti_flag));
    Store_field(taskinfo, TI_A_OUT, copy_string(taskp[i].ti_a_out));
    Store_field(taskinfo, TI_PID, Val_int(taskp[i].ti_pid));
    
    Store_field(array, i, taskinfo);
  }
  CAMLreturn(array);
}

value
Pvm_tidtohost(value tid)
{
  int err = pvm_tidtohost(Int_val(tid));
  if (err < 0) TreatError(err);
  return (Val_int(err));
}

value
Pvm_pkint(value array)
{
  int size, i, res;
  int *carray;

  size = Wosize_val(array);
  carray = (int*)malloc(sizeof(int)*size);
  for(i = 0; i < size; i++) carray[i] = Int_val(Field(array, i));
  res = pvm_pkint(carray, size, 1);
  free(carray);
  if (res < 0) TreatError(res);
  return;
}

value
Pvm_pkdouble(value array)
{
  int size, i, res;
  double *carray;

  size = Wosize_val(array);
  carray = (double*)malloc(sizeof(double)*size);
  for(i = 0; i < size; i++) carray[i] = Double_field(array, i);
  res = pvm_pkdouble(carray, size, 1);
  free(carray);
  if (res < 0) TreatError(res);
  return;
}

value
Pvm_pkbyte(value array)
{
  int size, i, res;
  unsigned char *carray;

  size = Wosize_val(array);
  carray = (unsigned char*)malloc(sizeof(unsigned char)*size);
  for(i = 0; i < size; i++) carray[i] = Int_val(Field(array, i));
  res = pvm_pkbyte(carray, size, 1);
  free(carray);
  if (res < 0) TreatError(res);
  return;
}

value
Pvm_pkstr(value s)
{
  int size, i, res;
  res = pvm_pkstr(String_val(s));
  if (res < 0) TreatError(res);
  return;
}

value
Pvm_upkstr(value n)
{
  int res;
  value v;
  char *s = malloc((Int_val(n)+1)*sizeof(char));

  res = pvm_upkstr(s);
  if (res < 0) TreatError(res);
  v = copy_string(s);
  free(s);
  return v;
}

value
val_int(int x)
{
  return Val_int(x);
}

value
Pvm_upkint(value n)
{
  CAMLparam1(n);
  CAMLlocal1(v);
  int res, i, cn = Int_val(n);
  int *t = (int*)malloc(cn*sizeof(int));

  res = pvm_upkint(t, cn, 1);
  if (res < 0) {free(t); TreatError(res);}

  v = alloc(cn, 0);
  for (i = 0; i < cn; i++) Store_field(v, i, Val_int(t[i]));
  free(t);
  CAMLreturn(v);
}

value
Pvm_upkdouble(value n)
{
  CAMLparam1 (n);
  CAMLlocal1 (v);
  int res, i, cn = Int_val(n);
  double *t = (double*)malloc(cn*sizeof(double));

  res = pvm_upkdouble(t, cn, 1);
  if (res < 0) {free(t); TreatError(res);}

  v = alloc(cn*(sizeof(double)/sizeof(int*)), Double_array_tag);
  for (i = 0; i < cn; i++) Store_double_field(v, i, t[i]);
  free(t);
  CAMLreturn(v);
}

value
Pvm_upkbyte(value n)
{
  CAMLparam1 (n);
  CAMLlocal1 (v);
  int res, i, cn = Int_val(n);
  unsigned char *t = (unsigned char*)malloc(cn*sizeof(unsigned char));

  res = pvm_upkbyte(t, cn, 1);
  if (res < 0) {free(t);TreatError(res);}

  v = alloc(cn, 0);
  for (i = 0; i < cn; i++) Store_field(v, i, t[i]);
  free(t);
  CAMLreturn(v);
}


value 
Pvm_kill (value tid)
{
  CAMLparam1(tid);
  int res = 0;
  res = pvm_kill (tid);
  CAMLreturn(res);
}
