import java.util
import java.util.Date
import org.apache.solr.client.solrj.impl.HttpSolrServer
import org.apache.solr.client.solrj.response.QueryResponse
import org.apache.solr.client.solrj.{SolrServer, SolrQuery}
import org.apache.spark
import spark.SparkContext
import spark.SparkContext._
import scala.collection.mutable.{HashSet, ArrayBuffer}

object Fifth_Optimization {
  var lst: ArrayBuffer[UserProperties] = ArrayBuffer[UserProperties]();
  var solrCounter = 0;

  def main(args: Array[String]) {

    val hsUsers = new HashSet[String]

    println("Starting to read existing users...")
    val users = scala.io.Source.fromFile("E:\\vvv.txt");
    for (user <- users.getLines()) {
      hsUsers += user
    }

    println ("users have " + hsUsers.size + " already indexed.")
    println("Starting the solr indexing work..")
    val server:SolrServer  = new HttpSolrServer("http://localhost:8983/solr/collection1");

    val query:SolrQuery = new SolrQuery();
    var query_str = ""
    query_str = query_str.replaceFirst(" OR ","")
    println("q is " + query_str)
    query.setQuery(query_str);
    query.set("wt", "xml");
    query.set("rows", "10000");
    val response:QueryResponse  = server.query(query);

  }

  def querySolr(arg: (String, Seq[String]),arg2: SolrServer) = {

    var query_str = ""
    var n = 0;
    for (question <- arg._2)
    {
      n+=1
      query_str += " OR Id:" + question

    }
  }

    def buildToNewCollection(arg: QueryResponse, userid: String)
  {
    var AnsweredQuestionIds : util.ArrayList[String] = new util.ArrayList[String]()
    var AnsweredQuestionBodies : util.ArrayList[String] = new util.ArrayList[String]()
    var AnsweredQuestionTags : util.ArrayList[String] = new util.ArrayList[String]()
    var AnsweredQuestionTitles : util.ArrayList[String] = new util.ArrayList[String]()
    val format = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SS'Z'")
    var LastActivity : Date  = format.parse("1970-01-01T00:00:00.00Z");

    val numRes = arg.getResults.getNumFound().toInt;
    for(i <- 0 until numRes)
    {
      AnsweredQuestionIds.add(arg.getResults.get(i).get("Id").toString)
      AnsweredQuestionBodies.add(arg.getResults.get(i).get("Body").toString)
      AnsweredQuestionTags.add(arg.getResults.get(i).get("Tags").toString)
      AnsweredQuestionTitles.add(arg.getResults.get(i).get("Title").toString)
      if (arg.getResults.get(i).get("LastActivityDate").asInstanceOf[Date].after(LastActivity))
        LastActivity = arg.getResults.get(i).get("LastActivityDate").asInstanceOf[Date]
    }

    val r = new UserProperties(userid,numRes, AnsweredQuestionIds,"0",AnsweredQuestionBodies,AnsweredQuestionTitles,AnsweredQuestionTags,LastActivity);
    lst += r;
    solrCounter = solrCounter + 1
    if (solrCounter % 10 == 0)
    {
      (new InsertAnswererToSolr).send(lst);
      lst.clear()
    }

  }
}
