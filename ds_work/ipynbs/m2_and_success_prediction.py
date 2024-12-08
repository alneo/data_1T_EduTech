#!/usr/bin/env python
# coding: utf-8

# # Обучение моделей прогнозирования показателей результативности обучения на курсах

# ### Задача
# Построить модели машинного обучения, предсказывающие результативность завершения учебных курсов пользователями образовательной платформы. Сериализовать модели для дальнейшей интеграции в веб-приложение.
# 
# ### Исходные данные:
# 1. 20241125_all_course.csv - сводный датасет по итогам подготовки на "детских" 3, 49, 71 и 77 курсах.
# 2. 20241128_new_data.csv - сводный датасет по итогам подготовки на курсах 1Т Дата - 76, 77, 82 и 83 курсы.

# ## Ход решения задачи

# ## 1. Загрузка и предобработка данных

# In[1]:


# Импорт библиотек для работы с данными
import pandas as pd
import numpy as np

# Импорт метрики MAE
from sklearn.metrics import mean_absolute_error

# Импорт инструментов визуализации
import matplotlib.pyplot as plt
import seaborn as sns
# from phik.report import plot_correlation_matrix


# #### 1.1 Загрузка данных

# #### Описание датасета 20241125_all_course
# 
# Датасет представляет собой выборку по итогам прохождения "детских" курсов и предназначен для обучения модели искусственного интеллекта в рамках разработки системы скоринга обучающихся, позволяющей прогнозировать уровень вовлеченности и вероятность успешного завершения курса каждым учеником. Кроме того, датасет подходит для предсказания статуса ("активный", "засыпающий", "спящий").
# Датасет содержит 55 столбцов и 4991 строк.
# Датасет содержит информацию о 4990 уникальных пользователях. Для каждого пользователя подсчитаны показатели и данные на 10 недель, начиная с 2023-12-01 (начало обучения на курсе) с интервалом в 1 неделю. В датасете содержится изменение значений метрик в течение всего периода обучения.
# 
# **Информация по столбцам:**
# * user_id - уникальный идентификатор пользователя
# * course_id	- идентификатор курса обучения
# 
# **Признаки для обучения модели имеют структуру данных, агрегированных за 10 недель обучения, в формате 'feature_{i}_week', где в каждом столбце - показатели за конкретную неделю обучения:**
# * required_activities_delay_1_week, ... , required_activities_delay_10_week - задержка в днях в выполнении заданий, накопленная за 1 - 10 недели
# * success_required_done_1_week, ... , success_required_done_10_week - количество сделанных обязательных заданий за 1 - 10 недели
# * mean_result_required_1_week, ... , mean_result_required_10_week - средняя оценка за выполненные обязательные задания за 1 - 10 недели
# * cur_date_progress_1_week, ... , cur_date_progress_1_week - прогресс в выполнении обязательных заданий за 1 - 10 недели
# * current_progress_1_week, ... , current_progress_10_week - накопленный общий прогресс по всему курсу обучения за 1 - 10 недели
# 
# **Целевые признаки:**
# * end_status - ("активный", "засыпающий", "спящий") на конец обучения
# * m2_progress - фактический накопленный общий прогресс по курсу
# * m2_success - успешность окончания курса (0 – не окончил, 1 – окончил успешно).

# In[2]:


# Загружаем датасет с "детскими" курсами
df_old = pd.read_csv('./original_dataset/20241125_all_course.csv')
df_old.head(5)


# Структура датасета по итогам прохождения курсов 1Т Дата  совпадает с "детскими" курсами. Но при этом имеются различия в названии столбцов:
# * столбец 'm2_progress' переименован на 'real_course_progress'
# * столбец 'm2_success' переименован на 'course_success'.

# In[3]:


# Загружаем датасет с курсами 1Т Дата
df_new = pd.read_csv('./original_dataset/20241128_new_data.csv')

# Переименовываем столбцы датафрейма df_new
df_new.rename(columns={
    'real_course_progress': 'm2_progress',
    'course_success': 'm2_success'
}, inplace=True)

# Заменяем значения в столбце course_id
df_new['course_id'] = df_new['course_id'].replace(77, 770)
df_new.head(5)


# * В обоих датасетах имеется признак 'end_status', который не будет применяться в данной работе. Поэтому мы его удаляем.

# In[4]:


# Объединяем два датафрейма в один
df = pd.concat([df_old, df_new], axis = 0, ignore_index=True)
# Удаляем столбец 'end_status'
df.drop(['end_status'], axis=1, inplace=True)
df.sample(5)


# В объединенном датасете наблюдается значительный дисбаланс обучающихся из разных курсов. Чтобы минимизировать негативное влияние этого дисбаланса на обучение моделей, создадим обучающую стратифицированную выборку.

# In[5]:


# Создаем обучающую стратифицированную выборку

# Шаг 1: Выбор записей из различных курсов с заданным количеством
# Определяем количество записей для каждого курса
sample_sizes = {
    77: 350,
    3: 1000,
    71: 1000,
    49: 1500,
    82: 180,
    770: 100,
    76: 50,
    83: 150
}

# Создаем пустой список для хранения выборок
samples = []

# Выбираем записи для каждого курса
for course_id, size in sample_sizes.items():
    # Выборка с заменой для курсов, где размер меньше необходимого
    course_sample = df[df['course_id'] == course_id].sample(n=size, replace=True)
    
    # Масштабируем до 1500 записей
    if len(course_sample) < 1500:
        course_expanded = course_sample.sample(n=1500, replace=True)
    else:
        course_expanded = course_sample.sample(n=1500)
    
    samples.append(course_expanded)

# Объединение всех выборок в одну обучающую выборку
train_sample = pd.concat(samples)

# Проверка результата
print("\nРазмер итоговой выборки:", len(train_sample))
for course_id in sample_sizes.keys():
    print(f"\nКоличество записей из course_id={course_id}:", len(train_sample[train_sample['course_id'] == course_id]))


# In[6]:


# Создаем валидационную выборку методом исключения из датасета обучающих примеров
val_sample = df.drop(train_sample.index)

# Проверка результатов
print("Размер обучающей стратифицированной выборки:")
print(len(train_sample))
print("\nРазмер валидационной выборки:")
print(len(val_sample))


# #### 1.2. Предварительный анализ данных

# In[7]:


# Проверяем на пропуски
val_sample.isna().sum()


# **Выводы:**
# * в датасете нет пропусков, он хорошо подходит для обучения моделей;
# * целесообразно обучить модели, прогнозирующие как успешность завершения курса 'm2_success', так и прогресс, которого достигнет обучающийся 'm2_progress'.

# #### 1.3. Создание отдельных датасетов для каждой недели

# * Формируем обучающие и валидационные выборки на каждую неделю. Особенности: датасет за 10 неделю содержат все данные исходной выборки, в датасете за 9 неделю заполняем нулями данные за 10 неделю, в датасете за 8 неделю - данные за 9 и 10 недели и т.д.
# 
# *Это позволяет с одной стороны сохранить структуру датасета, с другой - избежать "подглядывания" моделей в будущее*.

# In[8]:


