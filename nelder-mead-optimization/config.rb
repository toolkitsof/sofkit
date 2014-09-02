configs:
  dynamic:  
    -
      - 1 #mintf
      - 2 #mindf
      - 3 #minwl
      - 20 #maxqt
    -
      - 4
      - 3
      - 6
      - 30      
    -
      - 2
      - 4
      - 2
      - 10
    -
      - 3
      - 2
      - 6
      - 10
    -
      - 2
      - 6
      - 2
      - 20
  static:
    query_parameters:
      initial_questions_count: 500
    mlt_params:
      mlt: true
      stopwords: true
      mlt.fl: Tags Title
      mlt.minwl: 3
      mlt.maxqt: 20
      mlt.mindf: 5
      mlt.mintf: 3
      mlt.boost: true
      mlt.qf: Title^10 Tags^200
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