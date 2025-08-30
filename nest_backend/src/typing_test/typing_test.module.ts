import { Module } from '@nestjs/common';
import { TypingTestService } from './typing_test.service';
import { TypingTestResolver } from './typing_test.resolver';

@Module({
  providers: [TypingTestService, TypingTestResolver]
})
export class TypingTestModule {}