# Функция формирования еженедельных датасетов
def create_weekly_dataframes_with_zeros_and_globals(base_df, total_weeks=10, prefix='train'):
    """
    Args:
        base_df (pd.DataFrame): Исходный датафрейм.
        total_weeks (int): Общее количество недель.
        prefix (str): Префикс для именования глобальных переменных (например, 'train' или 'val').
    Returns:
        None: Датафреймы сохраняются как глобальные переменные.
    """
    global_vars = globals()  # Доступ к глобальным переменным

    for current_week in range(1, total_weeks + 1):
        # Копируем исходный датафрейм
        weekly_df = base_df.copy()

        # Обнуляем данные будущих недель
        for future_week in range(current_week + 1, total_weeks + 1):
            for col in weekly_df.columns:
                if f'_{future_week}_week' in col:
                    weekly_df[col] = 0

        # Сохраняем датафрейм как глобальную переменную
        global_vars[f'{prefix}_week_{current_week}'] = weekly_df

# Применение функции для тренировочных и валидационных данных
create_weekly_dataframes_with_zeros_and_globals(train_sample, total_weeks=10, prefix='train')
create_weekly_dataframes_with_zeros_and_globals(val_sample, total_weeks=10, prefix='val')


# * Сохраняем полученные датасеты в отдельные файлы csv (при необходимости)

# In[9]:


# import os

# # Папка для сохранения файлов (убедитесь, что директория существует)
# save_directory = './saved_datasets/'

# # Создаем директорию, если она не существует
# if not os.path.exists(save_directory):
#     os.makedirs(save_directory)

# # Список для тренировочных и валидационных датасетов
# train_datasets = [train_week_1, train_week_2, train_week_3, train_week_4, 
#                   train_week_5, train_week_6, train_week_7, train_week_8, 
#                   train_week_9, train_week_10]

# val_datasets = [val_week_1, val_week_2, val_week_3, val_week_4, 
#                 val_week_5, val_week_6, val_week_7, val_week_8, 
#                 val_week_9, val_week_10]

# # Сохранение обучающих данных
# for i in range(10):
#     file_name_train = f'{save_directory}train_week_{i + 1}.csv'
#     train_datasets[i].to_csv(file_name_train, index=False)  # Сохраняем DataFrame в CSV

# # Сохранение валидационных данных
# for i in range(10):
#     file_name_val = f'{save_directory}val_week_{i + 1}.csv'
#     val_datasets[i].to_csv(file_name_val, index=False)  # Сохраняем DataFrame в CSV

# print("Файлы сохранены.")


# ## 2. Обучение моделей прогнозирования прогресса по курсу

# #### 2.1. Обучение простых моделей

# 2.1.1. Линейная регрессия

# In[10]:


import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.metrics import mean_absolute_error

# Функция обучения модели линейной регрессии с использованием Pipeline
def create_linear_regression(X, y):
    # Создание конвейера с импутером и моделью линейной регрессии
    pipeline = Pipeline(steps=[
        ('imputer', SimpleImputer(strategy='mean')),  # Заполнение пропусков средними значениями
        ('model', LinearRegression())  # Модель линейной регрессии
    ])
    
    # Обучение модели
    pipeline.fit(X, y)

    return pipeline  # Возвращаем модель

# Словарь для хранения моделей и список для MAE
lr_models = {}  # Словарь для моделей
lr_maes = []    # Список для MAE

# Создание DataFrame для хранения предсказаний
lr_predictions_df = pd.DataFrame()

# Цикл от 1 до 10 для обучения моделей на обучающих данных
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из обучающей выборки
    train_week = globals()[f'train_week_{week}']
    
    # Подготовка данных для обучения
    X_week = train_week.drop(['m2_progress', 'm2_success'], axis=1)
    y_week = train_week['m2_progress']
    
    # Обучение модели линейной регрессии с обработкой пропусков
    lr_model = create_linear_regression(X_week, y_week)

    # Сохранение модели в словарь
    lr_models[f'lr_model_week_{week}'] = lr_model  # Добавляем модель в словарь

    # Предсказания на валидационных данных
    val_week = globals()[f'val_week_{week}']
    X_val_week = val_week.drop(['m2_progress', 'm2_success'], axis=1)
    y_val_week = val_week['m2_progress']

    predictions = lr_model.predict(X_val_week)

    # Оценка модели на валидационных данных
    mae = mean_absolute_error(y_val_week, predictions)
    
    # Добавление MAE в список
    lr_maes.append(mae)

    # Добавление предсказаний в DataFrame
    lr_predictions_df[f'predictions_val_week_{week}'] = predictions

# Вывод MAE для каждой недели на валидационных данных
for week in range(10):
    print(f"Validation Week {week + 1} - Mean Absolute Error: {lr_maes[week]}")


# 2.1.2. Дерево решений

# In[11]:


from sklearn.tree import DecisionTreeRegressor, plot_tree
import pandas as pd
import os

# Создание папки для сохранения графиков, если она не существует
# output_dir = '/home/shared_notebooks/zloy/trees'
# os.makedirs(output_dir, exist_ok=True)

# Функция обучения модели решающего дерева
def create_decision_tree(X, y):
    # Создание и настройка модели решающего дерева
    dt_model = DecisionTreeRegressor(random_state=42)
    
    # Обучение модели
    dt_model.fit(X, y)

    return dt_model  # Возвращаем модель

# Словарь для хранения моделей и список для MAE
dt_models = {}  # Словарь для моделей
dt_maes = []    # Список для MAE

# Создание списка для хранения предсказаний
dt_predictions = []

# Цикл от 1 до 10 для обучения моделей на обучающих данных
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из обучающей выборки
    train_week = globals()[f'train_week_{week}']
    
    # Подготовка данных для обучения
    X_week = train_week.drop(['m2_progress', 'm2_success'], axis=1)  # Оставляем все столбцы, кроме целевой переменной
    y_week = train_week['m2_progress']  # Целевая переменная
    
    # Обучение модели решающего дерева
    dt_model = create_decision_tree(X_week, y_week)

    # Сохранение модели в словарь
    dt_models[f'dt_model_week_{week}'] = dt_model  # Добавляем модель в словарь

    # Предсказания на валидационных данных
    val_week = globals()[f'val_week_{week}']
    X_val_week = val_week.drop(['m2_progress', 'm2_success'], axis=1)  # Оставляем все столбцы, кроме целевой переменной
    y_val_week = val_week['m2_progress']  # Целевая переменная

    predictions = dt_model.predict(X_val_week)

    # Оценка модели на валидационных данных
    mae = mean_absolute_error(y_val_week, predictions)
    
    # Добавление MAE в список
    dt_maes.append(mae)

    # Добавление предсказаний в список
    dt_predictions.append(predictions)

    # Визуализация решающего дерева с использованием plot_tree (при необходимости)
#     plt.figure(figsize=(20, 10))
#     plot_tree(dt_model, 
#               feature_names=X_week.columns,
#               filled=True,
#               rounded=True)
    
#     plt.title(f"Decision Tree - Week {week}")
    
    # plt.savefig(os.path.join(output_dir, f"decision_tree_week_{week}.png"))  # Сохранение графика в формате PNG
    # plt.close()  # Закрытие фигуры для освобождения памяти

# Вывод MAE для каждой недели на валидационных данных
for week in range(10):
    print(f"Validation Week {week + 1} - Mean Absolute Error: {dt_maes[week]}")


# #### 2.2 Обучение ансамблей моделей

# 2.2.1. Случайный лес

# In[12]:


from sklearn.ensemble import RandomForestRegressor

# Функция обучения модели случайного леса
def create_random_forest(X, y):
    # Создание и настройка модели случайного леса
    rf_model = RandomForestRegressor()

    # Обучение модели
    rf_model.fit(X, y)

    return rf_model  # Возвращаем модель

