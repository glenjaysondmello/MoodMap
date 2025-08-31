import Groq from 'groq-sdk';
import * as fs from 'fs';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

export const transcribeAudio = async (filePath: string): Promise<string> => {
  try {
    const transcription = await groq.audio.transcriptions.create({
      file: fs.createReadStream(filePath),
      model: 'whisper-large-v3',
    });

    return transcription.text || '';
  } catch (error) {
    console.error('Groq transcription failed:', error);
    throw new Error('Audio transcription failed.');
  }
};
