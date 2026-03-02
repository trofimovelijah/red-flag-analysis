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
CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Создание отдельной схемы проекта для изоляции данных
CREATE SCHEMA IF NOT EXISTS red_flag;

-- Установка схемы по умолчанию для базы данных
ALTER DATABASE red_flag_analysis SET search_path TO red_flag, public;

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

-- Выдача прав на БД и схемы пользователю приложения
GRANT CONNECT ON DATABASE red_flag_analysis TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT USAGE, CREATE ON SCHEMA red_flag TO app_user;
GRANT ALL ON ALL TABLES IN SCHEMA red_flag TO app_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA red_flag TO app_user;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA red_flag TO app_user;

-- Установка прав по умолчанию для будущих объектов в схеме red_flag
ALTER DEFAULT PRIVILEGES IN SCHEMA red_flag GRANT ALL ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA red_flag GRANT ALL ON SEQUENCES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA red_flag GRANT ALL ON FUNCTIONS TO app_user;

-- Проверка
SELECT version();
SELECT extname FROM pg_extension;
SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'red_flag';

\echo '✅ БД red_flag_analysis успешно создана!'
\echo '✅ Схема red_flag создана и настроена для изоляции данных проекта'
\echo 'Следующий шаг: psql -U postgres -d red_flag_analysis -f scripts/02_init_schema.sql'
