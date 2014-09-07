configs:
  -
    query_parameters:
      initial_questions_count: 50
    mlt_params:
      mlt: true
      stopwords: true
      mlt.fl: Tags Title
      mlt.minwl: 3
      mlt.maxqt: 20
      mlt.mindf: 5
      mlt.mintf: 1
      mlt.boost: true
      mlt.qf: Title^10 Tags^200
      debugQuery: true
      rows: 0
    similarity_query_params:
      fl: AnswererId
      defType: edismax
      stopwords: true
      lowercaseOperators: true
      rows: 8
      start: 0
    body_query_params:
      fl: none
      tv.fl: Body
      tv.tf_idf: true
      tv.df: true
      tv.tf: true
    question_similarity_params:
      fl: Id
      rows: 8
      start: 0