import { Test, TestingModule } from '@nestjs/testing';
import { SpeakingTestResolver } from './speaking_test.resolver';

describe('SpeakingTestResolver', () => {
  let resolver: SpeakingTestResolver;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [SpeakingTestResolver],
    }).compile();

    resolver = module.get<SpeakingTestResolver>(SpeakingTestResolver);
  });

  it('should be defined', () => {
    expect(resolver).toBeDefined();
  });
});
