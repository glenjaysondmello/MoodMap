-- CreateTable
CREATE TABLE "public"."SpeakingTest" (
    "id" TEXT NOT NULL,
    "uid" TEXT NOT NULL,
    "referenceText" TEXT NOT NULL,
    "transcript" TEXT NOT NULL,
    "scores" JSONB NOT NULL,
    "mistakes" JSONB NOT NULL,
    "suggestions" JSONB NOT NULL,
    "encouragement" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SpeakingTest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."TypingTest" (
    "id" TEXT NOT NULL,
    "uid" TEXT NOT NULL,
    "referenceText" TEXT NOT NULL,
    "userText" TEXT NOT NULL,
    "wpm" DOUBLE PRECISION NOT NULL,
    "cpm" DOUBLE PRECISION NOT NULL,
    "accuracy" DOUBLE PRECISION NOT NULL,
    "durationSec" INTEGER NOT NULL,
    "mistakes" JSONB NOT NULL,
    "score" DOUBLE PRECISION NOT NULL,
    "suggestions" JSONB NOT NULL,
    "encouragement" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TypingTest_pkey" PRIMARY KEY ("id")
);
