import java.util
import java.util.Date
import org.apache.solr.client.solrj.{SolrServer, SolrQuery}
import org.apache.spark
import scala.collection.mutable.{HashSet, ArrayBuffer}

object Main {
  var lst: ArrayBuffer[UserProperties] = ArrayBuffer[UserProperties]();
  var solrCounter = 0;

  def main(args: Array[String]) {


    var AnsweredQuestionIds: util.ArrayList[String] = new util.ArrayList[String]()
    var AnsweredQuestionBodies: util.ArrayList[String] = new util.ArrayList[String]()
    var AnsweredQuestionTags: util.ArrayList[String] = new util.ArrayList[String]()
    var AnsweredQuestionTitles: util.ArrayList[String] = new util.ArrayList[String]()
    val format = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SS'Z'")
    var LastActivity: Date = format.parse("2013-11-03T18:49:22.757Z");

    AnsweredQuestionTags.add("<javascript><html><regex>")
    AnsweredQuestionTags.add("<javascript><html><css><anchor>")
    AnsweredQuestionTags.add("<javascript><jquery-ajax><asp.net-mvc-4>")
    AnsweredQuestionTags.add("<css>")
    AnsweredQuestionTags.add("<javascript><jquery><tabs><accordion>")
    AnsweredQuestionTags.add("<angularjs><input><filter><numbers>")
    AnsweredQuestionTags.add("<ruby-on-rails-4><captcha>")

    AnsweredQuestionTitles.add("JavaScript string modification (Probably involves regular expression)")
    AnsweredQuestionTitles.add("Html anchor can't change the url?")
    AnsweredQuestionTitles.add("jquery dilaog not showing view no 404 just blank screen mvc 4")
    AnsweredQuestionTitles.add("How to overlap 2 charaters with CSS")
    AnsweredQuestionTitles.add("Stop keyboard keys from affecting jquery")
    AnsweredQuestionTitles.add("Trouble with AngularJS $filter('number'), Deletes number after 3 characters")
    AnsweredQuestionTitles.add("can't install simple_captcha produces uninitialized constant Sprockets::Helpers")

    AnsweredQuestionIds.add("18476915");
    AnsweredQuestionIds.add("18397367");
    AnsweredQuestionIds.add("18397569");
    AnsweredQuestionIds.add("18401286");
    AnsweredQuestionIds.add("19756102");
    AnsweredQuestionIds.add("19593535");
    AnsweredQuestionIds.add("18427273");


    AnsweredQuestionBodies.add("<p>The problem I need to solve is to shorten file paths given by the user. If you didn't know, sometimes it's not possible to enter in paths with spaces in the command prompt. You are required to either put the path in quotes or rename the paths with spaces to  abcdef~1 .</p>\n\n<p>Example:  C:\\Some Folder\\Some File.exe  should become  C:\\SomeFo~1\\SomeFi~1.exe  (case insensitive).</p>\n\n<p>I'm making a function in JavaScript to attempt to shorten file paths using this idea.</p>\n\n<pre><code>function ShortenFilePath(FilePath){\n    var Sections = FilePath.split()\n    for (Index = 0; Index &lt; Sections.length; Index++){\n        while (Sections[Index].length &gt; 6 &amp;&amp; Sections[Index].match(   ) &amp;&amp; !Sections[Index].match( ~1 )){\n            alert(Sections[Index])\n            Sections[Index] = Sections[Index].replace(   ,  )\n            Sections[Index] = Sections[Index].substring(0,6)\n            Sections[Index] = Sections[Index] +  ~1 \n            alert(Sections[Index])\n        }\n    }\n    var FilePath = Sections.join(  )\n    alert(FilePath)\n    return FilePath\n}\n</code></pre>\n\n<p>The problem is, it will leave out the file extension and spit out  C:\\SomeFo~1\\SomeFi~1 . I need help obtaining that file extension (probably through regular expression). If you feel that this function can be optimized, please do share your thoughts.</p>\n\n<p>UPDATE: I believe the problem has been resolved.</p>\n\n<p>UPDATE 2: There were some problems with the previous code, so I revised it a little.</p>\n\n<p>UPDATE 3: Fresh new problem. Yikes. If the name of the file itself without the extension is under 7 letters, then it will turn up as  name.e~1.exe .</p>\n\n<p>UPDATE 4: I think I've finally fixed the problem. I THINK.</p>\n\n<pre><code>function ShortenFilePath(FilePath){\n    var Sections = FilePath.split(  )\n    Sections[Sections.length - 1] = Sections[Sections.length - 1].substring(0,Sections[Sections.length - 1].lastIndexOf( . ))\n    for (Index = 0; Index &lt; Sections.length; Index++){\n        while (Index &gt; 0 &amp;&amp; Sections[Index].match(   ) &amp;&amp; !Sections[Index].match( ~1 )){\n            Sections[Index] = Sections[Index].replace(/ /gm,  )\n            Sections[Index] = Sections[Index].substring(0,6) +  ~1 \n        }\n    }\n    return Sections.join(  ) + FilePath.substring(FilePath.lastIndexOf( . ))\n}\n</code></pre>\n")
    AnsweredQuestionBodies.add("<p>I'm making a sliding effect which is similar to carousel, I set up four boxes, the contents of each box is different, and I use a nav to navigate.I found every time I refresh, the page will return to the first box.But I hope the page return to the box before refresh. Moreover, when I click on the 'a' tags,  #box*  will not be added to the url. How can this be resolved? Can someone help me?Thank you very much! I'm sorry for my poor english</p>\n\n<pre><code>    &lt;ul id= menu  class= nav nav-list span2 &gt;\n    &lt;li class= nav-header &gt;nav&lt;/li&gt;\n    &lt;li class= active &gt;\n        &lt;a href= #box1  class= link &gt;box1&lt;/a&gt;\n    &lt;/li&gt;\n    &lt;li&gt;\n        &lt;a href= #box2  class= link &gt;box2&lt;/a&gt;\n    &lt;/li&gt;\n    &lt;li&gt;\n        &lt;a href= #box3  class= link &gt;box3&lt;/a&gt;\n    &lt;/li&gt;\n    &lt;li&gt;\n        &lt;a href= #box4  class= link &gt;box4&lt;/a&gt;\n    &lt;/li&gt;\n    &lt;/ul&gt;\n\n\n&lt;li id= box1  class= box &gt;\n\n  &lt;div&gt;XXXXX&lt;/div&gt;\n &lt;/li&gt; \n&lt;li id= box2  class= box &gt;\n\n  &lt;div&gt;XXXXX&lt;/div&gt;\n &lt;/li&gt;\n</code></pre>\n\n<p>javascipt code  </p>\n\n<pre><code>$('a.link').click(function(){  \n      $(this).parents( ul ).children( li ).removeClass( active );\n      $(this).parents( li ).addClass( active );\n      $('#wrapper').scrollTo($(this).attr('href'),800);\n      return false;\n});\n</code></pre>\n")
    AnsweredQuestionBodies.add("<p>Why is my dialog not popping? </p>\n\n<p>jQuery</p>\n\n<pre><code>    $('.ITA').dialog({\n    autoOpen: false,\n    draggable: true,\n    width: 400,\n    resizable: false,\n    dialogClass:  ui-dialog ,\n    modal: true,\n   // show: { effect: 'fade', duration: 300 }\n  });\n\n $( .AllItemsBtn ).on( click , function (e) {\n    e.preventDefault();\n   // $(this).css('cursor', 'pointer');\n    var url = $(this).attr('href');\n    alert(url);\n    $('.ITA').load(url, function () {\n        $('.ITA').dialog( open );\n\n    });\n   });\n</code></pre>\n\n<p>Controller</p>\n\n<pre><code>  public ActionResult GetItemsToAdd()\n    {\n        var Uid = WebSecurity.GetUserId(User.Identity.Name);\n\n        var UserItems = from i in db.Items\n                        where i.user_id == Uid \n                        select i;\n\n        var results = UserItems;\n\n        return PartialView( _AllItemsPartial , UserItems );\n    }\n</code></pre>\n\n<p>VIEW _AllItemPartial: the view to load into the dialog</p>\n\n<pre><code>@model IEnumerable&lt;Item&gt;\n\n&lt;style&gt;\n.ui-dialog,.ui-dialog,.ui-widget, \n.ui-widget-content, .ui-corner-all, \n.ui-draggable, \n.ui-resizable {background-color:#ffd800 !important;\n\n}\n\n\n&lt;/style&gt;\n\n@foreach (var item in Model)\n{ \n&lt;ul&gt;\n    &lt;li&gt;\n        @Html.DisplayFor(modelItem =&gt; item.ID)\n    &lt;/li&gt;\n     &lt;li&gt;\n        @Html.DisplayFor(modelItem =&gt; item.item_name)\n    &lt;/li&gt;\n    &lt;li&gt;\n        @Html.DisplayFor(modelItem =&gt; item.item_description)\n    &lt;/li&gt;\n&lt;/ul&gt;\n }\n</code></pre>\n\n<p>View _ItemPartial: addItemsBtn in this view</p>\n\n<pre><code>  &lt;div id= tradeItem &gt;\n\n @foreach (var item in Model)\n{ \n&lt;ul&gt;\n    &lt;li&gt;\n        @Html.DisplayFor(modelItem =&gt; item.ID)\n    &lt;/li&gt;\n     &lt;li&gt;\n        @Html.DisplayFor(modelItem =&gt; item.item_name)\n    &lt;/li&gt;\n    &lt;li&gt;\n        @Html.DisplayFor(modelItem =&gt; item.item_description)\n    &lt;/li&gt;\n&lt;/ul&gt;\n\n\n}\n&lt;/div&gt;\n\n  &lt;a class= AllItemsBtn  id= AllItemsBtn  href='@Url.Action( GetItemsToAdd )' &gt;Add \n File...&lt;/a&gt;\n\n &lt;div class =  ITA &gt;/*load to this div*/&lt;/div&gt;\n</code></pre>\n")
    AnsweredQuestionBodies.add("<p>I have 2 Unicode arrows, that I would like to have on top of one another ( eg as a column sorter ).</p>\n\n<p>How can I do this? - a <code>&lt;br&gt;</code> tag in a span won't work, as it breaks the entire content flow.</p>\n\n<p>I also cant set <code>position:absolute</code> and top 0, left 0, as it needs to be relatively positioned. </p>\n\n<p>See fiddle:\n<a href= http://jsfiddle.net/YrJTN/1/  rel= nofollow >http://jsfiddle.net/YrJTN/1/</a></p>\n")
    AnsweredQuestionBodies.add("<p>i had a little peak around Stackoverflow and couldn't find the answer to this question.</p>\n\n<p>On my website I have 2 Jquery elements.. Tabs and accordion. They look great but i'm having issues with the keyboard. </p>\n\n<p>Because i use a netbook, i sometimes find it easier to surf pages just by pressing up or down on the keyboard.. However if a Jquery element is selected, i find myself cycling through seperate sections. </p>\n\n<p>It seams Jquery has built-in key commands which i do not want. How can i remove all key commands?</p>\n\n<p>It should only be possible to affect the elements with the mouse!</p>\n\n<p>Any thoughts? Thanks</p>\n")
    AnsweredQuestionBodies.add("<p>I have an input that requires the entry to be only numbers (I know there is an <code>input type= number </code> but I don't like the spinner that gets put on it), so I thought I would use AngularJS's $filter('number') and watch the variable on the <code>$scope</code> for changes and filter it accordingly.  It works fine but when someone inputs a number over 1000, it deletes the entire number and starts over again.</p>\n\n<p>Here's a fiddle that demostrates the problem: <a href= http://jsfiddle.net/xxAq2/  rel= nofollow >http://jsfiddle.net/xxAq2/</a></p>\n")
    AnsweredQuestionBodies.add("<p>I have included the simple_captcha gem as instructed on their site:</p>\n\n<pre><code>gem 'simple_captcha', :git =&gt; 'git://github.com/galetahub/simple-captcha.git'\n</code></pre>\n\n<p>I have then run bundler to install it.</p>\n\n<p>Finally when I go to run the following command I get an error:</p>\n\n<pre><code> rails generate simple_captcha\n\n.rvm/gems/ruby-1.9.3-p327@eapi4/bundler/gems/simple-captcha-e99cc7e8bf6b/lib/simple_captcha/form_builder.rb:7:in `included': uninitialized constant Sprockets::Helpers (NameError)\n</code></pre>\n\n<p>I've searched on the web and can't find any other users with this problem.</p>\n\n<p>Any help appreciated</p>\n")

    val r = new UserProperties("2581506", 7, AnsweredQuestionIds, "0", AnsweredQuestionBodies, AnsweredQuestionTitles, AnsweredQuestionTags, LastActivity);
    lst += r;
    (new InsertAnswererToSolr).send(lst);
  }
}
