#!/bin/bash

set -e

# Конфигурация
REPO_URL="https://github.com/Lissy93/dashy"
IMAGE_NAME="dashy-app"
TAR_FILE="${IMAGE_NAME}.tar"
DOCKERFILE="Dockerfile"
DOCKER_COMPOSE_FILE="docker-compose.yml"
PORT="8080"
BASE_IMAGE="alpine:3.17"

# Функция для ошибок
error_exit() {
    echo "Ошибка: $1" >&2
    exit 1
}

# 1. Проверка Docker
echo "Проверяем Docker..."
docker info >/dev/null 2>&1 || error_exit "Docker не запущен или нет прав"
echo "Docker работает"

# 2. Проверка репозитория
echo "Проверяем доступность репозитория..."
curl --silent --head --fail "$REPO_URL" >/dev/null 2>&1 || error_exit "Репозиторий недоступен"
echo "Репозиторий доступен"

# 3. Создаем Dockerfile
echo "Создаем Dockerfile..."
cat > "$DOCKERFILE" << EOF
FROM $BASE_IMAGE

RUN apk add --no-cache nodejs npm git && \\
    git clone $REPO_URL /app

WORKDIR /app

RUN npm install && npm run build

EXPOSE 4000

CMD ["npm", "start"]
EOF
echo "Dockerfile создан"

# 4. Собираем образ
echo "Собираем Docker образ..."
docker build -t "$IMAGE_NAME" . || error_exit "Ошибка сборки образа"
echo "Образ собран"

# 5. Сохраняем образ в файл
echo "Сохраняем образ в файл..."
docker save -o "$TAR_FILE" "$IMAGE_NAME" || error_exit "Ошибка сохранения образа"
echo "Образ сохранен в $TAR_FILE"

# 6. Очищаем Docker
echo "Очищаем Docker..."
docker system prune -af --volumes >/dev/null 2>&1 || true
echo "Docker очищен"

# 7. Загружаем образ из файла
echo "Загружаем образ из файла..."
docker load -i "$TAR_FILE" || error_exit "Ошибка загрузки образа"
echo "Образ загружен"

# 8. Создаем docker-compose.yml
echo "Создаем docker-compose.yml..."
cat > "$DOCKER_COMPOSE_FILE" << EOF
version: '3.8'
services:
  dashy:
    image: $IMAGE_NAME
    container_name: dashy-container
    ports:
      - "127.0.0.1:$PORT:4000"
    restart: unless-stopped
EOF
echo "docker-compose.yml создан"

# 9. Запускаем контейнер
echo "Запускаем контейнер..."
docker-compose up -d || error_exit "Ошибка запуска контейнера"
echo "Контейнер запущен"

# 10. Проверяем работу
echo "Проверяем работу приложения..."
sleep 10

if curl --silent --connect-timeout 5 "http://127.0.0.1:$PORT" >/dev/null; then
    echo "Приложение работает! Доступно по адресу: http://127.0.0.1:$PORT"
else
    error_exit "Приложение не отвечает"
fi

echo "Скрипт выполнен успешно!"