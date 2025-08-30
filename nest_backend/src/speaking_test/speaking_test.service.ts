import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { evaluateWithGroq } from 'src/utils/ai-evaluatar-speaking';
import { transcribeAudio } from '../utils/whisper';

@Injectable()
export class SpeakingTestService {
  constructor(private readonly prismaService: PrismaService) {}

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
    const transcript = await transcribeAudio(audioBase64);

    const aiResult = await evaluateWithGroq({
      referenceText,
      transcript,
    });

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
