import Groq from 'groq-sdk';
import { SpeakingTest } from '../speaking_test/models/speaking-test.model';

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
  const response = await groq.chat.completions.create({
    model: 'llama3-70b-8192',
    messages: [
      {
        role: 'system',
        content:
          'You are a strict but fair English evaluation expert. Your task is to analyze a user\'s speech transcript by comparing it to a reference text. You MUST return a JSON object with the exact structure: { "scores": { "fluency": number, "pronunciation": number, "grammar": number, "vocabulary": number, "overall": number }, "mistakes": [{ "error": string, "correction": string, "type": string }], "suggestions": [string], "encouragement": string }. All scores must be integers from 0 to 100. The "mistakes" array should detail every deviation. The "type" can be "Pronunciation", "Grammar", "Omission", "Insertion", or "Word Choice". If there are no mistakes, return an empty array. Provide actionable suggestions for improvement.',
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

  return JSON.parse(content);
};
