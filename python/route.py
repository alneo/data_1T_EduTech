import sys
import joblib
import pandas as pd
import numpy as np
import json
from datetime import datetime, timezone
import time
import psycopg2

"""
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
"""

host = '95.64.227.126'
port = '21000'
database = 'edutechdb'
user = 'edutechuser'
password = '1edutech!password3'

model_info = 'project_1611'

# Получение значений week_number и user_id_to_predict из консоли
if len(sys.argv) == 1:
    print("Используй:________________________________________python3 route.py <model_name> <user_id> <week_number|date_set>")
    print("Пример пользователь и текущее состояние:__________python3 route.py project_1611 19489")
    print("Пример пользователь и 3 неделя:___________________python3 route.py project_1611 19489 3")
    print("Пример пользователь и получить на указанную дату:_python3 route.py project_1611 19489 2023-12-14")
    sys.exit(1)

model_info = sys.argv[1]

PATH = '/home/shared_notebooks/zloy/'+model_info

week_number = 0
date_cur = ''
user_id_to_predict = int(sys.argv[2])
if sys.argv[3].isdigit():
    week_number = int(sys.argv[3])
elif len(sys.argv) == 4 and '-' in sys.argv[3]:
    date_cur = sys.argv[3]


def postgresql_insert_result(data):
    """Вставка данных в таблицу model_stats"""
    connection = psycopg2.connect(host=host, port=port, database=database, user=user, password=password)
    cursor = connection.cursor()
    insert_query = """INSERT INTO model_stats (data_create, metrika, model_info, id_user, value, day_num, time_sql, time_model) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)"""

    values = (
        data['data_create'],
        data['metrika'],
        data['model_info'],
        data['id_user'],
        data['value'],
        data['day_num'],
        data['time_sql'],
        data['time_model']
    )
    cursor.execute(insert_query, values)
    connection.commit()
    cursor.close()
    connection.close()

def postgresql_data_start_query(user_id):
    """Получение даты начала занятий TODO: надо определить для КУРСА начало занятий!!! но не для пользователя"""
    logs = []
    data = None
    try:
        connection = psycopg2.connect(host=host, port=port, database=database, user=user, password=password)
        cursor = connection.cursor()
        #sql = "select created_at from users_logs_v2 where user_id = "+str(user_id)+" ORDER BY created_at asc limit 1"
        sql = "select TO_CHAR(created_at, 'YYYY-MM-DD') as created_at from activity_history_viewed_v2 where page_type = 'активность' and user_id="+str(user_id)+" order by created_at asc limit 1;"
        cursor.execute(sql)
        data = cursor.fetchone()
        cursor.close()
        connection.close()
    except Exception as e:
        logs.append(f"Ошибка: {e}")
    return data, logs

def postgresql_dataset_query(sql):
    """Выполнение SQL скрипта и получение результата pandas DataFrame"""
    logs = []
    data = None
    try:
        connection = psycopg2.connect(host=host, port=port, database=database, user=user, password=password)
        cursor = connection.cursor()
        cursor.execute(sql)
        data0 = cursor.fetchone()
        cursor.close()
        connection.close()

        data1 = np.array([data0])
        data = pd.DataFrame(data1, columns=['user_id', 'course_id', 'required_activities_delay_1_week', 'required_activities_delay_2_week', 'required_activities_delay_3_week', 'required_activities_delay_4_week', 'required_activities_delay_5_week', 'required_activities_delay_6_week', 'required_activities_delay_7_week', 'required_activities_delay_8_week', 'required_activities_delay_9_week', 'required_activities_delay_10_week', 'success_required_done_1_week', 'success_required_done_2_week', 'success_required_done_3_week', 'success_required_done_4_week', 'success_required_done_5_week', 'success_required_done_6_week', 'success_required_done_7_week', 'success_required_done_8_week', 'success_required_done_9_week', 'success_required_done_10_week', 'mean_result_required_1_week', 'mean_result_required_2_week', 'mean_result_required_3_week', 'mean_result_required_4_week', 'mean_result_required_5_week', 'mean_result_required_6_week', 'mean_result_required_7_week', 'mean_result_required_8_week', 'mean_result_required_9_week', 'mean_result_required_10_week', 'cur_date_progress_1_week', 'cur_date_progress_2_week', 'cur_date_progress_3_week', 'cur_date_progress_4_week', 'cur_date_progress_5_week', 'cur_date_progress_6_week', 'cur_date_progress_7_week', 'cur_date_progress_8_week', 'cur_date_progress_9_week', 'cur_date_progress_10_week', 'current_progress_1_week', 'current_progress_2_week', 'current_progress_3_week', 'current_progress_4_week', 'current_progress_5_week', 'current_progress_6_week', 'current_progress_7_week', 'current_progress_8_week', 'current_progress_9_week', 'current_progress_10_week', 'end_status', 'm2_progress'])

    except Exception as e:
        logs.append(f"Ошибка: {e}")
    return data, logs

