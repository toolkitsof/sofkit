Sofy = (function() {

  var consts = {
    'questionSummaryClassSelector': '.question-summary',
    'questionIdPrefix': 'question-summary-',
    'marginLeftForContainer': '94px'
  };

  function init() {
    var $questionsSummaries = $(consts.questionSummaryClassSelector),
        counter = 0;
    
  
    $questionsSummaries.each(function() {
      // Stackoverflow blocks us if we do too many requests
      if (counter < 2) {
        $container = initializeContainer();
        perQuestion(this, $container);
      }
      
      counter++;
    });
  }

  // Creates a html element (a container) to put inside the suggested answerers
  function initializeContainer() {
    // Create container, use summary class to copy CSS style
    $container = $('<div>')
                  .attr('class', 'summary')
                  .css('margin-left', consts.marginLeftForContainer)
                  .css('margin-bottom', '15px');
                  
    // Create header
    $headerContainer = $('<div>').attr('class', 'subheader')
    $header = $('<h1>').html('Ask users to answer')
    $headerContainer.append($header);
    
    $container.append($headerContainer);
    
    return $container;
  }

  // Brings the answerers and adds to HTML to the container, per a specific question
  function perQuestion(questionSummary, $container) {
    var questionId = questionSummary.id.replace(consts.questionIdPrefix, '');
    
    // Call sofy engine
    //var answerersIds = [190744, 47481, 2715725, 2052523];
    callSofyEngine(questionId, function(answerersIds) {
    
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
          var answererId = profileHref.substring(0, profileHref.lastIndexOf('/'));
          answererId = profileHref.substring(answererId.lastIndexOf('/') + 1);
          
          var index = answerersIds.indexOf(parseInt(answererId));
          
          // Create the header and append to gravatar
          $header = $('<h2>').html((index + 1) + '.'); // For example: 1.
          $gravatar.prepend($header);
          
          answerersGravatars[index] = $gravatar;
        }).always(function() {
          counter++;
          
          if (counter == answerersGravatars.length) {
            //var $moreButton = createMoreButton();
            //answerersGravatars[counter] = $moreButton;
            
            for (var j = 0 ; j < counter ; j++) {
              var $gravatar = answerersGravatars[j];
              
              // Append to DOM
              $container.append($gravatar);
            }
            
            // When container is ready append to DOM
            $(questionSummary).append($container);
          }
        });
      }
    }); 
  }
  
  // Creates the more button
  function createMoreButton() {
    $moreButton = $('<div>');
    $moreLink = $('<a>');
    $moreHeader = $('<h3>');
    $moreHeader.css('font-size', '200%').css('margin-top', '15%');
    $moreHeader.html('More...');
    
    $moreButton.append($moreLink);
    $moreLink.append($moreHeader);
    
    return $moreButton;
  }
  
  function callSofyEngine(questionId, callback) {
    var url = 'http://localhost:4567/return_answerers_ids_from_server?id=' + questionId;
    $.ajax(url)
      .success(function(results) {
        callback(results);
      })
      ;
  }

  return {
    'init': init
  };
}())

Sofy.init();