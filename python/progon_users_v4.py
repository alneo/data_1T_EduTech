import sys
import os
from datetime import datetime, timedelta, timezone
import psycopg2
import json

"""Скрипт прогона пользователя по дням и сохранения результата анализа 199900534"""


def postgresql_data_start_query(user_id):
    """Получение даты начала занятий"""
    logs = []
    data = None
    data1 = None
    try:
        connection = psycopg2.connect(host=host, port=port, database=database, user=user, password=password)
        cursor = connection.cursor()
        #sql = "select created_at from users_logs_v2 where user_id = "+str(user_id)+" ORDER BY created_at asc limit 1"
        #sql = "select TO_CHAR(created_at, 'YYYY-MM-DD') as created_at from activity_history_viewed_v4 where page_type = 'активность' and user_id="+str(user_id)+" order by created_at asc limit 1;"
        sql = "select distinct users.user_id, TO_CHAR(min(sh.date_shown), 'YYYY-MM-DD') as created_at from public.users_v4 users left join public.schedule_v4 sh using(course_id) where user_id ="+str(user_id)+" group by 1;"
        cursor.execute(sql)
        data = cursor.fetchone()
        cursor.close()
        connection.close()
    except Exception as e:
        logs.append(f"Ошибка: {e}")
    return data, logs


def postgresql_model_stat_check(model_info, user_id, day_num):
    """Проверка существования записи"""
    logs = []
    data = None
    try:
        connection = psycopg2.connect(host=host, port=port, database=database, user=user, password=password)
        cursor = connection.cursor()
        sql = "select id from model_stats where model_info=\'"+model_info+"_v4\' AND id_user="+str(user_id)+" AND day_num="+str(day_num)+" limit 1;"
        cursor.execute(sql)
        data = cursor.fetchone()
        cursor.close()
        connection.close()
    except Exception as e:
        logs.append(f"Ошибка: {e}")
    return data, logs


def postgresql_users_all_query():
    """Получение всех пользователей"""
    logs = []
    data = []
    try:
        connection = psycopg2.connect(host=host, port=port, database=database, user=user, password=password)
        cursor = connection.cursor()
        sql = "select user_id from users_v4 GROUP BY user_id ORDER by user_id ASC;"
        cursor.execute(sql)
        for row in cursor.fetchall():
            data.append(row[0])
        cursor.close()
        connection.close()
    except Exception as e:
        logs.append(f"Ошибка: {e}")
    return data


host = '95.64.227.126'
port = '21000'
database = 'edutechdb'
user = 'edutechuser'
password = '1edutech!password3'

model_info = 'project_1911'
# Получение значений week_number и user_id_to_predict из консоли
if len(sys.argv) < 2:
    print("Используй:________________________________________python3 progon_users_v4.py <model_info> <user_id>")
    print("Просчет пользователя по модели [project_1911(m2_progress), project_2411_clf(m2_success)] от начала обучения до конца 10 недели и сохранения результата")
    print("python3 progon_users_v4.py project_1911 19254 - модель project_1911 просчитать одного пользователя 19254")
    print("python3 progon_users_v4.py project_1911 0 - модель project_1911 просчитать всех пользователей")
    sys.exit(1)

model_info = sys.argv[1]
user_id = int(sys.argv[2])
kol_day = 70 # 10 недель по 7 дней

if user_id == 0:
    users = postgresql_users_all_query()
else:
    users = [user_id]

for user_id in users:
    # Получаем дату начала для пользователя
    data_start, logs = postgresql_data_start_query(user_id)
    if data_start != None:
        #Пройдем все дни для пользователя
        for i in range(1, 70):
            date_obj = datetime.strptime(data_start[1], '%Y-%m-%d')
            date_plus_1 = date_obj + timedelta(days=i)
            date_cur = date_plus_1.strftime('%Y-%m-%d')

            #Определим количество дней от начала курса до расчетной даты
            end_date = datetime.strptime(date_cur, '%Y-%m-%d')
            start_date = datetime.strptime(data_start[1], '%Y-%m-%d')
            day_num = (end_date - start_date).days

            #Проверим, есть ли ткаой расчет
            rez, logs = postgresql_model_stat_check(model_info, user_id, day_num)
            if rez == None:#Нет такой записи
                command = f"python3 route_v4.py {model_info} {user_id} {date_cur}"
                return_value = os.popen(command).read()
                result_dict = json.loads(return_value)
                result_value = result_dict.get("result")
                #print(f"Модель: {model_info} Пользователь: {user_id} День:{day_num} Значение: {result_value}")
        print(f"Модель: {model_info} Пользователь: {user_id}")
    else:
        print(f"Ошибка получения даты начала занятий: user_id={user_id} {logs}")