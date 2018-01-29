package pg.parsergenerator

import org.scalatest.FunSpec
import pg.parsergenerator.nullableset.{NullableSet,generateNulls,isNullable}
import pg.{data, token}
import data.sample_language.test_sample_grammar

class nullableset_test extends FunSpec {

  describe("NullableSet test") {
    val nulls = generateNulls(test_sample_grammar)
    it("T is Nullable") {
      assert(isNullable(nulls, "T"))
    }
    it("LIST is Nullable") {
      assert(isNullable(nulls, "LIST"))
    }
    it("HOGE is not Nullable") {
      assert(!isNullable(nulls, "HOGE"))
    }
    it("E is not Nullable") {
      assert(!isNullable(nulls, "E"))
    }
    it("S is not Nullable") {
      assert(!isNullable(nulls, "S"))
    }
  }
}
