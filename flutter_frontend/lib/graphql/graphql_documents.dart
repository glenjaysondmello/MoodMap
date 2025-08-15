// --- Mutations ---

const String logMoodMutation = r'''
mutation LogMood($input: MoodLogInput!, $userId: String!) {
  logMood(input: $input, userId: $userId) {
    _id
    userId
    date
    mood
    journalText
    sentimentScore
    createdAt
    updatedAt
  }
}
''';

const String updateMoodMutation = r'''
mutation UpdateMood($id: String!, $input: MoodLogInput!, $userId: String!) {
  updateMood(id: $id, input: $input, userId: $userId) {
    _id
    userId
    date
    mood
    journalText
    sentimentScore
    createdAt
    updatedAt
  }
}
''';

const String deleteMoodMutation = r'''
mutation DeleteMood($id: String!, $userId: String!) {
  deleteMood(id: $id, userId: $userId)
}
''';

// --- Queries ---

const String getTodayMoodQuery = r'''
query GetTodayMood($userId: String!) {
  getTodayMood(userId: $userId) {
    _id
    userId
    date
    mood
    journalText
    sentimentScore
    createdAt
    updatedAt
  }
}
''';

const String getMoodHistoryQuery = r'''
query GetMoodHistory($range: DateRangeInput!, $userId: String!) {
  getMoodHistory(range: $range, userId: $userId) {
    _id
    userId
    date
    mood
    journalText
    sentimentScore
    createdAt
    updatedAt
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
