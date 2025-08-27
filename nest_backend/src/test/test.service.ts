import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { evaluateTypingTest } from 'src/utils/typing-metrics';

@Injectable()
export class TestService {
  constructor(private readonly prismaService: PrismaService) {}

  async submitTypingTest(
    uid: string,
    referenceText: string,
    userText: string,
    durationSec: number,
  ) {
    const result = evaluateTypingTest(referenceText, userText, durationSec);

    return this.prismaService.typingTest.create({
      data: {
        uid,
        referenceText,
        userText,
        durationSec,
        wpm: result.wpm,
        cpm: result.cpm,
        accuracy: result.accuracy,
        mistakes: result.mistakes,
        score: result.score,
        suggestions: result.suggestions,
        encouragement: result.encouragement,
      },
    });
  }

  async getTypingTests(uid: string) {
    return this.prismaService.typingTest.findMany({
      where: { uid },
      orderBy: { createdAt: 'desc' },
    });
  }
}
