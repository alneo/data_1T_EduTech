#!/usr/bin/env python
# coding: utf-8

# In[1090]:


import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


# In[1091]:


users= pd.read_csv('E:/Учёба/DA/EduTech/Data_srt1/users.csv', delimiter=';') #импорт таблицы users (студенты), прописываем адрес хранения файла
users.head(5)


# In[1092]:


users.info() #запоминаем количество строк, чтобы в дальнейшем контролировать количество студентов


# In[1093]:


#приводим столбец "дата аттестации по курсу" к формату datetime
users['course_attestation_date'] = pd.to_datetime(users['course_attestation_date'])


# In[1094]:


users.head(2)


# In[1095]:


users.isna().sum()


# In[1096]:


# переименовываем колонки в соотвествии с названиями в нашей базе
users.rename(columns = {'userID': 'user_id', 'course_progress2': 'course_progress'}, inplace = True)


# In[1097]:


# берем только данные об итоговой аттестации, можно при необходимости добавить данные по отдельным модулям
users = users[['user_id', 'course_id', 'course_progress', 'course_attestation', 'course_attestation_date']].copy()


# In[1098]:


#для ускорения расчётов или при необходимости можно выбрать конкретного студента по user_id
#users = users.query('user_id == 5596') 
#users = users.reset_index(drop=True)
#users.head(2)


# In[1099]:


authorization= pd.read_csv('E:/Учёба/DA/EduTech/Data_srt1/authorization.csv')  # импорт талицы authorization (логи авторизаций), прописываем адрес хранения файла
authorization.head(5)


# In[1100]:


authorization.info()


# In[1101]:


authorization.drop(['user_agent', 'window_size'], axis=1, inplace=True)


# In[1102]:


#рассчитывем количество авторизаций для каждого студента
authorization2 = authorization.groupby(['user_id']).agg('count')
authorization2.rename(columns = {'created_at': 'num_of_auth'}, inplace = True)
authorization2.head(5)


# In[1103]:


us_auth = pd.merge(users, authorization, on='user_id', how='left') # объединяем таблицы users и authorization


# In[1104]:


us_auth.info()


# In[1105]:


us_auth.rename(columns = {'created_at': 'first_authirization'}, inplace = True)


# In[1106]:


us_auth.head(2)


# In[1107]:


us_auth.drop_duplicates(subset='user_id', keep='first', inplace=True) # оставляем дату первой авторизации в качестве даты регистрации


# In[1108]:


df_merged = pd.merge(us_auth, authorization2, on='user_id', how='left') # добавляем количество авторизаций


# In[1109]:


df_merged.head(2)


# In[1110]:


df_merged.info()  # сверяем количество строк с таблицей users


# In[1111]:


webinars_logs= pd.read_csv('E:/Учёба/DA/EduTech/Data_srt1/webinars_logs.csv') # импорт таблицы webinars_logs (логи вебинаров), прописываем адрес хранения файла
webinars_logs.head(5)


# In[1112]:


# удаляем ненужный столбец, переименовываем колонки в соотвествии с названиями в нашей базе
webinars_logs.drop(['module'], axis=1, inplace=True)
webinars_logs.rename(columns = {'dateTime': 'datetime', 'userId': 'user_id', 'eventName': 'event_name', 'webinarId': 'webinar_id', 'вводный вебинар': 'webinar_int'}, inplace = True)


# In[1113]:


webinars_logs['datetime'] = pd.to_datetime(webinars_logs['datetime']) # приводим к формату datetime


# In[1114]:


webinars_logs.head(5)


# In[1115]:


webinar_vvod = webinars_logs[['user_id','webinar_int']].copy() # копируем колонку с информацией о просмотрах вводного вебинара


# In[1116]:


webinar_vvod.drop_duplicates(subset='user_id', keep='first', inplace=True) # удаляем дубликаты
webinar_vvod.head(20)


# Расчёт продолжительности просмотра вебинаров

# In[1117]:


# выделяем подключения
connected = webinars_logs[webinars_logs['event_name'] == 'Подключение'].reset_index(drop=True) # выбираем время подключения
connected['date'] = connected['datetime'].apply(lambda x: x.date())
con = connected[['user_id', 'date', 'datetime', 'webinar_id']].copy()
con.sort_values(['user_id', 'webinar_id', 'datetime'], inplace=True)
con['session_id'] = con.groupby(['user_id', 'webinar_id']).cumcount()  

