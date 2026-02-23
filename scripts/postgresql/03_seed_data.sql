-- ============================================================
-- Скрипт 3: Наполнение справочными данными
-- ============================================================
-- Этот скрипт запускается в БД red_flag_analysis
-- Выполнить: psql -U postgres -d red_flag_analysis -f scripts/03_seed_data.sql

-- ==================== СПРАВОЧНИКИ ====================

-- Тарифы
INSERT INTO tariffs (tariff_name, tariff_price, daily_limit, allows_deep_analysis, allows_export)
VALUES
  ('FREE', 0.00, 3, FALSE, FALSE),
  ('PRO', 299.00, 30, FALSE, TRUE),
  ('PRO+', 999.00, 999999, TRUE, TRUE)
ON CONFLICT (tariff_name) DO NOTHING;

-- Форматы файлов
INSERT INTO file_formats (format_name, mime_type, max_file_size_mb)
VALUES
  ('PDF', 'application/pdf', 100),
  ('DOCX', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 50),
  ('TXT', 'text/plain', 25),
  ('RTF', 'application/rtf', 50)
ON CONFLICT (format_name) DO NOTHING;

-- Типы документов
INSERT INTO document_types (type_name, description)
VALUES
  ('CONTRACT', 'Договор или соглашение'),
  ('NDA', 'Соглашение о неразглашении'),
  ('SERVICE_AGREEMENT', 'Соглашение об услугах'),
  ('EMPLOYMENT_CONTRACT', 'Трудовой договор'),
  ('INVOICE', 'Счёт-фактура')
ON CONFLICT (type_name) DO NOTHING;

-- Юрисдикции
INSERT INTO jurisdictions (jurisdiction_name, jurisdiction_code)
VALUES
  ('Российская Федерация', 'RF'),
  ('Казахстан', 'KZ'),
  ('Беларусь', 'BY'),
  ('США', 'US'),
  ('Европейский союз', 'EU')
ON CONFLICT (jurisdiction_code) DO NOTHING;

-- Категории рисков
INSERT INTO risk_categories (category_name, description)
VALUES
  ('Legal', 'Юридические риски'),
  ('Financial', 'Финансовые риски'),
  ('Technical', 'Технические риски'),
  ('Compliance', 'Риски соответствия требованиям'),
  ('Commercial', 'Коммерческие риски')
ON CONFLICT (category_name) DO NOTHING;

-- Типы анализа
INSERT INTO analysis_types (type_name, description)
VALUES
  ('STANDARD', 'Стандартный анализ'),
  ('DEEP', 'Глубокий анализ с дополнительными проверками')
ON CONFLICT (type_name) DO NOTHING;

-- Типы платежей
INSERT INTO payment_types (type_name)
VALUES
  ('SUBSCRIPTION'),
  ('ONE_TIME'),
  ('REFUND')
ON CONFLICT (type_name) DO NOTHING;

-- Типы обратной связи
INSERT INTO feedback_types (type_name)
VALUES
  ('HELPFUL'),
  ('NOT_HELPFUL'),
  ('PARTIALLY_HELPFUL')
ON CONFLICT (type_name) DO NOTHING;

-- ==================== ОПРЕДЕЛЕНИЯ РИСКОВ ====================

-- Риски для РФ (Legal)
INSERT INTO risk_definitions (risk_name, description, severity_level, risk_category_id, jurisdiction_id, remediation_advice)
SELECT
  'Подсудность вне РФ' as risk_name,
  'Договор предусматривает рассмотрение споров в иностранных судах' as description,
  'HIGH' as severity_level,
  rc.category_id,
  j.jurisdiction_id,
  'Изменить юрисдикцию на суды РФ или медиацию' as remediation_advice
FROM risk_categories rc, jurisdictions j
WHERE rc.category_name = 'Legal' AND j.jurisdiction_code = 'RF'
ON CONFLICT (risk_name, jurisdiction_id) DO NOTHING;

