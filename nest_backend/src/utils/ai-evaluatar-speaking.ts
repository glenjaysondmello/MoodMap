import Groq from 'groq-sdk';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

interface AiEvaluationResult {
  scores: {
    fluency: number;
    pronunciation: number;
    grammar: number;
    vocabulary: number;
    overall: number;
  };
  mistakes: {
    error: string;
    correction: string;
    type: string;
  }[];
  suggestions: string[];
  encouragement: string;
}

export const evaluateWithGroq = async (payload: {
  referenceText: string;
  transcript: string;
}): Promise<AiEvaluationResult> => {
  if (!payload.transcript) {
    return {
      scores: {
        fluency: 0,
        pronunciation: 0,
        grammar: 0,
        vocabulary: 0,
        overall: 0,
      },
      mistakes: [],
      suggestions: [
        'No transcript detected. Please retry the test with clear audio.',
      ],
      encouragement:
        'Don’t worry, try again! Clear speech will help the system transcribe better.',
    };
  }

  const response = await groq.chat.completions.create({
    model: 'gemma2-9b-it',
    messages: [
      {
        role: 'system',
        content:
          'You are a strict but fair English evaluation expert. Your task is to analyze a user\'s speech transcript by comparing it to a reference text. You MUST return a JSON object with the exact structure: { "scores": { "fluency": number, "pronunciation": number, "grammar": number, "vocabulary": number, "overall": number }, "mistakes": [{ "error": string, "correction": string, "type": string }], "suggestions": [string], "encouragement": string }. All scores must be integers from 0 to 100. The "mistakes" array should detail every deviation. The "type" can be "Pronunciation", "Grammar", "Omission", "Insertion", or "Word Choice". **Specifically, if a word from the reference text is missing in the transcript, create a mistake object where "type" is "Omission", "error" is the literal string "(missing)", and "correction" is the word that was missed.** If there are no mistakes, return an empty array. Provide actionable suggestions for improvement.',
      },
      {
        role: 'user',
        content: JSON.stringify(payload),
      },
    ],
    response_format: { type: 'json_object' },
  });

  const content = response.choices[0]?.message?.content;

  if (!content) {
    throw new Error('Failed to get a valid response from Groq API.');
  }

  let parsed: AiEvaluationResult;

  try {
    parsed = JSON.parse(content);
  } catch (error) {
    console.error('Invalid JSON from Groq:', content);
    throw new Error('Groq returned invalid JSON format.');
  }

  parsed.scores = Object.fromEntries(
    Object.entries(parsed.scores).map(([k, v]) => [
      k,
      Math.max(0, Math.min(100, Number(v) || 0)),
    ]),
  ) as AiEvaluationResult['scores'];

  return parsed;
};
