import { Args, Query, Context, Resolver, Mutation } from '@nestjs/graphql';
import { TestService } from './test.service';
import { UseGuards } from '@nestjs/common';
import { TypingTest } from './models/typing-test.model';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';

interface GqlContext {
  req: { user: { uid: string } };
}

@Resolver(() => TypingTest)
@UseGuards(FirebaseAuthGuard)
export class TestResolver {
  constructor(private readonly testService: TestService) {}

  @Query(() => String)
  async getTypingTestText() {
    return this.testService.generateTypingText();
  }

  @Query(() => [TypingTest])
  async getTypingTests(@Context() context: GqlContext) {
    const userId = context.req.user.uid;
    return this.testService.getTypingTests(userId);
  }

  @Mutation(() => TypingTest)
  async submitTypingTest(
    @Args('referenceText') referenceText: string,
    @Args('userText') userText: string,
    @Args('durationSec') durationSec: number,
    @Context() context: GqlContext,
  ) {
    const userId = context.req.user.uid;
    return this.testService.submitTypingTest(
      userId,
      referenceText,
      userText,
      durationSec,
    );
  }
}
