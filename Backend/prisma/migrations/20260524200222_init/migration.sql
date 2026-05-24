-- CreateTable
CREATE TABLE "Review" (
    "id" TEXT NOT NULL,
    "pr_url" TEXT NOT NULL,
    "pr_title" TEXT,
    "repo" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Review_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Flaw" (
    "id" TEXT NOT NULL,
    "review_id" TEXT NOT NULL,
    "file" TEXT NOT NULL,
    "line" INTEGER,
    "severity" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "suggestion" TEXT NOT NULL,

    CONSTRAINT "Flaw_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "Flaw" ADD CONSTRAINT "Flaw_review_id_fkey" FOREIGN KEY ("review_id") REFERENCES "Review"("id") ON DELETE CASCADE ON UPDATE CASCADE;
