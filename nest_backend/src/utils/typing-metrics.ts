export const evaluateTypingTest = (
  referenceText: string,
  userText: string,
  durationSec: number,
) => {
  // --- 1. SETUP ---
  const durationMin = durationSec / 60;
  // Handle edge case of zero duration to prevent division by zero.
  if (durationMin === 0) {
    return {
      wpm: 0,
      cpm: 0,
      accuracy: 0,
      mistakes: [],
      score: 0,
      suggestions: [],
      encouragement: 'Start typing to begin!',
    };
  }

  const ref = referenceText.trim();
  const user = userText.trim();

  // --- 2. CHARACTER-LEVEL ANALYSIS for ACCURACY, NET WPM, and NET CPM ---
  let correctChars = 0;
  let incorrectChars = 0;

  // Compare the user's text against the reference character by character.
  for (let i = 0; i < user.length; i++) {
    if (i < ref.length && user[i] === ref[i]) {
      correctChars++;
    } else {
      incorrectChars++;
    }
  }

  // Calculate standard metrics based on correct characters.
  // Net WPM (the most common standard): (correct characters / 5) / time
  const wpm = correctChars / 5 / durationMin;
  // Net CPM: correct characters / time
  const cpm = correctChars / durationMin;
  // Accuracy: How many of the characters the user typed were correct.
  const accuracy = user.length > 0 ? (correctChars / user.length) * 100 : 100;

  // --- 3. WORD-LEVEL ANALYSIS for MISTAKE DETAILS ---
  const mistakes: any[] = [];
  const refWords = ref.split(/\s+/);
  const userWords = user.split(/\s+/);
  const maxWords = Math.max(refWords.length, userWords.length);
  let correctWords = 0;

  for (let i = 0; i < maxWords; i++) {
    const refWord = refWords[i];
    const userWord = userWords[i];

    if (userWord !== undefined && userWord === refWord) {
      correctWords++;
    } else if (userWord === undefined) {
      // User typed fewer words than reference (Omission)
      mistakes.push({
        error: '(missing)',
        correction: refWord,
        type: 'omission',
      });
    } else if (refWord === undefined) {
      // User typed more words than reference (Insertion)
      mistakes.push({
        error: userWord,
        correction: '(extra)',
        type: 'insertion',
      });
    } else {
      // Misspelled word
      mistakes.push({ error: userWord, correction: refWord, type: 'spelling' });
    }
  }

  // --- 4. SCORING & SUGGESTIONS ---
  // The original scoring formula is kept, but now uses the corrected metrics.
  // Normalize WPM and CPM against common benchmarks (e.g., 100 WPM, 500 CPM)
  const normalizedWpm = Math.min(wpm / 100, 1);
  const normalizedCpm = Math.min(cpm / 500, 1);
  const score =
    accuracy * 0.5 + normalizedWpm * 100 * 0.3 + normalizedCpm * 100 * 0.2;

  const suggestions: string[] = [];
  if (accuracy < 90)
    suggestions.push(
      'Focus on accuracy over speed. Slow down to avoid mistakes.',
    );
  if (wpm < 40)
    suggestions.push('Practice regularly to build muscle memory and speed.');
  if (mistakes.some((m) => m.type === 'spelling'))
    suggestions.push('Pay close attention to spelling as you type.');
  if (accuracy >= 95 && wpm >= 50)
    suggestions.push(
      'Excellent work! Challenge yourself with more complex texts.',
    );

  // --- 5. RETURN FINAL RESULTS ---
  return {
    wpm: parseFloat(wpm.toFixed(1)),
    cpm: parseFloat(cpm.toFixed(1)),
    accuracy: parseFloat(accuracy.toFixed(1)),
    mistakes,
    score: parseFloat(score.toFixed(1)),
    suggestions,
    encouragement: 'Practice makes progress. Keep up the great effort!',
  };
};
