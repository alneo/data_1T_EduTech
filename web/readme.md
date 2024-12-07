# Установка

Запуск docker `compose up -d`

Развернутся docker образы:

* web_nginx - ВЕБ сервер
* web_php - PHP препроцессор гипертекста
* web_mysql - База данных MySQL

## ВЕБ сервер

Необходим для реализации веб сервера и получения доступа к визуальным данным. Реализован с помощью nginx.

Основные настройки:

```
    ports:
      - 20002:80
      - 20003:443
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/ssl:/etc/nginx/ssl
      - ./nginx/log:/var/log/nginx
      - ./www_data:/usr/share/nginx/html
```

Хост настроен на домен `edutech.1t.ru` [конфиг](./nginx/conf.d/edutech.1t.ru.conf)

## PHP препроцессор гипертекста

Необходим для реализации бэкэнда проекта.

Образ собирается по [конфигурации](./php/Dockerfile):

```
FROM php:8.2-fpm
ENV TZ=Europe/Moscow
RUN apt update && apt-get install -y \
        libmcrypt-dev \
        && apt-get install -y libpq-dev \
        && docker-php-ext-install mysqli pdo pdo_mysql
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pgsql pdo_pgsql
```

## База данных MySQL

Необходима для реализации работы веб интерфейса, хранит конфигурацию административной части, пользователей с их правами в системе

```
    environment:
      MYSQL_DATABASE: edutech
      MYSQL_ROOT_PASSWORD: ${mysql_root_password}
      MYSQL_USER: edutech_user
      MYSQL_PASSWORD: ${mysql_user_password}
    ports:
      - '3306:3306'
    volumes:
      - ./mysql/db:/var/lib/mysql
```

Необходимо указать доступы, которые в дальнейшем использовать в конфигурационном файле `www_data/admin/config.php`
