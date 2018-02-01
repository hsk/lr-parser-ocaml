all:
	ocamlfind ocamlc -o test1 -package oUnit -package str -linkpkg -g \
		 -w -31-8 \
		-I src -I src/parser -I src/precompiler -I src/parsergenerator \
		-I test -I test/data  -I test/parser -I test/precompiler -I test/parsergenerator \
	  src/token.ml \
	  src/language.ml \
	  src/parser/callback.ml \
		src/lexer.ml \
	  src/parser/parser.ml \
	  src/parsergenerator/nullableset.ml \
	  src/parsergenerator/symboldiscriminator.ml \
	  src/parsergenerator/firstset.ml \
	  src/parsergenerator/grammardb.ml \
	  src/parsergenerator/closureitem.ml \
	  src/parsergenerator/closureset.ml \
	  src/parsergenerator/dfagenerator.ml \
	  src/parsergenerator/parsergenerator.ml \
	  src/precompiler/ruleparser.ml \
		test/data/sample_language.ml \
		test/data/broken_language.ml \
		test/data/language_language.ml \
		test/lexer_test.ml \
		test/parsergenerator/nullableset_test.ml \
	  test/parsergenerator/symboldiscriminator_test.ml \
		test/parsergenerator/firstset_test.ml \
	  test/parsergenerator/syntaxdb_test.ml \
	  test/parsergenerator/closureitem_test.ml \
	  test/parsergenerator/closureset_test.ml \
		test/parser/parser_test.ml \
		test/language_parsing_test.ml \
		test/broken_language_test.ml \
		test/all_test.ml \

#	  src/precompiler/ruleparser.ml \
#		test/language_parsing_test.ml \

	make clean
	./test1

clean:
	rm -rf *.cm* src/*.cm* src/parser/*.cm* src/precompiler/*.cm* src/parsergenerator/*.cm* test/*.cm* test/data/*.cm* test/parser/*.cm* test/precompiler/*.cm* test/parsergenerator/*.cm*
cleanall:
	make clean
	rm -rf test1 a.out *.cache