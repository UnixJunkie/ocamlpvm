# $Id: Makefile 2823 2003-04-16 07:07:55Z brisset $

OCAMLC = ocamlc
OCAMLOPT = ocamlopt
OCAMLDEP=ocamldep
OCAMLFLAGS= -g
OCAMLOPTFLAGS=
OCAMLDIR:=$(shell ocamlc -where)
CFLAGS = -I $(OCAMLDIR)/caml -I $(PVM_ROOT)/include -W
BDTNORM_OBJS= pvm.cmo mailbox.cmo daemons.cmo 
BDTOPT_OBJS=  $(BDTNORM_OBJS:.cmo=.cmx)

all : pvm.cma pvm.cmxa pvmc.o libpvm.a

pvm.cma : $(BDTNORM_OBJS) pvmc.o
	$(OCAMLC) $(OCAMLFLAGS) -a -custom -o pvm.cma $(BDTNORM_OBJS)


pvm.cmxa : $(BDTOPT_OBJS) pvmc.o
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -a -o pvm.cmxa  $(BDTOPT_OBJS)

libpvm.a : pvmc.o
	rm -f $@
	ar rc $@  pvmc.o
	ranlib $@

.SUFFIXES: .ml .mli .cmo .cmi .cmx

.ml.cmo :
	$(OCAMLC) $(OCAMLFLAGS) -c $<
.mli.cmi :
	$(OCAMLC) $(OCAMLFLAGS) -c $<
.ml.cmx :
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -c $<
.c.o :
	$(CC) -c $(CFLAGS) $<

clean:
	\rm -f *.cmo *.cmi *.cmx *.o pvm.cma pvm.cmxa pvm.a libpvm.a *~ .depend

.depend:
	$(OCAMLDEP) $(INCLUDES) *.mli *.ml > .depend

include .depend
