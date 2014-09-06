import scala.xml._
import scala.io.Source

object Fourth_Checker {
  def main(args: Array[String]) {

    val chunkSize = 128 * 1024
    // Iterate over all posts which are answers and map their parents (the questions) to the user who answered them.
    val iterator = Source.fromFile("D:\\res.txt")("UTF-8").getLines.grouped(chunkSize)
    var out_stream = new java.io.PrintStream("E:\\checker.txt", "UTF-8")
    System.setOut(out_stream)
    var n = 0;
    var res = 0;
    iterator.foreach { lines => {
      lines.par.foreach { line =>

        if (line.startsWith("  <row"))
        {
          val row = XML.loadString(line)
          //System.err.println((row \ "@CreationDate").toString().substring(0,4))

          if ((row \ "@CreationDate").toString().length > 0 && (row \ "@CreationDate").toString().substring(0,4).equals("2013"))
          {
            System.out.println(line)
          }
        }
      }
    }
    }
    out_stream.close();
  }
}
