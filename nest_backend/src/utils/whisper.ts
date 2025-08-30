import { pipeline, type AutomaticSpeechRecognitionOutput } from '@xenova/transformers';

/**
 * Convert Node.js Buffer to Float32Array
 */
function bufferToFloat32Array(buffer: Buffer): Float32Array {
  const float32 = new Float32Array(buffer.length / 2); // assuming 16-bit PCM
  for (let i = 0; i < float32.length; i++) {
    const int16 = buffer.readInt16LE(i * 2);
    float32[i] = int16 / 32768; // normalize to [-1, 1]
  }
  return float32;
}

/**
 * Transcribe base64 audio using Xenova Whisper
 */
export const transcribeAudio = async (audioBase64: string): Promise<string> => {
  try {
    // Remove data URI prefix if present
    const base64Data = audioBase64.replace(/^data:audio\/\w+;base64,/, '');
    const audioBuffer = Buffer.from(base64Data, 'base64');

    // Convert buffer to Float32Array
    const floatArray = bufferToFloat32Array(audioBuffer);

    // Load Whisper model
    const whisper = await pipeline('automatic-speech-recognition', 'Xenova/whisper-large');

    // Transcribe audio
    const transcription = (await whisper(floatArray)) as AutomaticSpeechRecognitionOutput;

    // Handle output (if array returned, take first element)
    if (Array.isArray(transcription)) {
      return transcription[0]?.text || '';
    }

    return transcription.text || '';
  } catch (err) {
    console.error('Xenova transcription failed:', err);
    throw new Error('Audio transcription failed. Please try again.');
  }
};
