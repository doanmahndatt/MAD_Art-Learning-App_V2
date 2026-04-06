-- CreateTable
CREATE TABLE "TutorialComment" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tutorial_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "content" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TutorialComment_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "TutorialComment" ADD CONSTRAINT "TutorialComment_tutorial_id_fkey" FOREIGN KEY ("tutorial_id") REFERENCES "Tutorial"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TutorialComment" ADD CONSTRAINT "TutorialComment_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
