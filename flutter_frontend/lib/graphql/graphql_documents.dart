// --- Mutations ---

const String logMoodMutation = r'''
mutation LogMood($input: MoodLogInput!) {
  logMood(input: $input) {
    _id
    mood
    journalText
    sentimentScore
  }
}
''';

const String updateMoodMutation = r'''
mutation UpdateMood($id: String!, $input: MoodLogInput!) {
  updateMood(id: $id, input: $input) {
    _id
    mood
    journalText
    sentimentScore
  }
}
''';

const String deleteMoodMutation = r'''
mutation DeleteMood($id: String!) {
  deleteMood(id: $id)
}
''';

// --- Queries ---

const String getTodayMoodQuery = r'''
query GetTodayMood {
  getTodayMood {
    _id
    mood
    journalText
    sentimentScore
  }
}
''';

const String getMoodHistoryQuery = r'''
query GetMoodHistory($range: DateRangeInput!) {
  getMoodHistory(range: $range) {
    _id
    mood
    journalText
    sentimentScore
  }
}
''';

const String getMoodStatsQuery = r'''
query GetMoodStats {
  getMoodStats {
    averageMoodScore
    moodCount
    positiveDays
    negativeDays
    mostUsedWords
    streak
  }
}
''';
