import java.util
import java.util.{Date, ArrayList}
import org.apache.solr.client.solrj.impl.HttpSolrServer
import org.apache.solr.common.SolrInputDocument
import scala.collection.mutable.ArrayBuffer

/**
 * Created by Awesome on 5/10/2014.
 */
case class UserProperties (Id:String, NumAnswered:Integer , AnsweredQuestionIds:util.ArrayList[String], Score:String, QuestionBody:util.ArrayList[String],
                           QuestionTitle:util.ArrayList[String], QuestionTags:util.ArrayList[String], LastActivityDate:Date)

class InsertAnswererToSolr
{
  // The SOLR URL we would like to index to.
  val url = "http://130.211.93.220:8983/solr/collection2"
  val solrDocuments = new ArrayList[SolrInputDocument]()
  val server= new HttpSolrServer( url )


  // Send a bulk of SOLR documents to SOLR.
  def send(users:ArrayBuffer[UserProperties])
  {
    val docs: ArrayList[SolrInputDocument] = new ArrayList[SolrInputDocument]();
    users.foreach(userprop=>docs.add(getSolrDocument(userprop)))
    server.add(docs);
    //server.commit();
  }

  // Build a SolrInputDocument and return it.
  def getSolrDocument(userprop: UserProperties): SolrInputDocument =
  {
    val document = new SolrInputDocument()
    document.addField("AnswererId",userprop.Id);
    document.addField("NumAnswered",userprop.NumAnswered)
    document.addField("AnsweredQuestionIds",userprop.AnsweredQuestionIds)
    document.addField("Score",userprop.Score);
    document.addField("Body",userprop.QuestionBody);
    document.addField("LastActivityDate",userprop.LastActivityDate);
    document.addField("Title",userprop.QuestionTitle);
    document.addField("Tags",userprop.QuestionTags);

    document
  }
}