import idx.{Feed2Solr, SolrId}
import scala.collection.mutable.ArrayBuffer
import scala.xml._
object Main
{
  def main(args: Array[String])
  {
    var n = 1;
    val lst: ArrayBuffer[SolrId] = ArrayBuffer[SolrId]();

    // Read a local Posts.xml file to be indexed.
    // We currently support Posts.xml only, since it provides all requirements.
    var Posts = scala.io.Source.fromFile("E:\\stackoverflow\\Posts.xml");

    // Iterate over all lines, and extract meaningful rows of data, and build a SOLR
    // object from them.
    for (post <- Posts.getLines())
    {
      if (post.startsWith("  <row"))
      {

        // The purpose of this parameter is to handle failure.
        // If we fail while indexing, we can tell it to start from a later index by changing the condition.
        if (n > 19000000)
        {
          val row = XML.loadString(post);
          val SolrDoc = new SolrId((row \ "@Id").toString(),
            (row \ "@PostTypeId").toString(),
            (row \ "@ParentId").toString(),
            (row \ "@AcceptedAnswerId").toString(),
            (row \ "@CreationDate").toString(),
            (row \ "@Score").toString(),
            (row \ "@Body").toString(),
            (row \ "@OwnerUserId").toString(),
            (row \ "@LastActivityDate").toString(),
            (row \ "@Title").toString(),
            (row \ "@Tags").toString(),
            (row \ "@AnswerCount").toString())

          //println(SolrDoc.toString)lst
          lst += SolrDoc;

        }

        n = n + 1

        if ((n + 1) % 40001 == 0)
        {
          println ("passed " + n + " lines")
        }
      }

      // Send results to SOLR as a bulk to prevent network bottleneck.
      if ((lst.size + 1) % 40001 == 0)
      {
        println (lst.size)
        (new Feed2Solr).send(lst)
        lst.clear();

      }
    }

    println (lst.size)
    (new Feed2Solr).send(lst)
    lst.clear();

    println(n)
  }
}