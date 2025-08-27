export const evaluateTypingTest = (
  referenceText: string,
  userText: string,
  durationSec: number,
) => {
  const refWords = referenceText.trim().split(/\s+/);
  const userWords = userText.trim().split(/\s+/);

  const totalChars = userText.length;
  const totalWords = userWords.length;
  const durationMin = durationSec / 60;

  const wpm = totalWords / durationMin;
  const cpm = totalChars / durationMin;

  const mistakes: any[] = [];
  let correctWords = 0;

  refWords.forEach((word, i) => {
    if (userWords[i]) {
      if (userWords[i] !== word) {
        mistakes.push({
          error: userWords[i],
          correction: word,
          type: 'spelling',
        });
      } else {
        correctWords++;
      }
    } else {
      mistakes.push({
        error: '(missing)',
        correction: word,
        type: 'omission',
      });
    }
  });

  const accuracy = (correctWords / refWords.length) * 100;

  const normalizedWpm = Math.min(wpm / 60, 1);
  const normalizedCpm = Math.min(cpm / 300, 1);
  const score =
    accuracy * 0.4 + normalizedWpm * 100 * 0.4 + normalizedCpm * 100 * 0.2;

  const suggestions: string[] = [];
  if (accuracy < 80) suggestions.push('Focus on accuracy before speed.');
  if (wpm < 30)
    suggestions.push('Practice to gradually increase typing speed.');
  if (mistakes.length > 3)
    suggestions.push('Work on reducing spelling mistakes.');
  if (accuracy >= 90 && wpm >= 40)
    suggestions.push('Great job! Keep practicing for consistency.');

  return {
    wpm,
    cpm,
    accuracy,
    mistakes,
    score,
    suggestions,
    encouragement: 'Keep practicing, you’re improving every time!',
  };
};