def get_sql_content_with_replacements(user_id, start_date):
    """Загружаем SQL запрос из файла и подставляем данные"""
    logs = []
    sql_content = ''
    try:
        with open('sql/sql_oneuser_data.sql', 'r') as file:
            sql_content = file.read()
        sql_content = sql_content.replace(':user_id', str(user_id))
        sql_content = sql_content.replace(':start_date', str(start_date))
    except FileNotFoundError:
        logs.append("Файл 'sql/sql_oneuser_data.sql' не найден.")
    except Exception as e:
        logs.append(f"Ошибка: {e}")
    return sql_content, logs

def dataset_load(week):
    """Загружаем данные из валидационного набора"""
    logs = []
    try:
        data = pd.read_csv(f'{PATH}/saved_datasets/val_week_{week}.csv')
        # print(f"Data for validation week {week} loaded successfully.")
        logs.append(f"Data for validation week {week} loaded successfully.")
        data_source = "validation"
    except FileNotFoundError:
        # Если данные для валидации отсутствуют, загружаем обучающий набор
        data = pd.read_csv(f'{PATH}/saved_datasets/train_week_{week}.csv')
        # print(f"Validation data not found. Using training data for week {week}.")
        logs.append(f"Validation data not found. Using training data for week {week}.")
        data_source = "training"
    return data, data_source, logs

