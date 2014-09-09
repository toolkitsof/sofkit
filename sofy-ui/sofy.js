Sofy = (function() {

  var consts = {
    'questionAnswers': '#answers',
    'questionSummaryClassSelector': '.question-summary',
    'questionIdPrefix': 'question-summary-',
    'marginLeftForContainer': '94px'
  };

  function init() {
    initGoogleAnalytics();
  
    var url = window.location.href;
    
    // Question page
    if (url.indexOf('questions') !== -1) {
      var $questionAnswers = $(consts.questionAnswers);
      $container = initializeContainer(false);
      //$questionAnswers.prepend($container);
      
      var questionId = extractId(url);
      perQuestion(questionId, $questionAnswers[0], $container);
      
      // When container is ready append to DOM
      $questionAnswers.prepend($container);
    }
    // Results page
    else if (url.indexOf('unanswered') !== -1) {
    
      var $questionsSummaries = $(consts.questionSummaryClassSelector),
          counter = 0;
    
      $questionsSummaries.each(function() {
        // Stackoverflow blocks us if we do too many requests
        if (counter < 2) {
          $container = initializeContainer(true);
          var questionId = this.id.replace(consts.questionIdPrefix, '');
          perQuestion(questionId, this, $container);
          
          // When container is ready append to DOM
          $(this).append($container);
        }
        
        counter++;
      });
    }
    // Main page
    else {
      createSuggestedQuestions();
    }
  }
   
  function createSuggestedQuestions() {
    var href = $("body > .topbar a.profile-me").attr("href");
    var userId = href.split('/')[2];
    callSofyQuestionsEngine(userId, function (questions) {
      var $title = $('<div>').attr('class', 'bulletin-title').html('Questions for you');
      var $sideBar = $('#sidebar .related');
      $question = buildQuestion(questions[0]);
      $sideBar.prepend($question);
      $sideBar.prepend($('<hr>')).prepend($title);
    });
  }
  
  function buildQuestion(question) {
    var $spacer = $('<div>').attr('class', 'spacer');
    var $itemType = $('<div>').attr('class', 'bulletin-item-type');
    var $score = $('<span>').attr('title', 'Vote score (upvotes - downvotes)').html('3');
    $itemType.append($score);
    var $itemContent = $('<div>').attr('class', 'bulletin-item-content');
    var url = 'http://stackoverflow.com/questions/' + question.Id;
    var $link = $('<a>').attr('class', 'question-hyperlink').attr('href', url).html(question.Title);
    $itemContent.append($link);
    var $cbt = $('<br>').attr('class', 'cbt');
    
    $spacer.append($itemType).append($itemContent).append($cbt);
    
    return $spacer;
  }
  
  function initGoogleAnalytics() {
    // You'll usually only ever have to create one service instance.
    var service = analytics.getService('ice_cream_app');

    // You can create as many trackers as you want. Each tracker has its own state
    // independent of other tracker instances.
    var tracker = service.getTracker('UA-XXXXX-X');  // Supply your GA Tracking ID.
  }

  // Creates a html element (a container) to put inside the suggested answerers
  function initializeContainer(isResultsPage) {
    // Create container, use summary class to copy CSS style
    $container = $('<div>')
                  .attr('class', 'summary')
                  .css('margin-bottom', '15px');
                  
    // Special CSS rules for results page
    if (isResultsPage) {
      $container.css('margin-left', consts.marginLeftForContainer);
    }
                  
    // Create header
    $headerContainer = $('<div>')
                          .attr('class', 'subheader');
    
    // Special CSS rules for question page
    if (!isResultsPage) {
      $headerContainer.css('margin-bottom', '6px');
    }
                          
    $header = $('<h1>').html('Ask users to answer')
    $headerContainer.append($header);
    
    $container.append($headerContainer);
    
    return $container;
  }

  // Brings the answerers and adds to HTML to the container, per a specific question
  function perQuestion(questionId, questionSummary, $container) {
    // Call sofy engine
    //var answerersIds = [190744, 47481, 2715725, 2052523];
    callSofyAnswerersEngine(questionId, function(answerersIds) {
    
      var counter = 0;
      var answerersGravatars = [];
      for (var i = 0; i < answerersIds.length; i ++) {
        var answererId = answerersIds[i];
        
        $.get('http://stackoverflow.com/users/' + answererId).done(function(profilePageHtml) {
          var $profilePageHtml = $(profilePageHtml);
          
          $gravatar = $profilePageHtml.find('.gravatar').first();
          $gravatar.css('float', 'left').css('margin-right', '25px');
          
          // Extract answerer id from html
          var profileHref = $gravatar.children('a').first().attr('href');
          var answererId = extractId(profileHref);
          
          var index = answerersIds.indexOf(answererId);
          
          // Create the header and append to gravatar
          $header = $('<h2>').html((index + 1) + '.'); // For example: 1.
          $gravatar.prepend($header);
          
          answerersGravatars[index] = $gravatar;
        }).always(function() {
          counter++;
          
          if (counter == answerersIds.length) {
            //var $moreButton = createMoreButton();
            //answerersGravatars[counter] = $moreButton;
            
            for (var j = 0 ; j < counter ; j++) {
              var $gravatar = answerersGravatars[j];
              
              // Append to DOM
              $container.append($gravatar);
            }
          }
        });
      }
    }); 
  }
  
  function extractId(url) {
    var id = url.substring(0, url.lastIndexOf('/'));
    id = id.substring(id.lastIndexOf('/') + 1);
    return id;
  }
  
  // Creates the more button
  function createMoreButton() {
    var $moreButton = $('<div>'),
        $moreLink = $('<a>'),
        $moreHeader = $('<h3>');
    $moreHeader.css('font-size', '200%').css('margin-top', '15%');
    $moreHeader.html('More...');
    
    $moreButton.append($moreLink);
    $moreLink.append($moreHeader);
    
    return $moreButton;
  }
  
  function callSofyAnswerersEngine(questionId, callback) {
    //var url = 'http://localhost:4567/return_answerers_ids_from_server?id=' + questionId;
    var url = 'http://sof-sofy.herokuapp.com/return_answerers_ids_from_server?id=' + questionId;
    $.ajax(url)
      .success(function(results) {
        var answerersIds = JSON.parse(results);
        callback(answerersIds);
      })
      ;
  }
  function callSofyQuestionsEngine(userId, callback) {
    //var url = 'http://localhost:4567/return_questions_ids_from_server?id=' + userId;
    var url = 'http://sof-sofy.herokuapp.com/return_questions_ids_from_server?id=' + userId;
    $.ajax(url)
      .success(function(results) {
        var questions = JSON.parse(results);
        callback(questions);
      })
      ;
  }

  return {
    'init': init
  };
}())

Sofy.init();