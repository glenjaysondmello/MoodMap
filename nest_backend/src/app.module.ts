import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { join } from 'path';
import { AuthModule } from './auth/auth.module';
import { MoodModule } from './mood/mood.module';
import { SentimentModule } from './sentiment/sentiment.module';
import { PrismaModule } from './prisma/prisma.module';
import { TypingTestModule } from './typing_test/typing_test.module';
import { SpeakingTestModule } from './speaking_test/speaking_test.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true
    }),
    MongooseModule.forRoot(process.env.MONGO_URI || ''),
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      autoSchemaFile: join(process.cwd(), 'src/schema.gql'),
    }),
    AuthModule,
    MoodModule,
    SentimentModule,
    PrismaModule,
    TypingTestModule,
    SpeakingTestModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
