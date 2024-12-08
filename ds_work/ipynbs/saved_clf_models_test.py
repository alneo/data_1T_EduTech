#!/usr/bin/env python
# coding: utf-8

# ## Задаём функцию прогнозирования прогресса по курсу по конкретному пользователю за нужную нам неделю

# In[11]:


import joblib
import pandas as pd

def predict_for_user(week, user_id):
    try:
        # Загружаем модель для указанной недели
        model = joblib.load(f'./saved_clf_models/gb_model_week_{week}.joblib')
        
        # Инициализируем переменную для хранения данных
        data = None
        
        # Сначала пытаемся загрузить данные из валидационного набора
        try:
            data = pd.read_csv(f'./saved_datasets/val_week_{week}.csv')
            print(f"Data for validation week {week} loaded successfully.")
            data_source = "validation"
        except FileNotFoundError:
            # Если данные для валидации отсутствуют, загружаем обучающий набор
            data = pd.read_csv(f'./saved_datasets/train_week_{week}.csv')
            print(f"Validation data not found. Using training data for week {week}.")
            data_source = "training"

        # Фильтруем данные по user_id
        user_data = data[data['user_id'] == user_id]
        
        # Проверяем наличие пользователя в загруженной выборке
        if user_data.empty:
            if data_source == "validation":
                print(f"No data found for user_id {user_id} in validation dataset. Checking training dataset.")
                # Загружаем обучающий набор и ищем пользователя там
                data = pd.read_csv(f'./saved_datasets/train_week_{week}.csv')
                user_data = data[data['user_id'] == user_id]
            
            # Проверяем еще раз после загрузки обучающего набора
            if user_data.empty:
                print(f"No data found for user_id {user_id} in both datasets.")
                return None
            
            print(f"User_id {user_id} found in the training dataset for week {week}.")
        
        else:
            print(f"User_id {user_id} found in the validation dataset for week {week}.")

        # Проверка наличия целевого признака
        if 'm2_success' not in user_data.columns:
            print("Column 'm2_success' is missing from the dataset.")
            return None

        # Получаем реальное значение целевого признака
        actual_value = user_data['m2_success'].values[0]

        # Выводим статус окончания курса в зависимости от значения m2_success
        if actual_value == 1:
            print(f"Реальный статус окончания курса для пользователя {user_id}: окончил успешно.")
        else:
            print(f"Реальный статус окончания курса для пользователя {user_id}: не окончил.")

        # Подготовка данных для предсказания
        X_user = user_data.drop(['m2_success'], axis=1)
        
        # Получаем список признаков из обучающей модели
        train_features = model.feature_names_in_
        
        # Проверяем наличие необходимых признаков
        missing_features = set(train_features) - set(X_user.columns)
        if missing_features:
            print(f"Week {week} is missing features: {missing_features}")
            return None  # Прерываем выполнение, если есть недостающие признаки
        
        # Заполняем отсутствующие признаки значениями по умолчанию
        for feature in train_features:
            if feature not in X_user.columns:
                X_user[feature] = 0
        
        # Убедитесь, что порядок признаков соответствует обучающим данным
        X_user = X_user[train_features]
        
        # Формируем предсказания модели (вероятности)
        y_pred_proba = model.predict_proba(X_user)

        # Предполагаем, что второй столбец содержит вероятность успешного завершения курса
        success_probability = y_pred_proba[0][1] * 100  # Преобразуем в проценты
        
        # Выводим вероятность завершения курса в процентах
        print(f"Вероятность завершения курса для пользователя {user_id} на {week} неделе: {success_probability:.2f}%")
        
        return success_probability  # Возвращаем вероятность завершения курса
    
    except FileNotFoundError as e:
        print(f"File not found: {e}")
    except KeyError as e:
        print(f"KeyError for week {week}: {e}")
    except ValueError as e:
        print(f"ValueError for week {week}: {e}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")


# ## Вводим номер недели и user_id, на выходе получаем результат прогнозирования прогресса по курсу

# In[12]:


# Тестирование на данных
week_number = 7  # Номер недели
user_id_to_predict = 3914  # Замените на нужный user_id

# Вызов функции для предсказания
prediction = predict_for_user(week_number, user_id_to_predict)