INSERT INTO risk_definitions (risk_name, description, severity_level, risk_category_id, jurisdiction_id, remediation_advice)
SELECT
  'Отсутствие неустойки' as risk_name,
  'В договоре не предусмотрена ответственность за нарушение условий' as description,
  'HIGH' as severity_level,
  rc.category_id,
  j.jurisdiction_id,
  'Добавить четкий размер неустойки в % от суммы контракта' as remediation_advice
FROM risk_categories rc, jurisdictions j
WHERE rc.category_name = 'Financial' AND j.jurisdiction_code = 'RF'
ON CONFLICT (risk_name, jurisdiction_id) DO NOTHING;

INSERT INTO risk_definitions (risk_name, description, severity_level, risk_category_id, jurisdiction_id, remediation_advice)
SELECT
  'Отсутствие срока действия' as risk_name,
  'Договор не содержит дату истечения или условий прекращения' as description,
  'MEDIUM' as severity_level,
  rc.category_id,
  j.jurisdiction_id,
  'Добавить четкие сроки действия и условия расторжения' as remediation_advice
FROM risk_categories rc, jurisdictions j
WHERE rc.category_name = 'Legal' AND j.jurisdiction_code = 'RF'
ON CONFLICT (risk_name, jurisdiction_id) DO NOTHING;

INSERT INTO risk_definitions (risk_name, description, severity_level, risk_category_id, jurisdiction_id, remediation_advice)
SELECT
  'Нечеткие сроки оплаты' as risk_name,
  'Условия и сроки платежа сформулированы неточно' as description,
  'MEDIUM' as severity_level,
  rc.category_id,
  j.jurisdiction_id,
  'Указать точную дату платежа или условия (например, "в течение 10 дней")' as remediation_advice
FROM risk_categories rc, jurisdictions j
WHERE rc.category_name = 'Financial' AND j.jurisdiction_code = 'RF'
ON CONFLICT (risk_name, jurisdiction_id) DO NOTHING;

INSERT INTO risk_definitions (risk_name, description, severity_level, risk_category_id, jurisdiction_id, remediation_advice)
SELECT
  'Отсутствие форс-мажорных оговорок' as risk_name,
  'Договор не содержит положений о форс-мажоре' as description,
  'LOW' as severity_level,
  rc.category_id,
  j.jurisdiction_id,
  'Добавить раздел о форс-мажорных обстоятельствах' as remediation_advice
FROM risk_categories rc, jurisdictions j
WHERE rc.category_name = 'Legal' AND j.jurisdiction_code = 'RF'
ON CONFLICT (risk_name, jurisdiction_id) DO NOTHING;

-- Риски для USA (Legal)
INSERT INTO risk_definitions (risk_name, description, severity_level, risk_category_id, jurisdiction_id, remediation_advice)
SELECT
  'Отсутствие инициалов' as risk_name,
  'В договоре отсутствуют инициалы сторон на измененных местах' as description,
  'MEDIUM' as severity_level,
  rc.category_id,
  j.jurisdiction_id,
  'Добавить инициалы сторон в соответствии с законодательством США' as remediation_advice
FROM risk_categories rc, jurisdictions j
WHERE rc.category_name = 'Legal' AND j.jurisdiction_code = 'US'
ON CONFLICT (risk_name, jurisdiction_id) DO NOTHING;

-- ==================== ПРОВЕРКА ====================

\echo '✅ Справочные данные успешно загружены!'

-- Проверка количества записей
SELECT '--- СТАТИСТИКА ЗАГРУЖЕННЫХ ДАННЫХ ---' as info;
SELECT (SELECT COUNT(*) FROM tariffs) as tарифы;
SELECT (SELECT COUNT(*) FROM risk_definitions) as определения_рисков;
SELECT (SELECT COUNT(*) FROM document_types) as типы_документов;
SELECT (SELECT COUNT(*) FROM jurisdictions) as юрисдикции;
SELECT (SELECT COUNT(*) FROM risk_categories) as категории_рисков;

\echo '✅ БД полностью готова к использованию!'
\echo 'Следующий шаг: Проверка установки (см. README.md)'

