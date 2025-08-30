import { Test, TestingModule } from '@nestjs/testing';
import { TypingTestService } from './typing_test.service';

describe('TypingTestService', () => {
  let service: TypingTestService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [TypingTestService],
    }).compile();

    service = module.get<TypingTestService>(TypingTestService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
