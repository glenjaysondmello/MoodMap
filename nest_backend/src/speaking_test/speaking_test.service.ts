import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { evaluateWithGroq } from 'src/utils/ai-evaluatar-speaking';
import { transcribeAudio } from '../utils/whisper';
import Groq from 'groq-sdk';

@Injectable()
export class SpeakingTestService {
  private client: Groq;

  constructor(private readonly prismaService: PrismaService) {
    this.client = new Groq({
      apiKey: process.env.GROQ_API_KEY,
    });
  }

  async generateSpeakingText(): Promise<string> {
    try {
      const response = await this.client.chat.completions.create({
        model: 'llama3-8b-8192',
        messages: [
          {
            role: 'system',
            content:
              "You are a curator of interesting and accessible scientific knowledge. Your task is to generate a unique, fascinating scientific fact, presented as a cohesive paragraph. The paragraph must be approximately 150 words, making it suitable for a 60-second speaking assessment for an English professional. Use clear, intermediate-level vocabulary and varied sentence structures, ensuring the topic is easily understandable without requiring specialized knowledge. Present only the fact itself as a complete paragraph with correct punctuation. Do not include any introductory phrases like 'Here is a fascinating fact' or conversational filler.",
          },
          {
            role: 'user',
            content: 'Generate a new paragraph for a speaking test.',
          },
        ],
      });

      let content: string | undefined | null =
        response.choices[0]?.message.content;

      if (typeof content === 'string') {
        content = content.trim();
      } else {
        content = '';
      }

      return content;
    } catch (error) {
      console.error('Error fetching text from Groq API:', error);
      return 'The quick brown fox jumps over the lazy dog. This is a fallback text because the generator service is currently unavailable.';
    }
  }

  async getSpeakingTests(uid: string) {
    return this.prismaService.speakingTest.findMany({
      where: { uid },
      orderBy: { createdAt: 'desc' },
    });
  }

  async submitSpeakingTest(
    uid: string,
    referenceText: string,
    audioBase64: string,
  ) {
    let transcript = '';
    let aiResult: any;

    try {
      transcript = await transcribeAudio(audioBase64);
    } catch (err) {
      console.error('Transcription failed:', err);
      throw new Error('Audio transcription failed. Please try again.');
    }

    try {
      aiResult = await evaluateWithGroq({
        referenceText,
        transcript,
      });
    } catch (err) {
      console.error('Evaluation failed:', err);
      throw new Error('AI evaluation failed. Please try again.');
    }

    return this.prismaService.speakingTest.create({
      data: {
        uid,
        referenceText,
        transcript,
        scores: aiResult.scores,
        mistakes: aiResult.mistakes,
        suggestions: aiResult.suggestions,
        encouragement: aiResult.encouragement,
      },
    });
  }
}
