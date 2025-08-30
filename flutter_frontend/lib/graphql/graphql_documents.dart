// --- Mutations ---

const String logMoodMutation = r'''
mutation LogMood($input: MoodLogInput!) {
  logMood(input: $input) {
    _id
    date
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
    date
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
    date
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
    date
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

// typing

const String submitTypingTestMutation = r'''
mutation SubmitTypingTest($referenceText: String!, $userText: String!, $durationSec: Float!) {
  submitTypingTest(referenceText: $referenceText, userText: $userText, durationSec: $durationSec) {
    id
    wpm
    cpm
    accuracy
    score
    mistakes { error correction type }
    suggestions
    encouragement
    createdAt
  }
}
''';

const String getTypingTestQuery = r'''
  query GetTypingTests {
    getTypingTests {
      wpm
      cpm
      accuracy
      score
      createdAt
    }
  }
''';

const String generateTypingTestTextQuery = r'''
  query GetTypingTestText {
    getTypingTestText
  }
''';

// speaking

const String submitSpeakingTestMutation = r'''
mutation SubmitSpeakingTest($uid: String!, $referenceText: String!, $audioBase64: String!) {
  submitSpeakingTest(uid: $uid, referenceText: $referenceText, audioBase64: $audioBase64) {
    id
    transcript
    scores {
      fluency
      pronunciation
      grammar
      vocabulary
      overall
    }
    encouragement
    mistakes {
      error
      correction
      type
    }
    suggestions
  }
}
''';

const String getSpeakingTestsQuery = r'''
query GetSpeakingTests($uid: String!) {
  getSpeakingTests() {
    id
    transcript
    createdAt
    scores {
      fluency
      pronunciation
      grammar
      vocabulary
      overall
    }
  }
}
''';
