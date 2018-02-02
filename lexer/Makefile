all:
	ocamlfind ocamlc -o test1 -package oUnit -package str -linkpkg -g \
		-w -31-8 \
		token.ml language.ml lexer.ml \
		-I test test/lexer_test.ml \

	./test1
	make clean
clean:
	rm -rf *.cm* data/*.cm* test/*.cm* test1 *.cache
