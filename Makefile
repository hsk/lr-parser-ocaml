all:
	ocamlfind ocamlc -o test1 -package oUnit -package str -linkpkg -g \
		-w -31-8 \
		-I lexer lexer/token.ml lexer/lexer.ml \
		-I lexer/test lexer/test/lexer_test.ml \
		-I parser parser/language.ml parser/parser.ml \
		-I yacc yacc/utils.ml yacc/symboldiscriminator.ml yacc/nullableset.ml yacc/firstset.ml \
		   yacc/grammardb.ml yacc/closureitem.ml yacc/closureset.ml \
		   yacc/dfagenerator.ml yacc/lalr1dfa.ml yacc/parsergenerator.ml \
		-I precompiler precompiler/rule_parser.ml  precompiler/precompiler.ml \
		-I test -I test/data  -I test/parser -I test/precompiler -I test/yacc \
		test/data/calc_language.ml \
		test/data/empty_language.ml \
		test/data/language_language.ml \
		test/data/sample_language.ml \
		test/yacc/symboldiscriminator_test.ml \
 		test/yacc/nullableset_test.ml \
		test/yacc/firstset_test.ml \
		test/yacc/grammardb_test.ml \
		test/yacc/closureitem_test.ml \
		test/yacc/closureset_test.ml \
		test/parser/parser_test.ml \
		test/language_parsing_test.ml \
		test/rule_parsing_test.ml \
		test/broken_language_test.ml \
		test/all_test.ml \

	make clean
	./test1
	make clean2

clean:
	rm -rf *.cm* lexer/*.cm* lexer/data/*.cm* lexer/test/*.cm* \
	parser/*.cm* parser/data/*.cm* parser/test/*.cm* \
	precompiler/*.cm* yacc/*.cm* \
	test/*.cm* test/data/*.cm* test/parser/*.cm* test/precompiler/*.cm* test/yacc/*.cm*
clean2:
	rm -rf test1 a.out *.cache
cleanall:
	make clean
	make clean2
