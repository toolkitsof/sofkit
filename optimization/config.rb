configs:
  -
    query_parameters:
      initial_questions_count: 500
    mlt_params:
      mlt: true
      stopwords: true
      mlt.fl: Tags Title
      mlt.minwl: 3
      mlt.maxqt: 1000
      mlt.mindf: 300
      mlt.mintf: 1
      mlt.boost: true
      mlt.qf: Title^10 Tags^20
      debugQuery: true
      rows: 0
    similarity_query_params:
      fl: AnswererId
      defType: edismax
      stopwords: true
      lowercaseOperators: true
      rows: 800