configs:
  dynamic:
    - mlt.mintf: 1
    - mlt.mintf: 4
  static:
    query_parameters:
      initial_questions_count: 50
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