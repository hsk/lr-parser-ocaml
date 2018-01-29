package pg
import org.scalatest.FunSpec

object precompiler_test extends FunSpec {
  import pg.precompiler.precompiler.{PreCompiler}
  import pg.data.sample_language.{test_calc_language_raw_string}
  import pg.parser.callback.{AbstractCallbackController}
  import pg.lexer.{ILexer}

  class CustomCallbackController extends AbstractCallbackController {
    def callLex(id: Int, value: Any, lexer: ILexer): Any = {
      val rule = this.language.lex(id)
      if (rule.token == "DIGITS") value.toString.toInt
      else null
    }
    def callGrammar(id: Int, children: Array[Any], lexer: ILexer) : Any = {
      val rule = this.language.grammar(id)
      if (rule.ltoken == "ATOM") {
        if (children.length == 1) {
          return children(0)
        } else {
          return children(1)
        }
      } else if (rule.ltoken == "TERM") {
        if (children.length == 1) {
          return children(0)
        } else {
          return children(0).toInt * children(2).toInt
        }
      } else if (rule.ltoken == "EXP") {
        if (children.length == 1) {
          return children(0)
        } else {
          return children(0).toInt + children(2).toInt
        }
      }
    }
  }

  describe("precompiler test") {
    val precompiler = new PreCompiler("../../../dist");
    val source = precompiler.exec(test_calc_language_raw_string);
    fs.writeFileSync("./__tests__/data/tmp/precompiler_result.ts", source);
    val p = require("../data/tmp/precompiler_result.ts");
    it("parse \"1+1\" by using compiled parser") {
      expect(() => p.parser.parse("1+1")).not.toThrow();
    }
    it("parse \"1+1\" equals to 2 by using compiled parser and custom callback controller") {
      p.parser.setCallbackController(new CustomCallbackController(p.language));
      expect(p.parser.parse("1+1")).toBe(2);
    }
    fs.unlinkSync("./__tests__/data/tmp/precompiler_result.ts")
  }
}
