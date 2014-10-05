import java.util
import java.util.Date
import org.apache.solr.client.solrj.impl.HttpSolrServer
import org.apache.solr.client.solrj.response.QueryResponse
import org.apache.solr.client.solrj.{SolrServer, SolrQuery}
import org.apache.spark
import spark.SparkContext
import spark.SparkContext._
import scala.collection.mutable.{HashSet, ArrayBuffer}

object Third_SparkRunner {
  var lst: ArrayBuffer[UserProperties] = ArrayBuffer[UserProperties]();
  var solrCounter = 0;

  def main(args: Array[String]) {

    val hsUsers = new HashSet[String]

    // Read the already indexed users file so we would skip them.
    // The file is created as a result of a wget from collection2 (the users collection).
    // The results are loaded to a HashSet.
    println("Starting to read existing users...")
    val users = scala.io.Source.fromFile("E:\\stackoverflow\\already_indexed_users.txt");
    for (user <- users.getLines()) {
      hsUsers += user
    }
    println ("We have " + hsUsers.size + " users already indexed.")

    println("Starting the solr indexing work..")
    val server:SolrServer  = new HttpSolrServer("http://localhost:8983/solr/collection1");
    val sc = new SparkContext("local", "AggregationJob")
    val file = sc.textFile("E:\\stackoverflow\\answerer_to_question_mapping.txt")
    val l = file.filter(x => x.split(",").size > 1).
      map(x => (x.split(",")(0), x.split(",")(1))).
      filter(x => !x._1.equals("")).
      groupByKey().
      filter(x => x._2.size < 1000).
      //filter(x => !hsUsers.contains(x._1)).
      collect.
      foreach(x => querySolr(x, server))

    sc.stop()
  }

  def querySolr(arg: (String, Iterable[String]),arg2: SolrServer) = {

    var query_str = ""
    var n = 0;
    for (question <- arg._2)
    {
      n+=1
      query_str += " OR Id:" + question

    }
    val query:SolrQuery = new SolrQuery();
    query_str = query_str.replaceFirst(" OR ","")
    println("q is " + query_str)
    query.setQuery(query_str);
    query.set("wt", "xml");
    query.set("rows", "10000");
    val response:QueryResponse  = arg2.query(query);
    buildToNewCollection(response, arg._1)
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
