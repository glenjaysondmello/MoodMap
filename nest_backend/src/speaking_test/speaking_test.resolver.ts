import { Args, Context, Resolver, Query } from '@nestjs/graphql';
import { SpeakingTestService } from './speaking_test.service';
import { SpeakingTest } from './models/speaking-test.model';
import { UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from 'src/auth/firebase-auth.guard';

interface GqlContext {
  req: { user: { uid: string } };
}

@Resolver(() => SpeakingTest)
@UseGuards(FirebaseAuthGuard)
export class SpeakingTestResolver {
  constructor(private readonly speakingService: SpeakingTestService) {}

  @Query(() => [SpeakingTest])
  async getSpeakingTests(@Context() context: GqlContext) {
    const userId = context.req.user.uid;
    return this.speakingService.getSpeakingTests(userId);
  }

  async submitSpeakingTest(
    @Args('referenceText') referenceText: string,
    @Args('audioBase64') audioBase64: string,
    @Context() context: GqlContext,
  ) {
    const userId = context.req.user.uid;
    return this.speakingService.submitSpeakingTest(
      userId,
      referenceText,
      audioBase64,
    );
  }
}
