import { ObjectType, Field, ID } from '@nestjs/graphql';

@ObjectType()
export class Score {
  @Field() fluency: number;
  @Field() pronunciation: number;
  @Field() grammar: number;
  @Field() vocabulary: number;
  @Field() overall: number;
}

@ObjectType()
export class MistakeS {
  @Field() error: string;
  @Field() correction: string;
  @Field() type: string;
}

@ObjectType()
export class SpeakingTest {
  @Field(() => ID) id: string;
  @Field() uid: string;
  @Field() referenceText: string;
  @Field() transcript: string;
  @Field(() => Score) scores: Score;
  @Field(() => [MistakeS]) mistakes: MistakeS[];
  @Field(() => [String]) suggestions: string[];
  @Field() encouragement: string;
  @Field() createdAt: Date;
}
