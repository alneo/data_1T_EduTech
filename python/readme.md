# Принцип работы

## 1. Основной скрипт просчета данных пользователя

```route_v4.py <model_name> <user_id> <week_number|date_set>```

Примеры:

Пример пользователь и текущее состояние

```route_v4.py project_1911 19489``` 

Пример пользователь и 3 неделя

```route_v4.py project_1911 19489 3``` 

Пример пользователь и получить на указанную дату

```python3 route_v4.py project_1911 19489 2023-12-14``` 

Модели: 
* project_1611 - просчитывает m2_progress
* project_1911 - просчитывает m2_success
* project_2411_clf - просчитывает m2_success
* project_2911 - просчитывает m2_success

## 2. Вспомогательный скрипт - заполнение данными 

(нужен был для визуализации в ВЕБ)

```progon_users.py <user_id>``` - используется для запуска анализа одного пользователя и создания оценок на все дни от начала обучения до конца 10 недели

```progon_users_v4.py``` - настроен на новые данные и получает данные из таблиц с префиксом _v4 сохраняет в таблицу model_stats  с префиксом _v4

Примеры:

Просчет пользователя по модели от начала обучения до конца 10 недели и сохранения результата

```progon_users.py <model_info> <user_id>``` 

Модель project_1911 просчитать одного пользователя 19254

```progon_users.py project_1911 19254```

Модель project_1911 просчитать всех пользователей

```progon_users.py project_1911 0```

Результат заносится в таблицу:
```
CREATE TABLE model_stats (
    id SERIAL PRIMARY KEY,
    data_create TIMESTAMP,
    metrika VARCHAR(30),
    model_info VARCHAR(200),
    id_user INTEGER,
    value real,
    day_num INTEGER,
    time_sql real,
    time_model real
);
```


## 3. Работа скрипта Fastapi для проекта edutech

Основывается на uvicorn запущенном как сервис
```/etc/systemd/system/fastapi_project.service```

```
[Unit]
Description=FastAPI project
After=network.target

[Service]
User=root
WorkingDirectory=/home/yakovlev/app/python
#Environment="PATH=/home/yakovlev/app/python/env/bin"
ExecStart=/home/yakovlev/app/python/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 21004
Restart=always

[Install]
WantedBy=multi-user.target
```

Описание API доступно по адресу ```http://95.64.227.126:21004/docs```


## Скрипты для статистики обучения моделей

### Скрипт для сбора информации по обучению моделей

Запуск ``models_check.py`` без параметров

Конфиг в файле ``models_config.json`` указывается какие модели обрабатывать и по какому шаблону
Запись информации в таблицы ``ds_stats_m1`` и ``ds_stats_m2`` - для просмотра как происходит обучение. Отображает изменение MAE в процессе обучения

### Скрипт для сбора информации по тетрадкам Юпитера

Запуск ``grafana.py`` без параметров

```prometheus.py``` такой же скрипт для прометеус

Обход директории с юпитер-тетрадками пользователей и сбор информации
Если найден файл с расширением CSV подсчет количества строк и размер файла
Если найден файл с расширением IPYNB подсчет количества блоков с кодом
Все данные сохраняются в таблицу ds_stats