def predict_for_user(week, user_id, date_cur):
    logs = []
    result = 0
    day_num = 0
    error = 0
    time_sql = 0
    time_model = 0
    try:
        # Получаем дату начала для пользователя
        data_start, logs = postgresql_data_start_query(user_id)
        #data_start[0] = 2023-12-14
        if date_cur == '':
            end_date = datetime.strptime(datetime.now().strftime('%Y-%m-%d'), '%Y-%m-%d')
        else:
            end_date = datetime.strptime(date_cur, '%Y-%m-%d')
        start_date = datetime.strptime(data_start[0], '%Y-%m-%d')
        day_num = (end_date - start_date).days

        if week == 0:
            start_date = datetime.strptime(data_start[0], '%Y-%m-%d')
            end_date = datetime.strptime(date_cur, '%Y-%m-%d')
            # Вычислим номер недели между start_date and end_date
            week = ((end_date - start_date).days // 7)+1
            logs.append(f"Number of weeks between {start_date.strftime('%Y-%m-%d')} and {end_date.strftime('%Y-%m-%d')}: {week}")

        # Загружаем модель для указанной недели
        joblib_name = 'rf_model'
        if model_info =='project_2411_clf':
            joblib_name = 'gb_model'
        model = joblib.load(f'{PATH}/saved_models/{joblib_name}_week_{week}.joblib')

        # Инициализируем переменную для хранения данных
        sql, logs = get_sql_content_with_replacements(user_id, "'"+data_start[0]+"'")
        if len(logs)==0:
            start_time = time.time()
            user_data, logs = postgresql_dataset_query(sql)
            end_time = time.time()
            time_sql = end_time - start_time
            #т.к. данные тестовые удалим будущие недели
            if(week<9):
                for i in range((week+1), 10):
                    user_data['required_activities_delay_'+str(i)+'_week'] = 0
                    user_data['success_required_done_'+str(i)+'_week'] = 0
                    user_data['mean_result_required_'+str(i)+'_week'] = 0
                    user_data['cur_date_progress_'+str(i)+'_week'] = 0
                    user_data['current_progress_'+str(i)+'_week'] = 0

        logs.append(f"Date start is: {data_start[0]}.")

        # Проверяем наличие пользователя в загруженной выборке
        if user_data.empty:
            error = 1
            logs.append(f"User_id {user_id} not found in the validation dataset for week {week}.")
        else:
            logs.append(f"User_id {user_id} found in the validation dataset for week {week}.")

        if error == 0:
            # Проверка наличия целевого признака
            if 'm2_progress' not in user_data.columns:
                logs.append("Column 'm2_progress' is missing from the dataset.")
                error = 1

            if error == 0:
                # Получаем реальное значение целевого признака
                actual_value = user_data['m2_progress'].values[0]
                logs.append(f"Actual value of m2_progress for user_id {user_id}: {actual_value:.2f}")

                start_time = time.time()
                # Подготовка данных для предсказания
                X_user = user_data.drop(['m2_progress'], axis=1)

                # Получаем список признаков из обучающей модели
                train_features = model.feature_names_in_

                # Проверяем наличие необходимых признаков
                missing_features = set(train_features) - set(X_user.columns)
                if missing_features:
                    logs.append(f"Week {week} is missing features: {missing_features}")
                    error = 1

                if error == 0:
                    # Заполняем отсутствующие признаки значениями по умолчанию
                    for feature in train_features:
                        if feature not in X_user.columns:
                            X_user[feature] = 0

                    # Убедитесь, что порядок признаков соответствует обучающим данным
                    X_user = X_user[train_features]

                    if model_info == 'project_2411_clf':
                        # Формируем предсказания модели (вероятности)
                        probabilities = model.predict_proba(X_user)
                        # Извлекаем вероятность принадлежности к классу 1 (успех)
                        result = probabilities[0][1]  # Вероятность успешного завершения курса]
                    else:
                        # Формируем предсказания модели
                        y_pred = model.predict(X_user)
                        # Выводим предсказанное значение только один раз
                        result = y_pred[0]

                    logs.append(f"Predicted value of m2_progress for user_id {user_id} in week {week}: {result:.2f}")

                end_time = time.time()
                time_model = end_time - start_time

    except FileNotFoundError as e:
        error = 1
        logs.append(f"File not found: {e}")
    except KeyError as e:
        error = 1
        logs.append(f"KeyError for week {week}: {e}")
    except ValueError as e:
        error = 1
        logs.append(f"ValueError for week {week}: {e}")
    except Exception as e:
        error = 1
        logs.append(f"An unexpected error occurred: {e}")

    return result, day_num, error, logs, time_sql, time_model

# Вызов функции для предсказания
prediction, day_num, error, logs, time_sql, time_model = predict_for_user(week_number, user_id_to_predict, date_cur)

if date_cur == '':
    dt = datetime.now(timezone.utc)
else:
    dt1 = datetime.strptime(date_cur, '%Y-%m-%d')
    dt = dt1.replace(hour=0, minute=0, second=0)

metrika = 'm2_progress'
if model_info == 'project_2411_clf':
    metrika = 'm2_success'

if error == 0:
    data = {
        'data_create': dt,
        'metrika': metrika,
        'model_info': model_info,
        'id_user': user_id_to_predict,
        'value': round(prediction,4),
        'day_num': day_num,
        'time_sql': round(time_sql, 6),
        'time_model': round(time_model, 6)
    }
    postgresql_insert_result(data)

result_json = {
    "error": error,
    "result": float(round(prediction,4)),
    "logs": logs,
    "time_sql": float(round(time_sql,6)),
    "time_model": float(round(time_model,6)),
    "day_num": int(day_num)
}
json_result = json.dumps(result_json, indent=4)
print(json_result)