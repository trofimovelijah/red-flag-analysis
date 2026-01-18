-- ============================================================
-- Скрипт 2: Создание схемы таблиц и индексов
-- ============================================================
-- Этот скрипт запускается в БД red_flag_analysis
-- Выполнить: psql -U postgres -d red_flag_analysis -f scripts/02_init_schema.sql

-- ==================== ТАБЛИЦЫ СПРАВОЧНИКОВ ====================

-- Тарифы
CREATE TABLE IF NOT EXISTS tariffs (
  tariff_id SERIAL PRIMARY KEY,
  tariff_name VARCHAR(50) NOT NULL UNIQUE,
  tariff_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
  daily_limit INT NOT NULL DEFAULT 3,
  allows_deep_analysis BOOLEAN DEFAULT FALSE,
  allows_export BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Типы документов
CREATE TABLE IF NOT EXISTS document_types (
  document_type_id SERIAL PRIMARY KEY,
  type_name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Форматы файлов
CREATE TABLE IF NOT EXISTS file_formats (
  file_format_id SERIAL PRIMARY KEY,
  format_name VARCHAR(20) NOT NULL UNIQUE,
  mime_type VARCHAR(100),
  max_file_size_mb INT DEFAULT 100,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Юрисдикции
CREATE TABLE IF NOT EXISTS jurisdictions (
  jurisdiction_id SERIAL PRIMARY KEY,
  jurisdiction_name VARCHAR(100) NOT NULL,
  jurisdiction_code VARCHAR(10) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Категории рисков
CREATE TABLE IF NOT EXISTS risk_categories (
  category_id SERIAL PRIMARY KEY,
  category_name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Определения рисков
CREATE TABLE IF NOT EXISTS risk_definitions (
  risk_id SERIAL PRIMARY KEY,
  risk_name VARCHAR(255) NOT NULL,
  description TEXT,
  severity_level VARCHAR(20) DEFAULT 'MEDIUM',
  risk_category_id INT NOT NULL REFERENCES risk_categories(category_id),
  jurisdiction_id INT REFERENCES jurisdictions(jurisdiction_id),
  remediation_advice TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(risk_name, jurisdiction_id)
);

-- Типы анализа
CREATE TABLE IF NOT EXISTS analysis_types (
  analysis_type_id SERIAL PRIMARY KEY,
  type_name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Типы платежей
CREATE TABLE IF NOT EXISTS payment_types (
  payment_type_id SERIAL PRIMARY KEY,
  type_name VARCHAR(50) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Типы обратной связи
CREATE TABLE IF NOT EXISTS feedback_types (
  feedback_type_id SERIAL PRIMARY KEY,
  type_name VARCHAR(50) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== ОСНОВНЫЕ ТАБЛИЦЫ ====================

-- Пользователи
CREATE TABLE IF NOT EXISTS users (
  user_id SERIAL PRIMARY KEY,
  telegram_id BIGINT UNIQUE NOT NULL,
  email VARCHAR(255),
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  tariff_id INT NOT NULL REFERENCES tariffs(tariff_id),
  subscription_start DATE,
  subscription_end DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

-- Сессии анализа документов
CREATE TABLE IF NOT EXISTS sessions (
  session_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  telegram_user_id BIGINT,
  file_name VARCHAR(255) NOT NULL,
  file_path VARCHAR(512),
  file_format_id INT REFERENCES file_formats(file_format_id),
  document_type_id INT REFERENCES document_types(document_type_id),
  jurisdiction_id INT REFERENCES jurisdictions(jurisdiction_id),
  language_code VARCHAR(10) DEFAULT 'RU',
  upload_status VARCHAR(20) DEFAULT 'PENDING',
  file_size_bytes INT,
  chunk_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  upload_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

-- Chunks (части документа)
CREATE TABLE IF NOT EXISTS chunks (
  chunk_id SERIAL PRIMARY KEY,
  session_id INT NOT NULL REFERENCES sessions(session_id),
  chunk_number INT NOT NULL,
  chunk_text TEXT NOT NULL,
  chunk_length INT,
  embedding VECTOR(1536),
  tsvector TSVECTOR,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

-- Результаты анализа
CREATE TABLE IF NOT EXISTS analysis_results (
  result_id SERIAL PRIMARY KEY,
  session_id INT NOT NULL REFERENCES sessions(session_id),
  risk_id INT NOT NULL REFERENCES risk_definitions(risk_id),
  analysis_type_id INT NOT NULL REFERENCES analysis_types(analysis_type_id),
  found_severity VARCHAR(20) NOT NULL,
  confidence_score INT DEFAULT 50,
  evidence_text TEXT,
  evidence_chunk_id INT REFERENCES chunks(chunk_id),
  recommendation TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Платежи
CREATE TABLE IF NOT EXISTS payments (
  payment_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(user_id),
  payment_type_id INT NOT NULL REFERENCES payment_types(payment_type_id),
  tariff_id INT REFERENCES tariffs(tariff_id),
  amount DECIMAL(10, 2) NOT NULL,
  payment_status VARCHAR(20) DEFAULT 'PENDING',
  transaction_id VARCHAR(255) UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP
);

-- Обратная связь
CREATE TABLE IF NOT EXISTS feedback (
  feedback_id SERIAL PRIMARY KEY,
  result_id INT NOT NULL REFERENCES analysis_results(result_id),
  user_id INT NOT NULL REFERENCES users(user_id),
  feedback_type_id INT NOT NULL REFERENCES feedback_types(feedback_type_id),
  comment TEXT,
  rating INT CHECK (rating >= 1 AND rating <= 5),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Логирование аудита
CREATE TABLE IF NOT EXISTS audit_logs (
  log_id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(user_id),
  action VARCHAR(100) NOT NULL,
  resource_type VARCHAR(100),
  resource_id VARCHAR(255),
  status VARCHAR(20) DEFAULT 'SUCCESS',
  error_message TEXT,
  old_value JSONB,
  new_value JSONB,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Метрики LLM
CREATE TABLE IF NOT EXISTS analysis_metrics (
  metric_id SERIAL PRIMARY KEY,
  session_id INT NOT NULL REFERENCES sessions(session_id),
  total_duration_ms INT,
  llm_tokens_used INT,
  confidence_avg DECIMAL(5, 2),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== ИНДЕКСЫ ====================

-- Индексы для производительности
CREATE INDEX IF NOT EXISTS idx_users_telegram_id ON users(telegram_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON sessions(upload_status);
CREATE INDEX IF NOT EXISTS idx_sessions_created ON sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_chunks_session_id ON chunks(session_id);
CREATE INDEX IF NOT EXISTS idx_analysis_results_session_id ON analysis_results(session_id);
CREATE INDEX IF NOT EXISTS idx_analysis_results_risk_id ON analysis_results(risk_id);
CREATE INDEX IF NOT EXISTS idx_feedback_result_id ON feedback(result_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp);

-- Полнотекстовый поиск
CREATE INDEX IF NOT EXISTS idx_chunks_tsvector ON chunks USING GIN(tsvector);

-- ==================== ПРЕДСТАВЛЕНИЯ (VIEWS) ====================

-- Сводка анализа
CREATE OR REPLACE VIEW analysis_summary AS
SELECT
  s.session_id,
  s.user_id,
  COUNT(DISTINCT ar.result_id) as risk_count,
  COUNT(DISTINCT CASE WHEN ar.found_severity = 'HIGH' THEN ar.result_id END) as high_risk_count,
  COUNT(DISTINCT CASE WHEN ar.found_severity = 'MEDIUM' THEN ar.result_id END) as medium_risk_count,
  COUNT(DISTINCT CASE WHEN ar.found_severity = 'LOW' THEN ar.result_id END) as low_risk_count,
  ROUND(AVG(ar.confidence_score)::NUMERIC, 2) as avg_confidence,
  EXTRACT(EPOCH FROM (s.updated_at - s.created_at))::INT * 1000 as processing_duration_ms,
  s.upload_timestamp
FROM sessions s
LEFT JOIN analysis_results ar ON s.session_id = ar.session_id
GROUP BY s.session_id, s.user_id;

-- Активность пользователей
CREATE OR REPLACE VIEW user_activity AS
SELECT
  u.user_id,
  COUNT(DISTINCT s.session_id) as total_sessions,
  COUNT(DISTINCT ar.result_id) as total_risks_found,
  COUNT(DISTINCT f.feedback_id) as feedback_provided,
  MAX(s.created_at) as last_analysis
FROM users u
LEFT JOIN sessions s ON u.user_id = s.user_id
LEFT JOIN analysis_results ar ON s.session_id = ar.session_id
LEFT JOIN feedback f ON ar.result_id = f.result_id
WHERE u.deleted_at IS NULL
GROUP BY u.user_id;

-- Статистика рисков
CREATE OR REPLACE VIEW risk_statistics AS
SELECT
  rd.risk_id,
  rd.risk_name,
  rc.category_name,
  COUNT(DISTINCT ar.result_id) as detection_count,
  COUNT(DISTINCT ar.session_id) as affected_documents,
  ROUND(AVG(ar.confidence_score)::NUMERIC, 2) as avg_confidence
FROM risk_definitions rd
LEFT JOIN risk_categories rc ON rd.risk_category_id = rc.category_id
LEFT JOIN analysis_results ar ON rd.risk_id = ar.risk_id
GROUP BY rd.risk_id, rd.risk_name, rc.category_name;

-- ==================== ТРИГГЕРЫ ====================

-- Автоматическое обновление updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_sessions_updated_at
BEFORE UPDATE ON sessions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_risk_definitions_updated_at
BEFORE UPDATE ON risk_definitions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ==================== ФУНКЦИИ ====================

-- Проверка rate limiting
CREATE OR REPLACE FUNCTION check_rate_limit(p_user_id INT)
RETURNS BOOLEAN AS $$
DECLARE
  v_today_count INT;
  v_daily_limit INT;
BEGIN
  SELECT COUNT(*) INTO v_today_count
  FROM sessions
  WHERE user_id = p_user_id
    AND DATE(upload_timestamp) = CURRENT_DATE
    AND upload_status = 'COMPLETED';

  SELECT daily_limit INTO v_daily_limit
  FROM users u
  JOIN tariffs t ON u.tariff_id = t.tariff_id
  WHERE u.user_id = p_user_id;

  RETURN v_today_count < v_daily_limit;
END;
$$ LANGUAGE plpgsql;

\echo '✅ Схема таблиц успешно создана!'
\echo 'Следующий шаг: psql -U postgres -d red_flag_analysis -f scripts/03_seed_data.sql'

