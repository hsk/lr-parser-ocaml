all:
	ocamlfind ocamlc -o parser_test -package oUnit -package str -linkpkg -g -w -31-8 \
		-I ../lexer ../lexer/token.ml ../lexer/lexer.ml \
		language.ml parser.ml -I test test/calc_test.ml

	cd ../ ; ./parser/parser_test
	make clean
clean:
	rm -rf ../lexer/*.cm* ../lexer/test/*.cm* *.cm* data/*.cm* test/*.cm* parser_test *.cache
