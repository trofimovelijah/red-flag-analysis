# 🚩 Красные флажки

> **Telegram-бот**, который защитит вас от юридических ловушек в договорах, офертах и пользовательских соглашениях.

[![Документация](https://img.shields.io/badge/📖_Документация-online-blue)](https://trofimovelijah.github.io/red-flag-analysis/)
[![License](https://img.shields.io/github/license/trofimovelijah/red-flag-analysis)](LICENSE)

---

## 💡 О проекте

Вы когда-нибудь ставили галочку «Я согласен с условиями», не читая их? Большинство из нас так делает. Многие пункты действительно типовые и незначительные — но некоторые могут существенно ущемить ваши права или деньги.

**«Красные флажки»** — это ИИ-инструмент, который автоматически анализирует загруженный документ (договор, оферту, политику конфиденциальности) и подсвечивает потенциально опасные места, заслуживающие вашего внимания перед подписанием.

### Как это работает?

1. 📎 Пользователь отправляет документ в Telegram-бот
2. 🧹 Система очищает документ от лишних артефактов (колонтитулы, оглавление и т.д.)
3. 🔍 AI-агент сравнивает фрагменты документа с базой знаний «красных флажков», составленной юристами
4. 🚩 Бот возвращает список опасных мест с пояснениями

---

## 🛠️ Технологический стек

| Компонент | Технология | Назначение |
|-----------|-----------|------------|
| Фронтенд | Telegram Bot | Интерфейс для пользователей |
| Оркестратор | n8n | Связывание всех компонентов платформы |
| Реляционная БД | PostgreSQL 16 + pgvector | Хранение данных пользователей |
| Кэш и сессии | Redis 7.2 | Кэширование, управление сессиями |
| Векторная БД | Qdrant | Хранение эмбеддингов для RAG |
| Объектное хранилище | MinIO | Хранение загруженных документов |
| Анализ | LLM + RAG | Выявление «красных флажков» |

> Полная техническая документация с диаграммами архитектуры и описанием базы данных доступна на [сайте проекта](https://trofimovelijah.github.io/red-flag-analysis/).

---

## 🚀 Развёртывание

### 1. Клонирование репозитория

```bash
git clone git@github.com:trofimovelijah/red-flag-analysis.git
cd red-flag-analysis
```

### 2. Настройка окружения

```bash
cp configuration/.env.example configuration/.env
```

Отредактируйте `configuration/.env`, заполнив необходимые переменные:

```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_postgres_password
POSTGRES_DB=red_flag_analysis

QDRANT_API_KEY=qdrant_key
REDIS_PASSWORD=your_redis_password
MINIO_ROOT_PASSWORD=your_minio_password
```

### 3. Запуск сервисов

```bash
cd configuration
docker compose up -d
```

### 4. Инициализация базы данных

Вместо `{ipaddr}` укажите адрес сервера, где развёрнута СУБД:

```bash
psql -U postgres -h {ipaddr} -f scripts/postgresql/01_create_database.sql
psql -U postgres -h {ipaddr} -d red_flag_analysis -f scripts/postgresql/02_init_schema.sql
psql -U postgres -h {ipaddr} -d red_flag_analysis -f scripts/postgresql/03_seed_data.sql
```

### 5. Проверка развёртывания

```bash
chmod +x configuration/check_services.sh
./configuration/check_services.sh
```

---

## ⚙️ Управление сервисами

```bash
# Запуск / остановка
docker compose up -d          # Запустить в фоне
docker compose down           # Остановить (данные сохраняются)
docker compose down -v        # Остановить и удалить данные ⚠️
docker compose restart        # Перезапустить все сервисы

# Мониторинг
docker compose ps             # Статус контейнеров
docker compose logs -f        # Логи всех сервисов
docker stats                  # Использование ресурсов (CPU/RAM)

# Вход в контейнер
docker exec -it postgres_db psql -U postgres -d red_flag_analysis
docker exec -it redflag-redis redis-cli
docker exec -it qdrant_db bash
```

---

## 📚 Документация

Полный технический проект с описанием архитектуры, диаграммами C4, схемой базы данных и требованиями доступен на сайте:

**[trofimovelijah.github.io/red-flag-analysis](https://trofimovelijah.github.io/red-flag-analysis/)**
