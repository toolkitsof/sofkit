import scala.xml._
import scala.io.Source
import scala.collection.mutable.HashSet

object First_Extract_Answers {
  def main(args: Array[String]) {
    val hsAns = new HashSet[String]

    // Read all answer IDs to file as a result of a solr query using wget.
    // The file was created as a result of a wget from collection1 for all
    // "AcceptedAnswerId" properties in collection1.
    // For example, in Windows:
    // wget-1.14.exe "http://localhost:8983/solr/collection1/select?q=-AcceptedAnswerId%3A%22%22&rows=1000000000&fl=AcceptedAnswerId&wt=csv&indent=true" -O answer_ids.txt
    println("Starting to read accepted answer IDs file...")
    var answers = scala.io.Source.fromFile("E:\\stackoverflow\\answer_ids.txt");
    for (ans <- answers.getLines()) {
      hsAns += ans
    }

    // In this phase we build an XML which contains only the answers from posts.xml
    println("Extracting answers from posts...")
    val chunkSize = 128 * 1024
    val iterator = Source.fromFile("E:\\stackoverflow\\Posts.xml")("UTF-8").getLines.grouped(chunkSize)
    var out_stream = new java.io.PrintStream("E:\\stackoverflow\\accepted_answers_content.txt", "UTF-8")
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
