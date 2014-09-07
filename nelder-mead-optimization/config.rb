configs:
  dynamic:  
    -
      - 0 #mintf
      - 5 #mindf
      - 0 #minwl
      - 25 #maxqt
      - 10 #title boost
      - 20 #tags boost
      - 0.1 # body boost
    -
      - 4
      - 3
      - 6 
      - 30
      - 10
      - 10
      - 0.1
    -
      - 2
      - 4
      - 2
      - 10
      - 5
      - 15 
      - 21
    -
      - 3
      - 2
      - 6
      - 10
      - 20
      - 10
      - 2
    -
      - 2
      - 6
      - 2
      - 20
      - 15
      - 5
      - 2
    -
      - 2
      - 3
      - 2
      - 15
      - 10
      - 10
      - 5
    -
      - 1
      - 5
      - 1
      - 25
      - 15
      - 5
      - 1.5
    -
      - 2
      - 4
      - 2
      - 20
      - 12
      - 15
      - 0.5
  static:
    query_parameters:
      initial_questions_count: 500
    mlt_params:
      mlt: true
      stopwords: true
      mlt.fl: Tags Title Body
      mlt.minwl: 3
      mlt.maxqt: 50
      mlt.mindf: 5
      mlt.mintf: 3
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
    question_similarity_params:
      fl: Id
      rows: 8
      start: 0