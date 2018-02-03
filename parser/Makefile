all:
	ocamlfind ocamlc -o ./test1 -package oUnit -package str -linkpkg -g \
		-w -31-8 \
		-I ../lexer ../lexer/token.ml ../lexer/lexer.ml \
		-I ../lexer/test ../lexer/test/lexer_test.ml \
		language.ml parser.ml \
		-I data data/language_language.ml data/ruleparser.ml \
		-I test test/rule_parsing_test.ml \

	cd ../ ; ./parser/test1
	make clean
clean:
	rm -rf ../lexer/*.cm* ../lexer/test/*.cm* *.cm* data/*.cm* test/*.cm* test1 *.cache
