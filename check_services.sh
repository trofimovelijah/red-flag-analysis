#!/bin/bash

echo "🔍 Проверка работоспособности сервисов..."
echo ""

# PostgreSQL
echo "1️⃣ PostgreSQL:"
if docker exec postgres_db pg_isready -U postgres > /dev/null 2>&1; then
    echo "   ✅ PostgreSQL работает (порт 5432)"
else
    echo "   ❌ PostgreSQL недоступен"
fi

# Redis
echo "2️⃣ Redis:"
if docker exec redis_db redis-cli ping > /dev/null 2>&1; then
    echo "   ✅ Redis работает (порт 6379)"
else
    echo "   ❌ Redis недоступен"
fi

# Qdrant
echo "3️⃣ Qdrant:"
if curl -s http://localhost:6333/healthz > /dev/null; then
    echo "   ✅ Qdrant работает (REST: 6333, gRPC: 6334)"
else
    echo "   ❌ Qdrant недоступен"
fi

echo ""
echo "📊 Статус контейнеров:"
docker-compose ps