# Словарь для хранения моделей и список для MAE
rf_models = {}  # Словарь для моделей
rf_maes = []    # Список для MAE

# Создание списка для хранения предсказаний
rf_predictions = []

# Цикл от 1 до 10 для обучения моделей на обучающих данных
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из обучающей выборки
    train_week = globals()[f'train_week_{week}']
    
    # Подготовка данных для обучения
    X_week = train_week.drop(['m2_progress', 'm2_success'], axis=1)  # Оставляем все столбцы, кроме целевой переменной
    y_week = train_week['m2_progress']  # Целевая переменная
    
    # Обучение модели случайного леса
    rf_model = create_random_forest(X_week, y_week)

    # Сохранение модели в словарь
    rf_models[f'rf_model_week_{week}'] = rf_model  # Добавляем модель в словарь

    # Предсказания на валидационных данных
    val_week = globals()[f'val_week_{week}']
    X_val_week = val_week.drop(['m2_progress', 'm2_success'], axis=1)  # Оставляем все столбцы, кроме целевой переменной
    y_val_week = val_week['m2_progress']  # Целевая переменная

    predictions = rf_model.predict(X_val_week)

    # Оценка модели на валидационных данных
    mae = mean_absolute_error(y_val_week, predictions)
    
    # Добавление MAE в список
    rf_maes.append(mae)

    # Добавление предсказаний в список
    rf_predictions.append(predictions)

# Вывод MAE для каждой недели на валидационных данных
for week in range(10):
    print(f"Validation Week {week + 1} - Mean Absolute Error: {rf_maes[week]}")


# 2.2.2. Градиентный бустинг sklearn

# In[13]:


import pandas as pd
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.metrics import mean_absolute_error

# Функция обучения модели градиентного бустинга с использованием Pipeline
def create_gradient_boosting(X, y):
    # Создание конвейера с импутером и моделью градиентного бустинга
    pipeline = Pipeline(steps=[
        ('imputer', SimpleImputer(strategy='mean')),  # Заполнение пропусков средними значениями
        ('model', GradientBoostingRegressor())  # Модель градиентного бустинга
    ])
    
    # Обучение модели
    pipeline.fit(X, y)

    return pipeline  # Возвращаем модель

# Словарь для хранения моделей и список для MAE
gb_models = {}  # Словарь для моделей
gb_maes = []    # Список для MAE

# Создание DataFrame для хранения предсказаний
gb_predictions_df = pd.DataFrame()

# Цикл от 1 до 10 для обучения моделей на обучающих данных
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из обучающей выборки
    train_week = globals()[f'train_week_{week}']
    
    # Подготовка данных для обучения
    X_week = train_week.drop(['m2_progress', 'm2_success'], axis=1)
    y_week = train_week['m2_progress']
    
    # Обучение модели градиентного бустинга с обработкой пропусков
    gb_model = create_gradient_boosting(X_week, y_week)

    # Сохранение модели в словарь
    gb_models[f'gb_model_week_{week}'] = gb_model  # Добавляем модель в словарь

    # Предсказания на валидационных данных
    val_week = globals()[f'val_week_{week}']
    X_val_week = val_week.drop(['m2_progress', 'm2_success'], axis=1)
    y_val_week = val_week['m2_progress']

    predictions = gb_model.predict(X_val_week)

    # Оценка модели на валидационных данных
    mae = mean_absolute_error(y_val_week, predictions)
    
    # Добавление MAE в список
    gb_maes.append(mae)

    # Добавление предсказаний в DataFrame
    gb_predictions_df[f'predictions_val_week_{week}'] = predictions

# Вывод MAE для каждой недели на валидационных данных
for week in range(10):
    print(f"Validation Week {week + 1} - Mean Absolute Error: {gb_maes[week]}")


# 2.2.3. XGBoost

# In[14]:


from xgboost import XGBRegressor

# Функция обучения модели XGBoost
def create_xgboost(X, y):
    # Создание и настройка модели XGBoost
    xgb_model = XGBRegressor()

    # Обучение модели
    xgb_model.fit(X, y)

    return xgb_model  # Возвращаем модель

# Словарь для хранения моделей и список для MAE
xgb_models = {}  # Словарь для моделей
xgb_maes = []    # Список для MAE

# Создание DataFrame для хранения предсказаний
xgb_predictions_df = pd.DataFrame()

# Цикл от 1 до 10 для обучения моделей на обучающих данных
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из обучающей выборки
    train_week = globals()[f'train_week_{week}']
    
    # Подготовка данных для обучения
    X_week = train_week.drop(['m2_progress', 'm2_success'], axis=1)
    y_week = train_week['m2_progress']
    
    # Обучение модели XGBoost
    xgb_model = create_xgboost(X_week, y_week)

    # Сохранение модели в словарь
    xgb_models[f'xgb_model_week_{week}'] = xgb_model  # Добавляем модель в словарь

    # Предсказания на валидационных данных
    val_week = globals()[f'val_week_{week}']
    X_val_week = val_week.drop(['m2_progress', 'm2_success'], axis=1)
    y_val_week = val_week['m2_progress']

    predictions = xgb_model.predict(X_val_week)

    # Оценка модели на валидационных данных
    mae = mean_absolute_error(y_val_week, predictions)
    
    # Добавление MAE в список
    xgb_maes.append(mae)

    # Добавление предсказаний в DataFrame
    xgb_predictions_df[f'predictions_val_week_{week}'] = predictions

# Вывод MAE для каждой недели на валидационных данных
for week in range(10):
    print(f"Validation Week {week + 1} - Mean Absolute Error: {xgb_maes[week]}")


# 2.2.4. CatBoost

# In[15]:


from catboost import CatBoostRegressor

# Функция обучения модели CatBoost
def create_catboost(X, y):
    # Создание и настройка модели CatBoost
    catboost_model = CatBoostRegressor(silent=True)  # Устанавливаем silent=True, чтобы отключить вывод

    # Обучение модели
    catboost_model.fit(X, y)

    return catboost_model  # Возвращаем модель

# Словарь для хранения моделей и список для MAE
catboost_models = {}  # Словарь для моделей
catboost_maes = []    # Список для MAE

# Создание списка для хранения предсказаний
catboost_predictions = []

# Цикл от 1 до 10 для обучения моделей на обучающих данных
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из обучающей выборки
    train_week = globals()[f'train_week_{week}']
    
    # Подготовка данных для обучения
    X_week = train_week.drop(['m2_progress', 'm2_success'], axis=1)  # Оставляем все столбцы, кроме целевой переменной
    y_week = train_week['m2_progress']  # Целевая переменная
    
    # Обучение модели CatBoost
    catboost_model = create_catboost(X_week, y_week)

    # Сохранение модели в словарь
    catboost_models[f'catboost_model_week_{week}'] = catboost_model  # Добавляем модель в словарь

    # Предсказания на валидационных данных
    val_week = globals()[f'val_week_{week}']
    X_val_week = val_week.drop(['m2_progress', 'm2_success'], axis=1)  # Оставляем все столбцы, кроме целевой переменной
    y_val_week = val_week['m2_progress']  # Целевая переменная

    predictions = catboost_model.predict(X_val_week)

    # Оценка модели на валидационных данных
    mae = mean_absolute_error(y_val_week, predictions)
    
    # Добавление MAE в список
    catboost_maes.append(mae)

    # Добавление предсказаний в список
    catboost_predictions.append(predictions)

