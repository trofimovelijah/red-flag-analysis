### Физическая модель реляционной базы данных

[![3НФ структуры базы данных](../images/ER.png)](../images/ER.png)

Основные таблицы:

- Users
- Sessions
- Analysis_Results
- Chunks
- Feedbacks
- Risks
- Risk_Categories
- Jurisdictions
- Document_Types
- Tariff
- Payments
- Payments_Types
- Rate_Limit_Log

### Словарь данных реляционной базы данных



Словарь содержит описание всех полей для следующих таблиц:

1. **Users (Пользователи)**
2. **Sessions (Сессии анализа)**
3. **Analysis_Results (Результаты анализа)**
4. **Chunks (Чанки)**
5. **Feedbacks (Обратная связь)**
6. **Risks (Риски)**
7. **Risk_Categories (Категории рисков)**
8. **Jurisdictions (Юрисдикции)**
9. **Document_Types (Типы документов)**
10. **Tariff (Тариф)**
11. **Payments (Платежи)**
12. **Payments_Types (Типы платежей)**
13. **Rate_Limit_Log (Отслеживание лимитов)**

### Исследование векторного хранилища

#### Сбор требований

- Хранение векторных представлений рисков
- Быстрый семантический поиск (< 1 сек)
- Поддержка метаданных
- Масштабируемость до 100k+ векторов

#### Проектирование схемы данных

**[ИЗОБРАЖЕНИЕ: Таблица схемы Vector_documents]**

Основные поля векторного хранилища:

- document_vector_id (UUID)
- chunk_id (INTEGER)
- session_id (INTEGER)
- user_id (INTEGER)
- embedding (DenseVector 768-1024)
- embedding_model (VARCHAR)
- chunk_text (TEXT)
- metadata (JSON)
- document_type (VARCHAR)
- jurisdiction (VARCHAR)
- created_at (TIMESTAMP)

#### Выбор стратегии индексирования

- **HNSW-индекс** для embedding (быстрый приблизительный поиск)
- **BTree-индекс** для chunk_id, session_id, user_id
- **Full-text-индекс** для chunk_text (полнотекстовый поиск)

#### Расчёт ёмкости и ресурсов

- Размер одного вектора (768 измерений, float32): ~3 КБ
- 100,000 векторов: ~300 МБ
- С учетом индексов и метаданных: ~1 ГБ
- Рекомендуемая RAM для Qdrant: 4 ГБ

