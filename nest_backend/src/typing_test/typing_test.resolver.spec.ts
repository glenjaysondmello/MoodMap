import { Test, TestingModule } from '@nestjs/testing';
import { TypingTestResolver } from './typing_test.resolver';

describe('TypingTestResolver', () => {
  let resolver: TypingTestResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [TypingTestResolver],
    }).compile();

    resolver = module.get<TypingTestResolver>(TypingTestResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
