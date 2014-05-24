import scala.xml._
import scala.io.Source
import scala.collection.mutable.HashSet

object First_Extract_Answers {
  def main(args: Array[String]) {
    val hsAns = new HashSet[String]

    println("Starting to read answers file...")
    var answers = scala.io.Source.fromFile("D:\\stackoverflow\\aaaa");
    for (ans <- answers.getLines()) {
      hsAns += ans
    }


    println("Extracting answers from posts...")
    val chunkSize = 128 * 1024
    val iterator = Source.fromFile("D:\\stackoverflow\\Posts.txt")("UTF-8").getLines.grouped(chunkSize)
    var out_stream = new java.io.PrintStream("D:\\resa.txt", "UTF-8")
    System.setOut(out_stream)
    var n = 0;
    var res = 0;
    iterator.foreach { lines => {
      lines.par.foreach { line =>

        if (line.startsWith("  <row")) {
          n = n + 1;
          if (n % 10000 == 0)
          {
            println(n)
            println(res)
          }
          val row = XML.loadString(line)
          var id = (row \ "@Id").toString()
          if (hsAns.contains(id))
            System.out.println(line)
        }
      }
    }
    }
  }
}