# выделяем отключения
disconnected = webinars_logs[webinars_logs['event_name'] == 'Отключение'].reset_index(drop=True) # выбираем время отключения
disconnected['date'] = disconnected['datetime'].apply(lambda x: x.date())
dis = disconnected[['user_id', 'date', 'datetime','webinar_id']].copy()
dis.sort_values(['user_id', 'webinar_id', 'datetime'], inplace=True)
dis['session_id'] = dis.groupby(['user_id', 'webinar_id']).cumcount()  

# объединяем подключения и отключения
webinar_viewing = pd.merge(con, dis, on=['user_id', 'webinar_id', 'date', 'session_id'], suffixes=('_connect', '_disconnect'))

# Удаляем временные промежуточные идентификаторы, если они больше не нужны
webinar_viewing.drop(columns=['session_id'], inplace=True)
webinar_viewing.head(15)


# суммарная длительность просмотров вебинаров по юзерам

# In[1118]:


# избегаем отрицательных значений в случае отсутствия логов
webinar_viewing['w_view_hours'] = np.where(
    webinar_viewing['datetime_disconnect'] > webinar_viewing['datetime_connect'],
    (webinar_viewing['datetime_disconnect'] - webinar_viewing['datetime_connect']).dt.total_seconds() / 3600,
    0  # или np.nan если вы хотите оставить пустым для значений, которые не соответствуют условию
)

webinar_viewing.head(10)


# In[1119]:


# считаем суммарное время просмотра вебинаров для одного студента
webinar_viewing_1 = webinar_viewing.groupby(['user_id'])[['w_view_hours']].agg('sum')
webinar_viewing_1.head(5)


# время просмотра отдельных вебинаров (далее не используется, но может пригодиться для анализа в будущем)

# In[1120]:


webinar_viewing['w_view_hours'] = (webinar_viewing['datetime_disconnect'] - webinar_viewing['datetime_connect']).dt.total_seconds() /3600 # вычисляем продолжиельность просмотра, переводим в часы
webinar_viewing_2 = webinar_viewing.groupby(['user_id', 'webinar_id'])[['w_view_hours']].agg('sum')
webinar_viewing_2.head(10)


# In[1121]:


# Присоединяем просмотры вводных вебинаров
webinar_viewing_sum = pd.merge(df_merged, webinar_vvod, on='user_id', how='left')
webinar_viewing_sum.head(2)


# In[1122]:


# Присоединяем продолжительность просмотра вебинаров
webinar_viewing_sum = pd.merge(webinar_viewing_sum, webinar_viewing_1, on='user_id', how='left')
webinar_viewing_sum.head(2)


# In[1123]:


webinar_viewing_sum.info() # проверяем, что количество строк не изменилось


# In[1124]:


activity_history_viewed = pd.read_csv('E:/Учёба/DA/EduTech/Data_srt1/activity_history_viewed.csv') # импорт таблицы activity_history_viewed (история просмотров), прописываем адрес хранения файла
activity_history_viewed.tail(2)


# In[1125]:


# копируем нужные столбцы с идентификатором пользователя, датой и временем просмотра, типом страницы
activity_sum = activity_history_viewed[['user_id', 'created_at','page_type']].copy()


# In[1126]:


# приводим тип данных в столбце "дата просмотра" к формату datetime
activity_sum['created_at'] = pd.to_datetime(activity_sum['created_at'])


# In[1127]:


# смотрим количество активностей в таблице
activity_sum['user_id'].count()


# In[1128]:


# считаем суммарное количество просмотров страниц с типом "занятие" для каждого пользователя
sum_task_id = activity_sum.loc[(activity_sum['page_type'] == 'занятие')]
sum_task_id = sum_task_id.groupby(['user_id', 'page_type']).agg('count')
sum_task_id.rename(columns = {'created_at': 'view_task_id'}, inplace = True)
sum_task_id.head(2)


# In[1129]:


# считаем суммарное количество просмотров страниц с типом "активность" для каждого пользователя
sum_activity_id = activity_sum.loc[(activity_sum['page_type'] == 'активность')]
sum_activity_id = sum_activity_id.groupby(['user_id', 'page_type']).agg('count')
sum_activity_id.rename(columns = {'created_at': 'view_activity_id'}, inplace = True)
sum_activity_id.head(2)