# Вывод MAE для каждой недели на валидационных данных
for week in range(10):
    print(f"Validation Week {week + 1} - Mean Absolute Error: {catboost_maes[week]}")


# 2.2.5. Light Gradient Boosted Machine

# In[16]:


import lightgbm as lgb
from sklearn.metrics import mean_absolute_error

# Функция обучения модели LightGBM
def create_lightgbm(X, y):
    # Создание и настройка модели LightGBM
    lgb_model = lgb.LGBMRegressor()

    # Обучение модели
    lgb_model.fit(X, y)

    return lgb_model  # Возвращаем модель

# Словарь для хранения моделей и список для MAE
lgb_models = {}  # Словарь для моделей
lgb_maes = []    # Список для MAE

# Создание списка для хранения предсказаний
lgb_predictions = []

# Цикл от 1 до 10 для обучения моделей на обучающих данных
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из обучающей выборки
    train_week = globals()[f'train_week_{week}']
    
    # Подготовка данных для обучения
    X_week = train_week.drop(['m2_progress', 'm2_success'], axis=1)  # Оставляем все столбцы, кроме целевой переменной
    y_week = train_week['m2_progress']  # Целевая переменная
    
    # Обучение модели LightGBM
    lgb_model = create_lightgbm(X_week, y_week)

    # Сохранение модели в словарь
    lgb_models[f'lgb_model_week_{week}'] = lgb_model  # Добавляем модель в словарь

    # Предсказания на валидационных данных
    val_week = globals()[f'val_week_{week}']
    X_val_week = val_week.drop(['m2_progress', 'm2_success'], axis=1)  # Оставляем все столбцы, кроме целевой переменной
    y_val_week = val_week['m2_progress']  # Целевая переменная

    predictions = lgb_model.predict(X_val_week)

    # Оценка модели на валидационных данных
    mae = mean_absolute_error(y_val_week, predictions)
    
    # Добавление MAE в список
    lgb_maes.append(mae)

    # Добавление предсказаний в список (если нужно)
    lgb_predictions.append(predictions)

# Вывод MAE для каждой недели на валидационных данных
for week in range(10):
    print(f"Validation Week {week + 1} - Mean Absolute Error: {lgb_maes[week]}")


# ## 3. Сравнение и визуализация результатов

# In[17]:


# Создание словаря с данными МАЕ разных моделей
model_results_data = {
    'week_1': [
        round(lr_maes[0],2), round(dt_maes[0],2), round(rf_maes[0],2), 
        round(gb_maes[0],2), round(xgb_maes[0],2), round(catboost_maes[0],2), 
        round(lgb_maes[0],2)
    ],
    'week_2': [
        round(lr_maes[1],2), round(dt_maes[1],2), round(rf_maes[1],2), 
        round(gb_maes[1],2), round(xgb_maes[1],2), round(catboost_maes[1],2), 
        round(lgb_maes[1],2)
    ],
    'week_3': [
        round(lr_maes[2],2), round(dt_maes[2],2), round(rf_maes[2],2), 
        round(gb_maes[2],2), round(xgb_maes[2],2), round(catboost_maes[2],2), 
        round(lgb_maes[2],2)
    ],
    'week_4': [
        round(lr_maes[3],2), round(dt_maes[3],2), round(rf_maes[3],2), 
        round(gb_maes[3],2), round(xgb_maes[3],2), round(catboost_maes[3],2), 
        round(lgb_maes[3],2)
    ],
    'week_5': [
        round(lr_maes[4],2), round(dt_maes[4],2), round(rf_maes[4],2), 
        round(gb_maes[4],2), round(xgb_maes[4],2), round(catboost_maes[4],2), 
        round(lgb_maes[4],2)
    ],
    'week_6': [
        round(lr_maes[5],2), round(dt_maes[5],2), round(rf_maes[5],2),
        round(gb_maes[5],2),round(xgb_maes[5],2),round(catboost_maes[5],2),
        round(lgb_maes[5],2)
    ],
    'week_7': [
        round(lr_maes[6],2), round(dt_maes[6],2), round(rf_maes[6],2),
        round(gb_maes[6],2),round(xgb_maes[6],2), round(catboost_maes[6],2),
        round(lgb_maes[6],2)
    ],
    'week_8': [
        round(lr_maes[7],2), round(dt_maes[7],2), round(rf_maes[7],2),
        round(gb_maes[7],2),round(xgb_maes[7],2), round(catboost_maes[7],2),
        round(lgb_maes[7],2)
    ],
    'week_9': [
        round(lr_maes[8],2), round(dt_maes[8],2), round(rf_maes[8],2),
        round(gb_maes[8],2),round(xgb_maes[8],2), round(catboost_maes[8],2),
        round(lgb_maes[8],2)
    ],
    'week_10': [
        round(lr_maes[9],2), round(dt_maes[9],2), round(rf_maes[9],2),
        round(gb_maes[9],2), round(xgb_maes[9],2), round(catboost_maes[9],2),
        round(lgb_maes[9],2)
    ]
}

# Создание DataFrame
mae_df = pd.DataFrame(model_results_data)

# Установка индексов на названия моделей
mae_df.index = ['LinearRegression', 'DecisionTreeRegressor', 'RandomForestRegressor', 
                'GradientBoostingRegressor', 'XGBoost', 'CatBoost', 'LightGBM']


# In[18]:


mae_df


# In[19]:


# Создание матрицы для тепловой карты
heatmap_data = mae_df

plt.figure(figsize=(10, 10))
sns.heatmap(heatmap_data, annot=True, cmap='Blues', fmt=".2f", annot_kws={"size": 8}, vmin=0, vmax=20)
plt.title('Значения Mean Absolute Error по неделям')
plt.xlabel('Недели')
plt.ylabel('Модели машинного обучения')
# plt.savefig('./outputs/maes_weekly_all.png', dpi=300, bbox_inches='tight')
plt.show()


# **Вывод:** наилучший результат продемонстрировала модель случайного леса, что позволяет использовать её в качестве основной при прогнозировании показателей успеваемости обучающихся. Уже на второй неделе среднее абсолютное отклонение от реального целевого показателя составило 6,69. Это позволяет взять указанную модель за основу при дальнейшей работе.

# ## 4. Тестирование качества прогнозирования прогресса на разных курсах

# In[20]:


# Создаем выборки по курсам для тестирования
df_77_test = val_sample[val_sample['course_id'] == 77]
df_71_test = val_sample[val_sample['course_id'] == 71]
df_49_test = val_sample[val_sample['course_id'] == 49]
df_3_test = val_sample[val_sample['course_id'] == 3]

# Новые курсы
df_82_test = val_sample[val_sample['course_id'] == 82]
df_770_test = val_sample[val_sample['course_id'] == 770]
df_76_test = val_sample[val_sample['course_id'] == 76]
df_83_test = val_sample[val_sample['course_id'] == 83]

# Определяем количество недель
num_weeks = 10

# Создаем пустые датафреймы для каждой недели для всех курсов
df_list_77 = []
df_list_71 = []
df_list_49 = []
df_list_3 = []

df_list_82 = []
df_list_770 = []
df_list_76 = []
df_list_83 = []

# Функция для создания выборок по курсам
def create_weekly_dfs(course_df, course_list):
    for week in range(num_weeks, 0, -1):
        df_week = course_df.copy()
        df_week[f'required_activities_delay_{week}_week'] = 0
        df_week[f'success_required_done_{week}_week'] = 0
        df_week[f'mean_result_required_{week}_week'] = 0
        df_week[f'cur_date_progress_{week}_week'] = 0
        df_week[f'current_progress_{week}_week'] = 0
        
        course_list.append(df_week)

