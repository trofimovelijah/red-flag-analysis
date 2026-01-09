# red-flag-analysis
Инструмент (в виде чат-бота) определения "красных флажков", содержащихся в различных юридических документов, с которыми приходится иметь дело обычным пользователям в Сети.

Технический проект представлен в [GoogleDocs](https://docs.google.com/document/d/1s5n__p_HItBspoNvUpveP_-ZSwDBr2WYCdYvToondTg/edit?usp=sharing)

## Развёртывание решения
1. Перед запуском создайте следующую структуру каталогов:
    ```
    project-root/
    ├── docker-compose.yaml
    ├── data/
    │   ├── postgres/
    │   ├── redis/
    │   └── qdrant/
    ├── postgres/
    │   └── initdb.d/
    │       └── init.sql (опционально)
    ├── redis/
    │   └── redis.conf
    └── qdrant/
        └── qdrant_config.yaml
    ```
### Создание структуры одной командой

```bash
mkdir -p data/{postgres,redis,qdrant} postgres/initdb.d redis qdrant
```
### Создание файла окружения
Создайте файл `.env` в одной директории с `docker-compose.yaml`

```
cp .env.example .env
```
В результате в файле окружения должны присутствовать подобные переменные среды:
```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_postgres_password
POSTGRES_DB=база_данных

QDRANT_API_KEY=qdrant_key

REDIS_PASSWORD=your_redis_password
```

## Основные команды

### 1. Запуск всех сервисов

```bash
# Запуск в фоне (рекомендуется)
docker-compose up -d

# Запуск с выводом логов в консоль
docker-compose up
```

### 2. Остановка сервисов

```bash
# Остановить контейнеры (данные сохраняются)
docker-compose down

# Остановить и удалить volumes (УДАЛИТ ВСЕ ДАННЫЕ!)
docker-compose down -v

# Остановить только (без удаления)
docker-compose stop
```

### 3. Проверка статуса

```bash
# Статус всех контейнеров
docker-compose ps

# Логи всех сервисов
docker-compose logs -f

# Логи конкретного сервиса (например, Qdrant)
docker-compose logs -f qdrant

# Последние 100 строк логов
docker-compose logs --tail=100 qdrant
```

### 4. Перезапуск сервисов

```bash
# Перезапустить все
docker-compose restart

# Перезапустить конкретный сервис
docker-compose restart qdrant

# Пересобрать и запустить (если изменился образ)
docker-compose up -d --force-recreate
```

### 5. Входить в контейнер

```bash
# PostgreSQL
docker exec -it postgres_db psql -U postgres -d база_данных

# Redis
docker exec -it redis_db redis-cli

# Qdrant (bash)
docker exec -it qdrant_db bash
```

### 6. Просмотр ресурсов

```bash
# Использование памяти и CPU
docker stats

# Информация об образах
docker images
```

---

## Проверка работоспособности

### Qdrant - простая проверка

#### 1. Проверка health endpoint

```bash
curl http://localhost:6333/healthz
```

**Ожидаемый ответ:**
```json
{}
```

#### 2. Получение информации о сервере

```bash
curl http://localhost:6333/api/v1/telemetry \
  -H "api-key: qdrant_api_key_123"
```

#### 3. Проверка через Python

```python
from qdrant_client import QdrantClient

# Подключение
client = QdrantClient(
    url="http://localhost:6333",
    api_key="qdrant_api_key_123"
)

# Проверка подключения
try:
    info = client.get_collections()
    print("✅ Qdrant работает!")
    print(f"Коллекции: {info}")
except Exception as e:
    print(f"❌ Ошибка: {e}")
```

#### 4. Проверка через Node.js

```javascript
const { QdrantClient } = require("@qdrant/js-client-rest");

const client = new QdrantClient({
  url: "http://localhost:6333",
  apiKey: "qdrant_api_key_123",
});

async function checkQdrant() {
  try {
    const collections = await client.getCollections();
    console.log("✅ Qdrant работает!");
    console.log("Коллекции:", collections);
  } catch (error) {
    console.error("❌ Ошибка:", error);
  }
}

checkQdrant();
```

#### 5. Проверка все сервисов одним скриптом

Запустите скрипт

```bash
chmod +x check_services.sh
./check_services.sh
```