# In[1130]:


# объединяем предыдущие две таблицы
activity_sum = pd.merge(sum_task_id, sum_activity_id, on=['user_id'], how='left')
activity_sum.head(2)


# In[1131]:


#объединяем сводную таблицу с количеством просмотренных страниц
df_merged = pd.merge(webinar_viewing_sum, activity_sum, on=['user_id'], how='left')
df_merged.head(5)


# In[1132]:


# собран датасет с информацией для каждого студента о прогрессе по курсу, сдаче аттестации и дате аттестации, дате первой авторизации, количестве авторизаций
# просмотре вводного вебинара, количестве часов просмотра вебинаров, количестве просмотренных заданий и активностей
#делаем копию датасета, используем её для сборки сводного датасета в самом конце
for_overwiew = df_merged.copy()


# Обрабатываем результаты выполнения заданий и расписание

# In[1133]:


schedule = pd.read_csv('E:/Учёба/DA/EduTech/Data_srt1/schedule.csv')  # импорт таблицы schedule (расписание), прописываем адрес хранения файла


# In[1134]:


# переименовываем столбцы согласно нашим названиям столбцов в базе
schedule.rename(columns={'taskID': 'task_id', 'activivtyID':'activity_id', 'dateShown': 'date_shown', 'isAttestation': 'is_attestation'}, inplace=True)


# In[1135]:


# приводим формат данных в стобце "дата открытия задания" к datetime
schedule['date_shown'] = pd.to_datetime(schedule['date_shown'])


# In[1136]:


# удаляем пустые значения
schedule.dropna(inplace = True)


# In[1137]:


schedule.info()


# In[1138]:


exercise_results = pd.read_csv('E:/Учёба/DA/EduTech/Data_srt1/exercise_results.csv') # импорт таблицы exercise_results (результаты выполнения заданий), прописываем свой адрес хранения файла
exercise_results.head(2)


# In[1139]:


# переименовываем столбцы согласно нашим названиям столбцов в базе
exercise_results.rename(columns={'userId':'user_id', 'activityID':'activity_id', 'taskID': 'task_id', 'createdAt': 'created_at'}, inplace=True)


# In[1140]:


# приводим формат данных в стобце "дата выполнения задания" к datetime
exercise_results['created_at'] = pd.to_datetime(exercise_results['created_at'])


# In[1141]:


#объединяем данные о выполнении заданий с номерами пользователей и курсов
df_merged_er = pd.merge(users[['user_id', 'course_id']], exercise_results, on='user_id', how='left')
df_merged_er.head(5)


# In[1142]:


# присоединяем расписание
df_merged_sch = pd.merge(df_merged_er, schedule, on=['activity_id', 'course_id'], how='left')
df_merged_sch.head(5)


# In[1143]:


# проверяем, что количество студентов не изменилось
df_merged_sch['user_id'].value_counts()


# In[1146]:


df_merged_sch.drop(['module', 'type', 'visibility', 'flows', 'is_attestation'], axis=1, inplace=True)


# In[1147]:


df_merged_sch.head(2)


# In[1148]:


# импорт таблицы activities_guide (справочник активностей), прописываем свой адрес хранения файла
activities_guide = pd.read_csv('E:/Учёба/DA/EduTech/Data_srt1/activities_catalog.csv')
activities_guide.head(2)


# In[1149]:


# переименовываем названия столбцов в соотвествии с названиями в нашей базе данных
activities_guide.rename(columns={'courseId':'course_id', 'activityID':'activity_id', 'taskID': 'task_id', 'Признак Обязательного': 'obyaz_priznak', 'Признак Аттестации': 'is_attestation'}, inplace=True)


# In[1150]:


# проверяем на нулевые значения
activities_guide.isnull().sum()


# In[1151]:


# удаляем из справочника активностей строки с нулевыми значениями в колонке "обязательный признак"
activities_guide.dropna(axis=0, subset=['obyaz_priznak'], inplace=True)


# In[1152]:


# проверяем, какие уникальные значения есть с колонке с номером курса
unique_vals = activities_guide['courseID'].unique()
print(unique_vals)


# In[1153]:


# определяем количество обязательных заданий (в примере для курса 83 "Арзитектор данных")
# используем полученное значение для вычисления прогресса по формуле в самом конце
activities_guide.loc[(activities_guide['courseID'] == 83) &(activities_guide['is_attestation'] == 0), 'obyaz_priznak'].sum()