# Создаем выборки для каждого курса
create_weekly_dfs(df_77_test, df_list_77)
create_weekly_dfs(df_71_test, df_list_71)
create_weekly_dfs(df_49_test, df_list_49)
create_weekly_dfs(df_3_test, df_list_3)
create_weekly_dfs(df_82_test, df_list_82)
create_weekly_dfs(df_770_test, df_list_770)
create_weekly_dfs(df_76_test, df_list_76)
create_weekly_dfs(df_83_test, df_list_83)

# Присваиваем переменные для каждой недели из списков
df_week_10_3, df_week_9_3, df_week_8_3, df_week_7_3, df_week_6_3, df_week_5_3, df_week_4_3, df_week_3_3, df_week_2_3, df_week_1_3 = df_list_3

df_week_10_49, df_week_9_49, df_week_8_49, df_week_7_49, df_week_6_49, df_week_5_49, df_week_4_49, df_week_49_49, df_week_2_49, df_week_1_49 = df_list_49

df_week_10_71, df_week_9_71, df_week_8_71, df_week_7_71, df_week_6_71, df_week_5_71, df_week_4_71, df_week_71_71, df_week_2_71, df_week_1_71 = df_list_71

df_week_10_77, df_week_9_77, df_week_8_77, df_week_7_77, df_week_6_77, df_week_5_77, df_week_4_77, df_week_3_77, df_week_2_77, df_week_1_77 = df_list_77

df_week_10_82, df_week_9_82, df_week_8_82, df_week_7_82, df_week_6_82, df_week_5_82, df_week_4_82, df_week_82_82, df_week_2_82, df_week_1_82 = df_list_82

df_week_10_770, df_week_9_770, df_week_8_770, df_week_7_770, df_week_6_770, df_week_5_770, df_week_4_770, df_week_770_770, df_week_2_770, df_week_1_770 = df_list_770

df_week_10_76, df_week_9_76, df_week_8_76, df_week_7_76, df_week_6_76, df_week_5_76, df_week_4_76, df_week_76_76, df_week_2_76, df_week_1_76 = df_list_76

df_week_10_83, df_week_9_83, df_week_8_83, df_week_7_83, df_week_6_83, df_week_5_83, df_week_4_83, df_week_82_83, df_week_2_83, df_week_1_83 = df_list_83
# Теперь у нас есть датафреймы для каждой недели по всем курсам.


# #### 4.1. Тестирование на разных учебных курсах

# In[21]:


# Словарь для хранения MAE
rf_maes_3 = []    # Список для MAE

# Создание DataFrame для хранения предсказаний
rf_predictions_df_3 = pd.DataFrame()

# Цикл от 1 до 10 для использования обученных моделей
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из df_3
    df_week_3 = df_list_3[week - 1]  # Предполагаем, что df_list_3 содержит датафреймы для каждой недели
    
    # Подготовка данных для предсказания
    X_week = df_week_3.drop(['m2_progress', 'm2_success'], axis=1)
    y_week = df_week_3['m2_progress']
    
    # Загрузка обученной модели из словаря
    rf_model_3 = rf_models[f'rf_model_week_{week}']  # Получаем модель из словаря

    # Предсказания на текущих данных
    predictions = rf_model_3.predict(X_week)
    
    # Вычисление MAE (если у вас есть истинные значения y_week)
    mae = mean_absolute_error(y_week, predictions)
    rf_maes_3.append(mae)  # Добавляем MAE в список

    # Добавление предсказаний в DataFrame
    rf_predictions_df_3[f'predictions_week_{week}'] = predictions

# Вывод MAE для каждой недели
for week in range(10):
    print(f"Week {week + 1} - Mean Absolute Error: {rf_maes_3[week]}")


# In[22]:


# Словарь для хранения MAE
rf_maes_49 = []    # Список для MAE

# Создание DataFrame для хранения предсказаний
rf_predictions_df_49 = pd.DataFrame()

# Цикл от 1 до 10 для использования обученных моделей
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из df_49
    df_week_49 = df_list_49[week - 1]  # Предполагаем, что df_list_49 содержит датафреймы для каждой недели
    
    # Подготовка данных для предсказания
    X_week = df_week_49.drop(['m2_progress', 'm2_success'], axis=1)
    y_week = df_week_49['m2_progress']
    
    # Загрузка обученной модели из словаря
    rf_model_49 = rf_models[f'rf_model_week_{week}']  # Получаем модель из словаря

    # Предсказания на текущих данных
    predictions = rf_model_49.predict(X_week)
    
    # Вычисление MAE (если у вас есть истинные значения y_week)
    mae = mean_absolute_error(y_week, predictions)
    rf_maes_49.append(mae)  # Добавляем MAE в список

    # Добавление предсказаний в DataFrame
    rf_predictions_df_49[f'predictions_week_{week}'] = predictions

# Вывод MAE для каждой недели
for week in range(10):
    print(f"Week {week + 1} - Mean Absolute Error: {rf_maes_49[week]}")


# In[23]:


# Словарь для хранения MAE
rf_maes_71 = []    # Список для MAE

# Создание DataFrame для хранения предсказаний
rf_predictions_df_71 = pd.DataFrame()

# Цикл от 1 до 10 для использования обученных моделей
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из df_71
    df_week_71 = df_list_71[week - 1]  # Предполагаем, что df_list_71 содержит датафреймы для каждой недели
    
    # Подготовка данных для предсказания
    X_week = df_week_71.drop(['m2_progress', 'm2_success'], axis=1)
    y_week = df_week_71['m2_progress']
    
    # Загрузка обученной модели из словаря
    rf_model_71 = rf_models[f'rf_model_week_{week}']  # Получаем модель из словаря

    # Предсказания на текущих данных
    predictions = rf_model_71.predict(X_week)
    
    # Вычисление MAE (если у вас есть истинные значения y_week)
    mae = mean_absolute_error(y_week, predictions)
    rf_maes_71.append(mae)  # Добавляем MAE в список

    # Добавление предсказаний в DataFrame
    rf_predictions_df_71[f'predictions_week_{week}'] = predictions

# Вывод MAE для каждой недели
for week in range(10):
    print(f"Week {week + 1} - Mean Absolute Error: {rf_maes_71[week]}")


# In[24]:


# Словарь для хранения MAE
rf_maes_77 = []    # Список для MAE

# Создание DataFrame для хранения предсказаний
rf_predictions_df_77 = pd.DataFrame()

# Цикл от 1 до 10 для использования обученных моделей
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из df_77
    df_week_77 = df_list_77[week - 1]  # Предполагаем, что df_list_77 содержит датафреймы для каждой недели
    
    # Подготовка данных для предсказания
    X_week = df_week_77.drop(['m2_progress', 'm2_success'], axis=1)
    y_week = df_week_77['m2_progress']
    
    # Загрузка обученной модели из словаря
    rf_model_77 = rf_models[f'rf_model_week_{week}']  # Получаем модель из словаря

    # Предсказания на текущих данных
    predictions = rf_model_77.predict(X_week)
    
    # Вычисление MAE (если у вас есть истинные значения y_week)
    mae = mean_absolute_error(y_week, predictions)
    rf_maes_77.append(mae)  # Добавляем MAE в список

    # Добавление предсказаний в DataFrame
    rf_predictions_df_77[f'predictions_week_{week}'] = predictions

