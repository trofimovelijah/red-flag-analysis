-- ============================================================
-- Скрипт 1: Создание базы данных и расширений
-- ============================================================
-- Этот скрипт запускается от суперпользователя (postgres)
-- Выполнить: psql -U postgres -f scripts/01_create_database.sql

-- Удалить старую БД если существует (осторожно!)
-- DROP DATABASE IF EXISTS red_flag_analysis;

-- Создание базы данных
CREATE DATABASE red_flag_analysis
  ENCODING 'UTF8'
  LC_COLLATE 'ru_RU.UTF-8'
  LC_CTYPE 'ru_RU.UTF-8'
  TEMPLATE template0;

-- Подключиться к новой БД
\c red_flag_analysis

-- Создание расширений
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgvector";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Создание пользователя приложения (опционально)
DO
$$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = 'app_user') THEN
    CREATE USER app_user WITH PASSWORD 'secure_password_here';
    ALTER USER app_user CREATEDB;
  END IF;
END
$$;

-- Выдача прав на БД пользователю приложения
GRANT CONNECT ON DATABASE red_flag_analysis TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;

-- Проверка
SELECT version();
SELECT extname FROM pg_extension;

\echo '✅ БД red_flag_analysis успешно создана!'
\echo 'Следующий шаг: psql -U postgres -d red_flag_analysis -f scripts/02_init_schema.sql'