# In[1154]:


# объединяем нужные нам столбцы справочника активностей со сводным дата-сетом
df_merged = pd.merge(activities_guide[['activity_id', 'obyaz_priznak', 'is_attestation']], df_merged_sch, on=['activity_id'], how='left')
df_merged.head(5)


# In[1155]:


# определяем тип данных столбца result
print(df_merged['result'].dtypes, "\n")


# In[1156]:


# проверяем, какие уникальные значения есть с колонке "результат"
unique_vals = df_merged['result'].unique()
print(unique_vals)


# In[1157]:


# заменяем словесные статусы на числовые, отличные от остальных
df_merged['result'] = df_merged['result'].apply(lambda x: -1 if x == 'Пропуск' else x)
#df_merged['result'] = df_merged['result'].apply(lambda x: -1 if x == 'На проверке' else x)


# In[1158]:


# заполняем пропуски
df_merged = df_merged.fillna(0)


# In[1159]:


# меняем тип данных столбца, чтобы производить с ним подсчёты
df_merged['result'].astype(str).astype(int)
df_merged['result'] = pd.to_numeric(df_merged['result'])
print(df_merged['result'].dtypes, "\n")


# In[1160]:


df_merged.head(2)


# In[1161]:


# считаем средний результат и успех выполнения каждой активности
sum_result = df_merged.groupby(['user_id', 'activity_id'])[['result', 'success']].agg('mean')
sum_result.head(2)


# In[1162]:


# переименовываем колонки
sum_result.rename(columns = {'result': 'mean_result', 'success': 'mean_success'}, inplace = True)


# In[1163]:


# объединяем сводный датасет с данными о средних результатах
df_merged = pd.merge(df_merged, sum_result, on=['user_id', 'activity_id'], how='left')
df_merged.head(5)


# In[1164]:


# приводим тип данных колонки 'дата выполнения' к datetime
df_merged['created_at'] = pd.to_datetime(df_merged['created_at'], format="%Y-%m-%d %H:%M:%S.%f", errors='coerce' )


# In[1165]:


# приводим тип данных колонки 'дата открытия' к datetime
df_merged['date_shown'] = pd.to_datetime(df_merged['date_shown'], format="%Y-%m-%d %H:%M:%S.%f", errors='coerce' )


# In[1166]:


# считаем, сколько дней студенту потребовалось на выполнение активности
df_merged['delay_days'] = (df_merged['created_at'] - df_merged['date_shown']).dt.days
df_merged.head(5)


# In[1167]:


# для тех случаев, когда активность выполнена раньше, чем открыта (когда активность открыта в начале модуля, а не согласно расписанию)
df_merged.loc[df_merged['delay_days'] < 0, 'delay_days'] = 1

среднее количество дней выполнения неаттестационных активностей
# In[1168]:


shed_res_act_delta_days = df_merged[(df_merged.is_attestation == 0)&(df_merged.result != -1)]
delta_days_mean = shed_res_act_delta_days.groupby(['user_id'])[['delay_days']].agg('mean')
delta_days_mean.rename(columns = {'delay_days': 'delay_days_mean'}, inplace = True)
delta_days_mean.head(2)


# средний результат выполнения неаттестационных активностей

# In[1169]:


shed_res_act_result = df_merged[(df_merged.is_attestation == 0)&(df_merged.result != -1)]
result_mean = shed_res_act_result.groupby(['user_id'])[['result']].agg('mean')
result_mean.rename(columns = {'result': 'result_mean'}, inplace = True)
result_mean.head(2)


# средний успех выполнения неаттестационных активностей

# In[1170]:


shed_res_act_success = df_merged[(df_merged.is_attestation == 0)&(df_merged.result != -1)]
success_mean = shed_res_act_success.groupby(['user_id'])[['success']].agg('mean')
success_mean.rename(columns = {'success': 'success_mean'}, inplace = True)
success_mean.head(2)


# количество выполненных аттестационных активностей

# In[1171]:


attestation= df_merged[(df_merged.is_attestation == 1)&(df_merged.obyaz_priznak == 1)&(df_merged.success == 1)]
sum_attestation_id = attestation.groupby(['user_id'])[['success']].agg('count')
sum_attestation_id.rename(columns = {'success': 'attestation_task'}, inplace = True)
sum_attestation_id.head(2)