# Вывод MAE для каждой недели
for week in range(10):
    print(f"Week {week + 1} - Mean Absolute Error: {rf_maes_77[week]}")


# In[25]:


# Словарь для хранения MAE
rf_maes_76 = []    # Список для MAE

# Создание DataFrame для хранения предсказаний
rf_predictions_df_76 = pd.DataFrame()

# Цикл от 1 до 10 для использования обученных моделей
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из df_76
    df_week_76 = df_list_76[week - 1]  # Предполагаем, что df_list_76 содержит датафреймы для каждой недели
    
    # Подготовка данных для предсказания
    X_week = df_week_76.drop(['m2_progress', 'm2_success'], axis=1)
    y_week = df_week_76['m2_progress']
    
    # Загрузка обученной модели из словаря
    rf_model_76 = rf_models[f'rf_model_week_{week}']  # Получаем модель из словаря

    # Предсказания на текущих данных
    predictions = rf_model_76.predict(X_week)
    
    # Вычисление MAE (если у вас есть истинные значения y_week)
    mae = mean_absolute_error(y_week, predictions)
    rf_maes_76.append(mae)  # Добавляем MAE в список

    # Добавление предсказаний в DataFrame
    rf_predictions_df_76[f'predictions_week_{week}'] = predictions

# Вывод MAE для каждой недели
for week in range(10):
    print(f"Week {week + 1} - Mean Absolute Error: {rf_maes_76[week]}")


# In[26]:


# Словарь для хранения MAE
rf_maes_82 = []    # Список для MAE

# Создание DataFrame для хранения предсказаний
rf_predictions_df_82 = pd.DataFrame()

# Цикл от 1 до 10 для использования обученных моделей
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из df_82
    df_week_82 = df_list_82[week - 1]  # Предполагаем, что df_list_82 содержит датафреймы для каждой недели
    
    # Подготовка данных для предсказания
    X_week = df_week_82.drop(['m2_progress', 'm2_success'], axis=1)
    y_week = df_week_82['m2_progress']
    
    # Загрузка обученной модели из словаря
    rf_model_82 = rf_models[f'rf_model_week_{week}']  # Получаем модель из словаря

    # Предсказания на текущих данных
    predictions = rf_model_82.predict(X_week)
    
    # Вычисление MAE (если есть истинные значения y_week)
    mae = mean_absolute_error(y_week, predictions)
    rf_maes_82.append(mae)  # Добавляем MAE в список

    # Добавление предсказаний в DataFrame
    rf_predictions_df_82[f'predictions_week_{week}'] = predictions

# Вывод MAE для каждой недели
for week in range(10):
    print(f"Week {week + 1} - Mean Absolute Error: {rf_maes_82[week]}")


# In[27]:


# Словарь для хранения MAE
rf_maes_770 = []    # Список для MAE

# Создание DataFrame для хранения предсказаний
rf_predictions_df_770 = pd.DataFrame()

# Цикл от 1 до 10 для использования обученных моделей
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из df_770
    df_week_770 = df_list_770[week - 1]  # Предполагаем, что df_list_770 содержит датафреймы для каждой недели
    
    # Подготовка данных для предсказания
    X_week = df_week_770.drop(['m2_progress', 'm2_success'], axis=1)
    y_week = df_week_770['m2_progress']
    
    # Загрузка обученной модели из словаря
    rf_model_770 = rf_models[f'rf_model_week_{week}']  # Получаем модель из словаря

    # Предсказания на текущих данных
    predictions = rf_model_770.predict(X_week)
    
    # Вычисление MAE (если есть истинные значения y_week)
    mae = mean_absolute_error(y_week, predictions)
    rf_maes_770.append(mae)  # Добавляем MAE в список

    # Добавление предсказаний в DataFrame
    rf_predictions_df_770[f'predictions_week_{week}'] = predictions

# Вывод MAE для каждой недели
for week in range(10):
    print(f"Week {week + 1} - Mean Absolute Error: {rf_maes_770[week]}")


# In[28]:


# Словарь для хранения MAE
rf_maes_83 = []    # Список для MAE

# Создание DataFrame для хранения предсказаний
rf_predictions_df_83 = pd.DataFrame()

# Цикл от 1 до 10 для использования обученных моделей
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из df_83
    df_week_83 = df_list_83[week - 1]  # Предполагаем, что df_list_83 содержит датафреймы для каждой недели
    
    # Подготовка данных для предсказания
    X_week = df_week_83.drop(['m2_progress', 'm2_success'], axis=1)
    y_week = df_week_83['m2_progress']
    
    # Загрузка обученной модели из словаря
    rf_model_83 = rf_models[f'rf_model_week_{week}']  # Получаем модель из словаря

    # Предсказания на текущих данных
    predictions = rf_model_83.predict(X_week)
    
    # Вычисление MAE (если у вас есть истинные значения y_week)
    mae = mean_absolute_error(y_week, predictions)
    rf_maes_83.append(mae)  # Добавляем MAE в список

    # Добавление предсказаний в DataFrame
    rf_predictions_df_83[f'predictions_week_{week}'] = predictions

# Вывод MAE для каждой недели
for week in range(10):
    print(f"Week {week + 1} - Mean Absolute Error: {rf_maes_83[week]}")


# In[29]:


test_rf_maes = pd.DataFrame()
test_rf_maes['course_3'] = rf_maes_3
test_rf_maes['course_49'] = rf_maes_49
test_rf_maes['course_71'] = rf_maes_71
test_rf_maes['course_77'] = rf_maes_77
test_rf_maes['course_76'] = rf_maes_76
test_rf_maes['course_82'] = rf_maes_82
test_rf_maes['course_770'] = rf_maes_770
test_rf_maes['course_83'] = rf_maes_83
test_rf_maes.index = [f'week_{i}' for i in range(1, len(test_rf_maes) + 1)]

test_rf_maes = test_rf_maes.T
test_rf_maes


# In[30]:


# Создание матрицы для тепловой карты
heatmap_data = test_rf_maes

plt.figure(figsize=(10, 6))
sns.heatmap(heatmap_data, annot=True, cmap='Blues', fmt=".2f", annot_kws={"size": 8}, vmin=0, vmax=40)
plt.title('Значения Mean Absolute Error для разных курсов по неделям')
plt.xlabel('Недели')
plt.ylabel('Учебные курсы')
# plt.savefig('./outputs/maes_groups.png', dpi=300, bbox_inches='tight')
plt.show()


# ## 5. Визуализация результатов. Сериализация моделей для их дальнейшего использования

# #### 5.1. Визуализация примеров прогнозирования прогресса по курсу для разных курсов

# In[31]:


# формируем датафреймы с истинными и предсказанными метками для каждой группы
true_label_3 = df_3_test[['user_id', 'm2_progress']].copy()
true_label_3.reset_index(drop=True, inplace=True)
results_3 = pd.concat([true_label_3, rf_predictions_df_3], axis=1)


# In[32]:


true_label_77 = df_77_test[['user_id', 'm2_progress']].copy()
true_label_77.reset_index(drop=True, inplace=True)
results_77 = pd.concat([true_label_77, rf_predictions_df_77], axis=1)


# In[33]:


true_label_71 = df_71_test[['user_id', 'm2_progress']].copy()
true_label_71.reset_index(drop=True, inplace=True)
results_71 = pd.concat([true_label_71, rf_predictions_df_71], axis=1)


# In[34]:


