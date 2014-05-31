import scala.xml._
import scala.io.Source

object Second_Answer_to_User_Mapping {
  def main(args: Array[String]) {

    val chunkSize = 128 * 1024
    // Iterate over all posts which are accepted answers only and
    // map their parents (the questions) to the user who answered them.
    val iterator = Source.fromFile("D:\\accepted_answers_only.txt")("UTF-8").getLines.grouped(chunkSize)
    var out_stream = new java.io.PrintStream("D:\\answerer_to_question_mapping.txt", "UTF-8")
    System.setOut(out_stream)
    iterator.foreach { lines => {
      lines.par.foreach { line =>

        if (line.startsWith("  <row"))
        {
          val row = XML.loadString(line)
          // We discard 2013 data so we could preform tests on it.
          if ((row \ "@CreationDate").toString().length > 0 &&
            !(row \ "@CreationDate").toString().substring(0,4).equals("2013"))
          {

            var question_id = (row \ "@ParentId").toString()
            var user_id = (row \ "@OwnerUserId").toString()
            System.out.println(user_id + "," + question_id)
          }
        }
      }
    }
    }
    out_stream.close();
  }
}
