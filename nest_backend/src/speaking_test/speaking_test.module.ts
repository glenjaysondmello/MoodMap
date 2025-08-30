import { Module } from '@nestjs/common';
import { SpeakingTestService } from './speaking_test.service';
import { SpeakingTestResolver } from './speaking_test.resolver';

@Module({
  providers: [SpeakingTestService, SpeakingTestResolver]
})
export class SpeakingTestModule {}