true_label_49 = df_49_test[['user_id', 'm2_progress']].copy()
true_label_49.reset_index(drop=True, inplace=True)
results_49 = pd.concat([true_label_49, rf_predictions_df_49], axis=1)


# In[35]:


true_label_76 = df_76_test[['user_id', 'm2_progress']].copy()
true_label_76.reset_index(drop=True, inplace=True)
results_76 = pd.concat([true_label_76, rf_predictions_df_76], axis=1)


# In[36]:


true_label_82 = df_82_test[['user_id', 'm2_progress']].copy()
true_label_82.reset_index(drop=True, inplace=True)
results_82 = pd.concat([true_label_82, rf_predictions_df_82], axis=1)


# In[37]:


true_label_83 = df_83_test[['user_id', 'm2_progress']].copy()
true_label_83.reset_index(drop=True, inplace=True)
results_83 = pd.concat([true_label_83, rf_predictions_df_83], axis=1)


# In[38]:


true_label_770 = df_770_test[['user_id', 'm2_progress']].copy()
true_label_770.reset_index(drop=True, inplace=True)
results_770 = pd.concat([true_label_770, rf_predictions_df_770], axis=1)


# In[39]:


# визуализируем результаты прогнозирования на тепловой карте
samples_3 = results_3.sample(15)
samples_3 = samples_3.astype(int)

heatmap_data = samples_3

plt.figure(figsize=(15, 10))
sns.heatmap(heatmap_data, annot=True, cmap='Blues', fmt="d", annot_kws={"size": 8}, vmin=0, vmax=100)
plt.title('Примеры прогнозов по 3 курсу')

# сохраняем график в файл при необходимости
# plt.savefig('./outputs/samples_3.png', dpi=300, bbox_inches='tight')
plt.show()


# In[40]:


samples_49 = results_49.sample(15)
samples_49 = samples_49.astype(int)

heatmap_data = samples_49

plt.figure(figsize=(15, 10))
sns.heatmap(heatmap_data, annot=True, cmap='Blues', fmt="d", annot_kws={"size": 8}, vmin=0, vmax=100)
plt.title('Примеры прогнозов по 49 курсу')
# plt.savefig('./outputs/samples_49.png', dpi=300, bbox_inches='tight')
plt.show()


# In[41]:


samples_71 = results_71.sample(15)
samples_71 = samples_71.astype(int)

heatmap_data = samples_71

plt.figure(figsize=(15, 10))
sns.heatmap(heatmap_data, annot=True, cmap='Blues', fmt="d", annot_kws={"size": 8}, vmin=0, vmax=100)
plt.title('Примеры прогнозов по 71 курсу')
# plt.savefig('./outputs/samples_71.png', dpi=300, bbox_inches='tight')
plt.show()


# In[42]:


samples_77 = results_77.sample(15)
samples_77 = samples_77.astype(int)

heatmap_data = samples_77

plt.figure(figsize=(15, 10))
sns.heatmap(heatmap_data, annot=True, cmap='Blues', fmt="d", annot_kws={"size": 8}, vmin=0, vmax=100)
plt.title('Примеры прогнозов по 77 курсу')
# plt.savefig('./outputs/samples_77.png', dpi=300, bbox_inches='tight')
plt.show()


# In[43]:


samples_770 = results_770.sample(15)
samples_770 = samples_770.astype(int)

heatmap_data = samples_770

plt.figure(figsize=(15, 10))
sns.heatmap(heatmap_data, annot=True, cmap='Blues', fmt="d", annot_kws={"size": 8}, vmin=0, vmax=100)
plt.title('Примеры прогнозов по 770 курсу')
# plt.savefig('./outputs/samples_770.png', dpi=300, bbox_inches='tight')
plt.show()


# In[44]:


samples_82 = results_82.sample(15)
samples_82 = samples_82.astype(int)

heatmap_data = samples_82

plt.figure(figsize=(15, 10))
sns.heatmap(heatmap_data, annot=True, cmap='Blues', fmt="d", annot_kws={"size": 8}, vmin=0, vmax=100)
plt.title('Примеры прогнозов по 82 курсу')
# plt.savefig('./outputs/samples_82.png', dpi=300, bbox_inches='tight')
plt.show()


# In[45]:


samples_83 = results_83.sample(15)
samples_83 = samples_83.astype(int)

heatmap_data = samples_83

plt.figure(figsize=(15, 10))
sns.heatmap(heatmap_data, annot=True, cmap='Blues', fmt="d", annot_kws={"size": 8}, vmin=0, vmax=100)
plt.title('Примеры прогнозов по 83 курсу')
# plt.savefig('./outputs/samples_83.png', dpi=300, bbox_inches='tight')
plt.show()


# In[46]:


samples_76 = results_76.sample(15)
samples_76 = samples_76.astype(int)

heatmap_data = samples_76

plt.figure(figsize=(15, 10))
sns.heatmap(heatmap_data, annot=True, cmap='Blues', fmt="d", annot_kws={"size": 8}, vmin=0, vmax=100)
plt.title('Примеры прогнозов по 76 курсу')
# plt.savefig('./outputs/samples_76.png', dpi=300, bbox_inches='tight')
plt.show()


# In[47]:


# словарь моделей случайного леса по каждой неделе
rf_models


# #### 5.2. Сериализация моделей

# In[48]:


# import joblib  # Импортируем библиотеку для сериализации
# import os

# # Укажите директорию для сохранения моделей
# model_dir = './saved_models'

# # Создаем директорию, если она не существует
# os.makedirs(model_dir, exist_ok=True)

# {'rf_model_week_1': RandomForestRegressor(max_features='log2', n_estimators=50),
#  'rf_model_week_2': RandomForestRegressor(max_features='log2', n_estimators=50),
#  'rf_model_week_3': RandomForestRegressor(max_features='log2', n_estimators=50),
#  'rf_model_week_4': RandomForestRegressor(max_depth=30, max_features='log2', n_estimators=200),
#  'rf_model_week_5': RandomForestRegressor(max_features='log2', n_estimators=50),
#  'rf_model_week_6': RandomForestRegressor(max_features='log2', n_estimators=200),
#  'rf_model_week_7': RandomForestRegressor(max_features='sqrt', n_estimators=200),
#  'rf_model_week_8': RandomForestRegressor(max_features='sqrt', n_estimators=200),
#  'rf_model_week_9': RandomForestRegressor(max_features='sqrt', n_estimators=200),
#  'rf_model_week_10': RandomForestRegressor(max_features='sqrt', n_estimators=200)}

# # Сериализация моделей на диск
# for model_name, model in rf_models.items():
#     model_filename = os.path.join(model_dir, f'{model_name}.joblib')  # Создаем имя файла для модели
#     joblib.dump(model, model_filename)  # Сохраняем модель в файл
#     print(f"Модель '{model_name}' успешно сохранена в '{model_filename}'")

# print(f"\nВсе модели успешно сохранены в директорию: {model_dir}")


# ## 6. Обучение моделей, прогнозирующих вероятность успешного завершения курса

# *Эксперимент по выбору наиболее результативной модели прогнозирования вероятности успешного завершения курса проводился отдельно. Наилучшие результаты показала модель градиентного бустинга, в связи с этим считаем возможным не проводить этот эксперимент повторно, а сразу обучить оптимальную модель.*

# #### 6.1. Обучение моделей градиентного бустинга, прогнозирующих вероятность успешного окончания курсов

# In[49]:


