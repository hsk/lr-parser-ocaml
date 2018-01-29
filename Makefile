all:
	ocamlc -I src -I src/parser src/token.ml src/language.ml src/parser/ast.ml  src/parser/callback.ml src/lexer.ml \
	src/parsingtable.ml
clean:
	rm -rf src/*.cm* src/parser/*.cm* a.out 
