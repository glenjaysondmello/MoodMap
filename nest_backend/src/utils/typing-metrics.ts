export const evaluateTypingTest = (
  referenceText: string,
  userText: string,
  durationSec: number,
) => {
  const durationMin = durationSec / 60;
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

  let correctChars = 0;
  let incorrectChars = 0;

  for (let i = 0; i < user.length; i++) {
    if (i < ref.length && user[i] === ref[i]) {
      correctChars++;
    } else {
      incorrectChars++;
    }
  }

  const wpm = correctChars / 5 / durationMin;
  const cpm = correctChars / durationMin;
  const accuracy = user.length > 0 ? (correctChars / user.length) * 100 : 100;

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
      mistakes.push({
        error: '(missing)',
        correction: refWord,
        type: 'omission',
      });
    } else if (refWord === undefined) {
      mistakes.push({
        error: userWord,
        correction: '(extra)',
        type: 'insertion',
      });
    } else {
      mistakes.push({ error: userWord, correction: refWord, type: 'spelling' });
    }
  }

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