"""
Загрузка сохранённых датасетов нужна для чистоты эксперимента - 
чтобы обучающая и валидационная выборки для моделей прогнозирования прогресса по курсу
и моделей, прогнозирующих вероятность завершения курса, совпадали.
Если обучение моделей проводится в одну сессию выполнения кода, 
необходимости в загрузке сохранённых датасетов нет.

"""
# Загрузка сохраненных датасетов
import os
import pandas as pd

# Папка, из которой будем загружать файлы
load_directory = './saved_datasets/'

# Словарь для хранения загруженных датафреймов
train_datasets = {}
val_datasets = {}

def load_datasets(directory):
    """Загружает обучающие и валидационные наборы данных из указанной директории."""
    global train_datasets, val_datasets
    
    # Чтение обучающих данных
    for i in range(1, 11):  # от 1 до 10 включительно
        file_name_train = f'{directory}train_week_{i}.csv'
        if os.path.exists(file_name_train):
            train_datasets[f'train_week_{i}'] = pd.read_csv(file_name_train)
            print(f'Успешно загружен: {file_name_train}')
        else:
            print(f'Файл не найден: {file_name_train}')

    # Чтение валидационных данных
    for i in range(1, 11):  # от 1 до 10 включительно
        file_name_val = f'{directory}val_week_{i}.csv'
        if os.path.exists(file_name_val):
            val_datasets[f'val_week_{i}'] = pd.read_csv(file_name_val)
            print(f'Успешно загружен: {file_name_val}')
        else:
            print(f'Файл не найден: {file_name_val}')

# Загружаем датасеты
load_datasets(load_directory)

# Создаем переменные для доступа к загруженным датафреймам
for i in range(1, 11):
    globals()[f'train_week_{i}'] = train_datasets.get(f'train_week_{i}', None)
    globals()[f'val_week_{i}'] = val_datasets.get(f'val_week_{i}', None)


# In[50]:


# Выводим пример датасета за неделю, проверяем его. 
# Значения {признак}_{n+1}_week для n-й недели должны быть нулевыми
train_week_2


# In[51]:


import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.metrics import accuracy_score, precision_score, f1_score, roc_auc_score

# Функция обучения модели градиентного бустинга
def create_gradient_boosting(X, y):
    # Создание и настройка модели градиентного бустинга
    gb_model = GradientBoostingClassifier()

    # Обучение модели
    gb_model.fit(X, y)

    return gb_model  # Возвращаем модель

# Словарь для хранения моделей и списки для метрик
gb_models = {}  # Словарь для моделей
gb_metrics = []  # Список для метрик

# Создание списка для хранения предсказаний и вероятностей
gb_predictions = []
gb_probabilities = []

# Цикл от 1 до 10 для обучения моделей на обучающих данных
for week in range(1, 11):
    # Получаем DataFrame для текущей недели из обучающей выборки
    train_week = globals()[f'train_week_{week}']
    
    # Подготовка данных для обучения
    X_week = train_week.drop(['m2_progress', 'm2_success'], axis=1)  # Оставляем все столбцы, кроме целевой переменной
    y_week = train_week['m2_success']  # Целевая переменная
    
    # Обучение модели градиентного бустинга
    gb_model = create_gradient_boosting(X_week, y_week)

    # Сохранение модели в словарь
    gb_models[f'gb_model_week_{week}'] = gb_model  # Добавляем модель в словарь

    # Предсказания на валидационных данных
    val_week = globals()[f'val_week_{week}']
    X_val_week = val_week.drop(['m2_progress', 'm2_success'], axis=1)  # Оставляем все столбцы, кроме целевой переменной
    y_val_week = val_week['m2_success']  # Целевая переменная

    predictions = gb_model.predict(X_val_week)
    predictions_proba = gb_model.predict_proba(X_val_week)[:, 1]  # Вероятности положительного класса

    # Оценка модели на валидационных данных по различным метрикам
    accuracy = accuracy_score(y_val_week, predictions)
    precision = precision_score(y_val_week, predictions)
    f1 = f1_score(y_val_week, predictions)
    roc_auc = roc_auc_score(y_val_week, predictions_proba)

    # Сохранение метрик в список
    gb_metrics.append({
        'week': week,
        'accuracy': round(accuracy, 3),
        'precision': round(precision, 3),
        'f1': round(f1, 3),
        'roc_auc': round(roc_auc, 3)
    })

    # Добавление предсказаний и вероятностей в списки
    gb_predictions.append(predictions)
    gb_probabilities.append(predictions_proba)

# Преобразование списка метрик в DataFrame
metrics_df_gb = pd.DataFrame(gb_metrics)

# Вывод метрик для каждой недели на валидационных данных
display(metrics_df_gb)


# In[52]:


# Визуализация метрик с помощью тепловых карт
plt.figure(figsize=(8, 6))

# Accuracy Heatmap
plt.subplot(4, 1, 1)
sns.heatmap(metrics_df_gb[['week', 'accuracy']].set_index('week').T, annot=True, cmap='YlGnBu', cbar=True)
plt.title('Accuracy Heatmap (Gradient Boosting)')

# Precision Heatmap
plt.subplot(4, 1, 2)
sns.heatmap(metrics_df_gb[['week', 'precision']].set_index('week').T, annot=True, cmap='YlGnBu', cbar=True)
plt.title('Precision Heatmap (Gradient Boosting)')

# F1 Score Heatmap
plt.subplot(4, 1, 3)
sns.heatmap(metrics_df_gb[['week', 'f1']].set_index('week').T, annot=True, cmap='YlGnBu', cbar=True)
plt.title('F1 Score Heatmap (Gradient Boosting)')

# ROC AUC Heatmap
plt.subplot(4, 1, 4)
sns.heatmap(metrics_df_gb[['week', 'roc_auc']].set_index('week').T, annot=True, cmap='YlGnBu', cbar=True)
plt.title('ROC AUC Heatmap (Gradient Boosting)')

plt.tight_layout()
# Сохраняем тепловую карту с метриками
# plt.savefig('./outputs/gb_metrics.png', dpi=300, bbox_inches='tight')
plt.show()


# #### 6.2. Сериализация моделей, прогнозирующих вероятность успешного завершения курсов

# In[53]:


# Словарь моделей классификаторов градиентного бустинга по каждой неделе
gb_models


# In[54]:


# import joblib  # Импортируем библиотеку для сериализации
# import os

# # Укажите директорию для сохранения моделей
# model_dir = './saved_clf_models'

# # Создаем директорию, если она не существует
# os.makedirs(model_dir, exist_ok=True)

# {'gb_model_week_1': GradientBoostingClassifier(),
#  'gb_model_week_2': GradientBoostingClassifier(),
#  'gb_model_week_3': GradientBoostingClassifier(),
#  'gb_model_week_4': GradientBoostingClassifier(),
#  'gb_model_week_5': GradientBoostingClassifier(),
#  'gb_model_week_6': GradientBoostingClassifier(),
#  'gb_model_week_7': GradientBoostingClassifier(),
#  'gb_model_week_8': GradientBoostingClassifier(),
#  'gb_model_week_9': GradientBoostingClassifier(),
#  'gb_model_week_10': GradientBoostingClassifier()}

# # Сериализация моделей на диск
# for model_name, model in gb_models.items():
#     model_filename = os.path.join(model_dir, f'{model_name}.joblib')  # Создаем имя файла для модели
#     joblib.dump(model, model_filename)  # Сохраняем модель в файл
#     print(f"Модель '{model_name}' успешно сохранена в '{model_filename}'")

# print(f"\nВсе модели успешно сохранены в директорию: {model_dir}")

