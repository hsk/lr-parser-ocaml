package pg

import org.scalatest.FunSpec
import lexer.{Lexer,exec}
import data.sample_language.{test_sample_lex, test_empty_language}
import token.{SYMBOL_EOF,TokenizedInput}
import pg.language.{Language, LexDefinition, GrammarDefinition,GrammarRule,LexRule,Ptn,Reg,Str,reg}
import pg.parser.callback.DefaultCallbackController
import scala.util.matching.Regex

class lexer_test extends FunSpec{
  describe("Lexer test") {
    it("exec valid input") {
      val lexer = new Lexer(test_sample_lex,null)

      assertResult(exec(lexer, "xabc;x|&0ax x z;") )( Array(
        ("ID", "xabc"),
        ("SEMICOLON", ";"),
        ("ATOM", "x"),
        ("SEPARATE", "|"),
        ("INVALID", "&"),
        ("INVALID", "0"),
        ("ID", "ax"),
        ("ATOM", "x"),
        ("ID", "z"),
        ("SEMICOLON", ";"),
        (SYMBOL_EOF, "")
      ))
    }
    it("exec invalid input") {
      val lexer = new Lexer(test_empty_language.lex,null)
      assertThrows[Error]{
        exec(lexer,"xabc;x|&0ax x z;")
      }//no pattern matched
    }
    it("exec no length input") {
      val lexer = new Lexer(test_sample_lex,null)
      assertResult(exec(lexer,"") )( Array(
        (SYMBOL_EOF, "")
      ))
      val lexer2 = new Lexer(test_empty_language.lex,null)
      assertResult(exec(lexer2, "") )( Array(
        (SYMBOL_EOF, "")
      ))
    }

    it("regexp flags") {
      val lexer = new Lexer(List(
        LexRule("I", Reg("""(?i)AbC"""),0,None),
        LexRule("M", Reg("""(?m)x\nyz"""),0,None),
        LexRule("U", Reg("""(?u)\u0064\u0065\u0066"""),0,None),
        LexRule("G", Reg("""pqr"""),0,None),
        LexRule("A", Reg("""(?imu)\u0061\nC"""),0,None)
      ),null)
      assertResult(exec(lexer,"abcx\nyzdefpqra\nc") )( Array(
        ("I", "abc"),
        ("M", "x\nyz"),
        ("U", "def"),
        ("G", "pqr"),
        ("A", "a\nc"),
        (SYMBOL_EOF, "")
      ))
    }
    it("skip string pattern if the following is \\w") {
      val lexer = new Lexer(List(
        LexRule("STR", Str("abc"),0,None),
        LexRule("REGEXP", Reg("abc"),0,None),
        LexRule("ASTERISK", Str("*"),0,None),
        LexRule("XYZ", Str("xyz"),0,None)
      ),null)
      assertResult(exec(lexer,"abcxyz*abc*xyz*abcabc") )( Array(
        ("REGEXP","abc"),
        ("XYZ","xyz"),
        ("ASTERISK","*"),
        ("STR","abc"),
        ("ASTERISK","*"),
        ("XYZ","xyz"),
        ("ASTERISK","*"),
        ("REGEXP","abc"),
        ("STR","abc"),
        (SYMBOL_EOF,"")
      ))
    }
    it("rule priority") {
      val lexer = new Lexer(List(
        LexRule("PM", Str("+-"),0,None),
        LexRule("PMA", Str("+-*"),0,None),
        LexRule("ASTERISK", Str("*"), 1,None),
        LexRule("ABC", Reg("abc"),0,None),
        LexRule("ABCD", Reg("abcd"),0,None),
        LexRule("ABCD2", Str("abcd"),2,None),
        LexRule("D", Reg("d"),0,None),
        LexRule("XYZ", Reg("xyz"),0,None),
        LexRule("XYZW", Reg("xyzw"), -1, None),
        LexRule("W", Str("w"),0,None),
        LexRule(null, Str(" "),0,None)
      ),null)
      assert(exec(lexer," +-+-*abcd xyzw") == List(
        ("PM","+-"),
        ("PMA","+-*"),
        ("ABCD2","abcd"),
        ("XYZ","xyz"),
        ("W","w"),
        (SYMBOL_EOF,"")
      ))
    }
    it("longest match") {
      val lexer = new Lexer(List(
        LexRule("PM", Str("+-"),0,None),
        LexRule("PMA", Str("+-*"),0,None),
        LexRule("ASTERISK", Str("*"),0,None),
        LexRule("ABC", Reg("abc"),0,None),
        LexRule("ABCD", Reg("abcd"),0,None),
        LexRule("ABCD2", Reg("abcd"),0,None),
        LexRule("D", Reg("d"),0,None),
        LexRule(null, Str(" "),0,None)
      ),null)
      assertResult(exec(lexer," +-+-*abcd "))(List(
        ("PM", "+-"),
        ("PMA", "+-*"),
        ("ABCD", "abcd"),
        (SYMBOL_EOF, "")
      ))
    }
    it("add rule and exec again after reset") {
      var lexer = new Lexer(List(
        LexRule("ASTERISK", Str("*"),0,None),
        LexRule("ABC", Reg("abc"),0,None),
        LexRule(null, Str(" "),0,None)
      ),null)
      assertResult(exec(lexer," *abc* ") )( List(
        ("ASTERISK", "*"),
        ("ABC", "abc"),
        ("ASTERISK", "*"),
        (SYMBOL_EOF, "")
      ))

      lexer = new Lexer(List(
        LexRule("ASTERISK", Str("*"),0,None),
        LexRule("ABC", Reg("abc"),0,None),
        LexRule(null, Str(" "),0,None),
        LexRule("ABCAST", Reg("abc\\*"), 1,None)
      ),null)
      // reset add
      assertResult(exec(lexer," *abc* ") )( List(
        ("ASTERISK", "*"),
        ("ABCAST", "abc*"),
        (SYMBOL_EOF, "")
      ))

      lexer = new Lexer(List(
        LexRule("ASTERISK", Str("*"),0,None),
        LexRule("ABC", Reg("abc"),0,None),
        LexRule(null, Str(" "),0,None),
        LexRule("ABCAST", Reg("abc\\*"), 1,None),
        LexRule("ABCAST", Reg("abc\\*"), 1,None)
      ),null)
      assertResult(exec(lexer," *abc* ") )( List(
        ("ASTERISK", "*"),
        ("ABCAST", "abc*"),
        (SYMBOL_EOF, "")
      ))
      assert(exec(lexer," *abc* ") == List(
        ("ASTERISK", "*"),
        ("ABCAST", "abc*"),
        (SYMBOL_EOF, "")
      ))
    }
    it("custom callback (without CallbackController)") {
      // デフォルトの挙動がこれでいいのか不明
      val lexer = new Lexer(List(
        LexRule("ERROR", Str("x"),0, Some { (a: Any, b: Any, c: Lexer) =>
          throw new Error("custom callback")
        }),
        LexRule(null, Str(" "),0,None)
      ),null)
      assertThrows[Error](exec(lexer," x ")) //custom callback
    }
    it("custom callback (set CallbackController)") {
      val lex = List(
        LexRule("ERROR", Str("x"),0, Some{ (a:Any, b:Any, c:Lexer) =>
          throw new Error("custom callback")
        }),
        LexRule(null, Str(" "),0,None)
      )
      val lang = Language(lex, List(), "") // lex以外はダミー
      val lexer = new Lexer(lex,new DefaultCallbackController(lang))
      assertThrows[Error](exec(lexer," x ")) //custom callback
    }
  }
}
