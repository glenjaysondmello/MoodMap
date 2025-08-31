import { Args, Context, Resolver, Query, Mutation } from '@nestjs/graphql';
import { SpeakingTestService } from './speaking_test.service';
import { SpeakingTest } from './models/speaking-test.model';
import { UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from 'src/auth/firebase-auth.guard';
import GraphQLUpload from 'graphql-upload/GraphQLUpload.mjs';
import { FileUpload } from 'graphql-upload/processRequest.mjs';

interface GqlContext {
  req: { user: { uid: string } };
}

@Resolver(() => SpeakingTest)
@UseGuards(FirebaseAuthGuard)
export class SpeakingTestResolver {
  constructor(private readonly speakingService: SpeakingTestService) {}

  @Query(() => String)
  async getSpeakingTestText() {
    return this.speakingService.generateSpeakingText();
  }

  @Query(() => [SpeakingTest])
  async getSpeakingTests(@Context() context: GqlContext) {
    const userId = context.req.user.uid;
    return this.speakingService.getSpeakingTests(userId);
  }

  @Mutation(() => SpeakingTest)
  async submitSpeakingTest(
    @Args('referenceText') referenceText: string,
    @Args({ name: 'audioFile', type: () => GraphQLUpload })
    audioFile: FileUpload,
    @Context() context: GqlContext,
  ) {
    const userId = context.req.user.uid;
    return this.speakingService.submitSpeakingTest(
      userId,
      referenceText,
      audioFile,
    );
  }
}
