configs:
  dynamic:
    -
      # Config from results
      - 3
      - 1
      - 12
      - 5.25
      - 16.9
      - 730
      - 22.2
    -
      - 5 #mindf
      - 0 #minwl
      - 25 #maxqt
      - 10 #title boost
      - 20 #tags boost
      # Use this to optimize get answerers
      #- 1400 # mindf boost question
      #- 400 #bodyboost question
      # Use this to optimize get questions
      - 1400 # mindf boost question
      - 400 #bodyboost question
    -
      - 4
      - 3
      - 30
      - 10
      - 10
      - 1200
      - 300
    -
      - 2
      - 4
      - 10
      - 5
      - 15
      - 600
      - 150
    -
      - 3
      - 2
      - 10
      - 20
      - 10
      - 1000
      - 100
    -
      - 2
      - 6
      - 20
      - 15
      - 5
      - 1400
      - 100
    -
      - 2
      - 3
      - 15
      - 10
      - 10
      - 600
      - 10
    -
      - 1
      - 5
      - 25
      - 15
      - 5
      - 1000
      - 10
    -
      - 2
      - 4
      - 20
      - 12
      - 15
      - 1000
      - 600
  static:
    query_parameters:
      initial_questions_count: 1000
    mlt_params:
      mlt: true
      stopwords: true
      mlt.fl: Tags Title
      mlt.minwl: 3
      mlt.maxqt: 50
      mlt.mindf: 5
      mlt.mintf: 0
      mlt.boost: true
      # This \/ is now set used by configuration
      #mlt.qf: Title^10 Tags^20 Body^0.01
      debugQuery: true
      rows: 0
    similarity_query_params:
      fl: AnswererId
      defType: edismax
      stopwords: true
      lowercaseOperators: true
      rows: 50
      start: 0
    body_query_params:
      fl: none
      tv.fl: Body
      tv.tf_idf: true
      tv.df: true
      tv.tf: true
    body_query_params_question:
      mintf: 1
      maxtf: 10
      mindf: 1000
      maxdf: 200000
      bodyboost: 50
    body_query_params_answerer:
      mintf: 5
      maxtf: 30
      mindf: 1400
      maxdf: 5000
      bodyboost: 400
    question_similarity_params:
      fl: Id
      rows: 8
      start: 0