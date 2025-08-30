import { InferenceClient } from '@huggingface/inference';
import { Buffer } from 'buffer';

const hf = new InferenceClient(process.env.HF_API_KEY);

export const transcribeAudio = async (audioBase64: string): Promise<string> => {
  const audioBuffer = Buffer.from(audioBase64, 'base64');

  const response = await hf.automaticSpeechRecognition({
    model: 'openai/whisper-tiny',
    data: audioBuffer.buffer,
  });

  return response.text || '';
};
