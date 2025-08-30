import { ObjectType, Field, ID } from '@nestjs/graphql';

@ObjectType()
export class Mistake {
  @Field()
  error: string;

  @Field()
  correction: string;

  @Field()
  type: string;
}

@ObjectType()
export class TypingTest {
  @Field(() => ID)
  id: string;

  @Field()
  uid: string;

  @Field()
  referenceText: string;

  @Field()
  userText: string;

  @Field()
  durationSec: number;

  @Field()
  wpm: number;

  @Field()
  cpm: number;

  @Field()
  accuracy: number;

  @Field(() => [Mistake])
  mistakes: Mistake[];

  @Field()
  score: number;

  @Field(() => [String])
  suggestions: string[];

  @Field()
  encouragement: string;

  @Field()
  createdAt: Date;
}
