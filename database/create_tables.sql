-- Database schema for: Ung dung ho tro hoc nghe thuat va sang tao
-- Target DBMS: PostgreSQL

-- Optional: enable UUID generation (PostgreSQL 13+)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1) USERS
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  role VARCHAR(20) NOT NULL DEFAULT 'user',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 2) TUTORIALS
CREATE TABLE IF NOT EXISTS tutorials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE,
  category VARCHAR(50) NOT NULL,
  description TEXT NOT NULL,
  thumbnail_url TEXT,
  difficulty_level VARCHAR(30),
  created_by UUID,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_tutorials_created_by
    FOREIGN KEY (created_by)
    REFERENCES users(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

-- 3) TUTORIAL_STEPS
CREATE TABLE IF NOT EXISTS tutorial_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tutorial_id UUID NOT NULL,
  step_order INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  image_url TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_tutorial_steps_order UNIQUE (tutorial_id, step_order),
  CONSTRAINT fk_tutorial_steps_tutorial
    FOREIGN KEY (tutorial_id)
    REFERENCES tutorials(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- 4) MATERIALS
CREATE TABLE IF NOT EXISTS materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tutorial_id UUID NOT NULL,
  name VARCHAR(255) NOT NULL,
  quantity VARCHAR(100),
  note TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_materials_tutorial
    FOREIGN KEY (tutorial_id)
    REFERENCES tutorials(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- 5) TUTORIAL_FAVORITES (N-N users <-> tutorials)
CREATE TABLE IF NOT EXISTS tutorial_favorites (
  user_id UUID NOT NULL,
  tutorial_id UUID NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, tutorial_id),
  CONSTRAINT fk_tutorial_favorites_user
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_tutorial_favorites_tutorial
    FOREIGN KEY (tutorial_id)
    REFERENCES tutorials(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- 6) TUTORIAL_REVIEWS
CREATE TABLE IF NOT EXISTS tutorial_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tutorial_id UUID NOT NULL,
  user_id UUID NOT NULL,
  rating INT NOT NULL,
  comment TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_tutorial_reviews_rating CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT uq_tutorial_reviews_user_tutorial UNIQUE (tutorial_id, user_id),
  CONSTRAINT fk_tutorial_reviews_tutorial
    FOREIGN KEY (tutorial_id)
    REFERENCES tutorials(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_tutorial_reviews_user
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- 7) ARTWORKS
CREATE TABLE IF NOT EXISTS artworks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  image_url TEXT NOT NULL,
  source_type VARCHAR(20) NOT NULL DEFAULT 'upload',
  is_public BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_artworks_user
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
);

-- 8) ARTWORK_LIKES (N-N users <-> artworks)
CREATE TABLE IF NOT EXISTS artwork_likes (
  user_id UUID NOT NULL,
  artwork_id UUID NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, artwork_id),
  CONSTRAINT fk_artwork_likes_user
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_artwork_likes_artwork
    FOREIGN KEY (artwork_id)
    REFERENCES artworks(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- 9) ARTWORK_COMMENTS
CREATE TABLE IF NOT EXISTS artwork_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  artwork_id UUID NOT NULL,
  user_id UUID NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_artwork_comments_artwork
    FOREIGN KEY (artwork_id)
    REFERENCES artworks(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_artwork_comments_user
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- 10) NOTIFICATIONS
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receiver_id UUID NOT NULL,
  actor_id UUID,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  entity_type VARCHAR(30),
  entity_id UUID,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_notifications_receiver
    FOREIGN KEY (receiver_id)
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_notifications_actor
    FOREIGN KEY (actor_id)
    REFERENCES users(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

-- =========================================================
-- Recommended indexes
-- =========================================================

-- tutorials
CREATE INDEX IF NOT EXISTS idx_tutorials_category ON tutorials(category);
CREATE INDEX IF NOT EXISTS idx_tutorials_title ON tutorials(title);

-- artworks
CREATE INDEX IF NOT EXISTS idx_artworks_user_created
  ON artworks(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_artworks_public_created
  ON artworks(is_public, created_at DESC);

-- artwork_comments
CREATE INDEX IF NOT EXISTS idx_artwork_comments_artwork_created
  ON artwork_comments(artwork_id, created_at ASC);

-- notifications
CREATE INDEX IF NOT EXISTS idx_notifications_receiver_read_created
  ON notifications(receiver_id, is_read, created_at DESC);

-- tutorial_steps/materials fast lookup by tutorial
CREATE INDEX IF NOT EXISTS idx_tutorial_steps_tutorial ON tutorial_steps(tutorial_id);
CREATE INDEX IF NOT EXISTS idx_materials_tutorial ON materials(tutorial_id);

-- tutorial_reviews and favorites
CREATE INDEX IF NOT EXISTS idx_tutorial_reviews_tutorial ON tutorial_reviews(tutorial_id);
CREATE INDEX IF NOT EXISTS idx_tutorial_favorites_tutorial ON tutorial_favorites(tutorial_id);

