import { Test, TestingModule } from '@nestjs/testing';
import { SpeakingTestService } from './speaking_test.service';

describe('SpeakingTestService', () => {
  let service: SpeakingTestService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [SpeakingTestService],
    }).compile();

    service = module.get<SpeakingTestService>(SpeakingTestService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
