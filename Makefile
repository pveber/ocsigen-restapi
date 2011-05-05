test:
	ocamlbuild restapi.cmo
	ocsigen -V -c ocsigen.conf

clean:
	ocamlbuild -clean