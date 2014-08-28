Sofy = (function() {

  var consts = {
    'questionSummaryClassSelector': '.bottom-share-links', // Config for results page: '.question-summary',
    'questionIdPrefix': 'question-summary-',
    'marginLeftForContainer': '94px'
  };

  function init() {
    var $questionsSummaries = $(consts.questionSummaryClassSelector);
    
    $questionsSummaries.each(function() {
      $container = initializeContainer();
      var questionId = extractQuestionIdFromQuestionPage(this); // extractQuestionIdFromResultsPage(this)
      perQuestion(questionId, this, $container);
    });
  }

  // Creates a html element (a container) to put inside the suggested answerers
  function initializeContainer() {
    // Create container, use summary class to copy CSS style
    $container = $('<div>')
                  .attr('class', 'summary')
                  // Use these for results-page:
                  //.css('margin-left', consts.marginLeftForContainer)
                  //.css('margin-bottom', '15px')
                  ;
                  
    // Create header
    $headerContainer = $('<div>')
                        .attr('class', 'subheader')
                        .css('margin-bottom', '0px') // Comment this out to use results page
                        ;
    $header = $('<h1>').html('Ask users to answer');
    $headerContainer.append($header);
    
    $container.append($headerContainer);
    
    return $container;
  }
  
  function extractQuestionIdFromQuestionPage(questionSummary) {
    var textWithQuestionId = $(questionSummary).find('a:first').attr('href');
    var textWithQuestionId = textWithQuestionId.substring(0, textWithQuestionId.lastIndexOf('/'));
    var textWithQuestionId = textWithQuestionId.substring(textWithQuestionId.lastIndexOf('/') + 1);
    return textWithQuestionId;
  }
  
  function extractQuestionIdFromResultsPage(questionSummary) {
    var questionId = questionSummary.id.replace(consts.questionIdPrefix, '');
    return questionId;
  }

  // Brings the answerers and adds to HTML to the container, per a specific question
  function perQuestion(questionId, questionSummary, $container) {
    
    // TODO: Call sofy engine
    var answerersIds = [47481, 190744, 2052523, 2715725];
    
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
          $(questionSummary).after($container);
          
          // Use this for results page:
          //$(questionSummary).append($container);
        }
      });
    }
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

  return {
    'init': init
  };
}())

Sofy.init();