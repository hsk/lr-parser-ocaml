package pg

import org.scalatest.FunSpec
import pg.precompiler.ruleparser.{language_language, language_parser}
import pg.parsergenerator.parsergenerator.{genParserGenerator,getParser}
import pg.parser.parser.{parse}
import data.language_language.{language_language_without_callback}
import java.nio.file.{Paths, Files}
import java.nio.charset.StandardCharsets

class language_parsing_test extends FunSpec {

  def write(path: String, txt: String): Unit = {
    Files.write(Paths.get(path), txt.getBytes(StandardCharsets.UTF_8))
  }
  
  def read(path: String): String = scala.io.Source.fromFile(path, "UTF-8").getLines.mkString

  val input = read("language")

  describe("language parsing test") {
    val parser = getParser(genParserGenerator(language_language)) // language_parserと同一のものであることが期待される
    it("parsing language file") {
      assertResult(parse(parser, input).toString )( language_language_without_callback.toString)
    }
    // languageファイルを読み取ってパーサを生成したい
    it("language_parser") {
      assertResult(parse(language_parser, input).toString )( language_language_without_callback.toString)
    }
  }

  // TODO: languageファイルにコールバックも記述可能にして、それを読み取れるようにする
}

