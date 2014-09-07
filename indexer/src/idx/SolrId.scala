package idx

import org.apache.solr.common.SolrInputDocument
import java.util.ArrayList
import org.apache.solr.client.solrj.impl.HttpSolrServer
import org.apache.solr.morphlines.solr.SolrMorphlineContext
import scala.collection.mutable.ArrayBuffer

case class SolrId(Id:String,PostTypeId:String,ParentId:String, AcceptedAnswerId:String,CreationDate:String,Score:String, Body:String,
                  OwnerUserId:String, LastActivityDate:String, Title:String, Tags:String, AnswerCount:String)
class Feed2Solr
{
  // The SOLR URL we would like to index to.
  val url = "http://localhost:8983/solr/collection1"
  val solrDocuments = new ArrayList[SolrInputDocument]()
  val server= new HttpSolrServer( url )


  // Send a bulk of SOLR documents to SOLR.
  def send(posts:ArrayBuffer[SolrId])
  {
      val docs: ArrayList[SolrInputDocument] = new ArrayList[SolrInputDocument]();
      posts.foreach(post=>docs.add(getSolrDocument(post)))
      server.add(docs);
      server.commit();
  }

  // Build a SolrInputDocument and return it.
  def getSolrDocument(post: SolrId): SolrInputDocument =
  {
    val document = new SolrInputDocument()
    document.addField("Id",post.Id);
    document.addField("PostTypeId",post.PostTypeId);
    document.addField("ParentId",post.ParentId);
    document.addField("AcceptedAnswerId",post.AcceptedAnswerId);
    document.addField("CreationDate",post.CreationDate + "Z");
    document.addField("Score",post.Score);
    document.addField("Body",post.Body);
    document.addField("OwnerUserId",post.OwnerUserId);
    document.addField("LastActivityDate",post.LastActivityDate + "Z");
    document.addField("Title",post.Title);
    document.addField("Tags",post.Tags);
    document.addField("AnswerCount",post.AnswerCount);

    document
  }
}