# количество выполненных обязательных активностей

# In[1172]:


shed_res_act_1 = df_merged[(df_merged.success == 1)&(df_merged.obyaz_priznak == 1)&(df_merged.is_attestation == 0)]
sum_result_1 = shed_res_act_1.groupby(['user_id'])[['success']].agg('count')
sum_result_1.head(2)


# количество выполненных необязательных активностей

# In[1173]:


shed_res_act_0 = df_merged[(df_merged.success == 1)&(df_merged.obyaz_priznak == 0)&(df_merged.is_attestation == 0)]
sum_result_0 = shed_res_act_0.groupby(['user_id'])[['success']].agg('count')
sum_result_0.head(2)


# создаем сводный обзорный датасет типа "один студент - одна строка"

# In[1174]:


# прибавляем количество выполненных обязательных и необязательных активностей
df_overwiew = pd.merge(for_overwiew, sum_result_1, on='user_id', how='left')
df_overwiew = pd.merge(df_overwiew, sum_result_0, on='user_id', how='left')
df_overwiew.head(2)


# In[1175]:


#переименовываем колонки в "обязательные" и "необязательные активности"
df_overwiew.rename(columns = {'success_x': 'required_task', 'success_y': 'optional_task'}, inplace = True)


# In[1176]:


# прибавляем количество выполненных аттестационных активностей
df_overwiew = pd.merge(df_overwiew, sum_attestation_id, on = 'user_id', how = 'left')


# In[1177]:


# прибавляем средний результат выполнения неаттестационных активностей
df_overwiew = pd.merge(df_overwiew , result_mean, on = 'user_id', how = 'left')


# In[1178]:


# прибавляем средний успех выполнения неаттестационных активностей
df_overwiew = pd.merge(df_overwiew, success_mean, on = 'user_id', how = 'left')


# In[1179]:


# прибавляем среднюю длительность выполнения неаттестационных активностей
df_overwiew = pd.merge(df_overwiew, delta_days_mean, on = 'user_id', how = 'left')


# In[1180]:


# заполняем пропуски
df_overwiew = df_overwiew.fillna(0)
df_overwiew.head(2)


# In[1181]:


# создаем обзорный датасет для любого курса (в примере курс "Аналитик данных")
df_overwiew_83 = df_overwiew.query('course_id == 83')


# In[1182]:


# рассчитываем прогресс по курсу на основе данных о количестве выполненных обязательных и необязательных активностей
# в знаменателе 24 это количество обязательных активностей по расписанию для курса "Аналитик данных" из строки 1088.
df_overwiew_83.eval('progress_calculated = (required_task + optional_task) / (24 + optional_task )*100', inplace=True)
df_overwiew_83.head(5)


# In[1183]:


# проверяем, сколько студентов на курсе 83
df_overwiew_83['user_id'].value_counts()


# Нами получен сводный датасет для 182 студентов курс 83 "Аналитик данных"

# In[1184]:


# пример вывода данных по одному студенту курса "Аналитик"
df_overwiew_83.query('user_id == 5596')


# In[1185]:


#Значения колонок
#user_id - идентификационный номер студента
#course_id - идентификационный номер курса
#course_progress	- прогресс по курсу, %
#course_attestation - аттестация (значение в % / не сдана)
#course_attestation_date - дата аттестации	
#first_authirization - дата первой авторизации
#num_of_auth	- общее количество авторизаций
#webinar_int - просмотр водного вебинара (да/нет)
#w_view_hours - общее количество часов просмотра вебинаров
#view_task_id - общее количество просмотренных заданий
#view_activity_id - общее количество просмотренных активностей
#required_task - общее количество выполненных обязательных неаттестационных активностей
#optional_task - общее количество выполненных необязательных неаттестационных активностей
#attestation_task - общее количество выполненных аттестационных активностей	
#result_mean	- средний результат выполнения обязательных неаттестационных активностей, %
#success_mean - средний успех выполнения обязательных неаттестационных активностей (отношение удачных попыток выполнения ко всем попыткам) от 0 до 1
#delay_days_mean	- среднее количество дней, потребовавшихся на выполнение неаттестационных активностей
#progress_calculated - рассчетный прогресс по курсу, %


# In[1186]:


# экспортируем сводный датасет для курса 83
#df_overwiew_83.to_csv('E:/Учёба/DA/EduTech/overwiew_83.csv')

