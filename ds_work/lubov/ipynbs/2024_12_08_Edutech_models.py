#!/usr/bin/env python
# coding: utf-8

# In[1]:


import pandas as pd
import numpy as np
import math
import joblib
import dill as pickle
import requests
import json
import warnings

from matplotlib import pyplot as plt

import seaborn as sns

from sklearn.base import TransformerMixin, BaseEstimator
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression, LogisticRegressionCV
from sklearn.metrics import mean_absolute_error, classification_report, confusion_matrix, accuracy_score, roc_auc_score
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from sqlalchemy import create_engine

from tqdm import tqdm

from MarkovChain import MarkovChain

sns.set()

pd.options.display.float_format = '{:.4f}'.format


# In[2]:


# параметры подключения
username = '%user%'
password = '%password%'
host = '%host%'
port = '%port%'
database = '%database%'

# Создание строки подключения
connection_string = f'postgresql://{username}:{password}@{host}:{port}/{database}'

# Создание подключения к PostgreSQL с использованием sqlalchemy
engine = create_engine(connection_string)

# Загрузка таблицы в DataFrame
table_name = 'ds_gavrilova'  # Укажите имя таблицы
df = pd.read_sql_table(table_name, engine)

# Вывод DataFrame на экран
df.head(10)


# In[3]:


df.info()


# # Построение модели определения вероятности завершения курса

# In[4]:


# отделяем признаки от целевой переменной
features = df.drop(['user_id', 'cur_date', 'target'], axis=1)
target = df['target']


# In[5]:


# разделение данных на обучающую и тестовую выборки
X_train, X_val, y_train, y_val = train_test_split(features, target, test_size=0.4, random_state=12)
X_val, X_test, y_val, y_test = train_test_split(X_val, y_val, test_size=0.2, random_state=12)


# In[6]:


# класс для работы с выбросами
class GetRidOfEmissions(TransformerMixin, BaseEstimator):

    def __init__(self):
        pass

    def fit(self, X, y=None):
        return self

    def transform(self, X):
        for col in ['view_rate', 'view_required_rate', 'view_optional_rate', 'view_attestation_rate', 'progress',
            'exercise_rate', 'exercise_required_rate', 'exercise_optional_rate', 'exercise_attestation_rate']:
            X[col] = X[col].apply(lambda x: x if x <= 100 else 100)
        return X


# In[7]:


# конвейер
pipe = Pipeline([ 
    ('emissions', GetRidOfEmissions()), # работа с выросами
    ('imputer', SimpleImputer(strategy='median')),  # заполнение пропусков
    ('scaler', StandardScaler()),  # нормализация признаков
    ('classify', RandomForestClassifier(class_weight='balanced', random_state=12))
])


# In[8]:


pipe.fit(X=X_train, y=y_train)
print('Качество модели на обучающей выборке:', {roc_auc_score(y_train, pipe.predict_proba(X_train)[:, 1])})

print('Качество модели на валидационной выборке:', {roc_auc_score(y_val, pipe.predict_proba(X_val)[:, 1])})

print('Качество модели на тестовой выборке:', {roc_auc_score(y_test, pipe.predict_proba(X_test)[:, 1])})


# In[9]:


# сериализация модели
with open('models/successful_attestation_probability_model.pk', 'wb') as file:
    pickle.dump(pipe, file)


# In[10]:


# проверка правильности загрузки модели
with open('models/successful_attestation_probability_model.pk','rb') as f:
    loaded_model = pickle.load(f)
    
print(
    'Качество модели на тестовой выборке от законсервированной модели:', 
    {roc_auc_score(y_test, loaded_model.predict_proba(X_test)[:, 1])}
)


# # Определение количества классов учащихся и распределения значений основных метрик согласно определенным классам

# In[11]:


# предобработка
# работа с выбросами
for col in ['view_rate', 'view_required_rate', 'view_optional_rate', 'view_attestation_rate', 'progress',
            'exercise_rate', 'exercise_required_rate', 'exercise_optional_rate', 'exercise_attestation_rate']:
    features[col] = features[col].apply(lambda x: x if x <= 100 else 100)

# заполнение пропусков
features.fillna({'age': features['age'].describe()['50%']}, inplace=True)
features.fillna({'time_zone': features['time_zone'].value_counts().idxmax()}, inplace=True)


# In[12]:


# масштабирование признаков
scaler = StandardScaler()
features_norm = scaler.fit_transform(features.values)


# In[13]:


# определение кластеров
model = KMeans(3, random_state=12)
clusters = model.fit_predict(features_norm)

print("Центроиды кластеров:")
print(model.cluster_centers_)


# In[14]:


df['cluster'] = clusters.tolist()


# In[15]:


df_clusters = df.pivot_table(values=['cluster'], index=['user_id'], columns=['cur_date']).sample(20)
df_clusters


# In[16]:


metrics_descr_0 = df[df['cluster'] == 0][features.columns].describe().T
metrics_descr_1 = df[df['cluster'] == 1][features.columns].describe().T
metrics_descr_2 = df[df['cluster'] == 2][features.columns].describe().T

clusters_metrics_descr = pd.concat([metrics_descr_0, metrics_descr_1, metrics_descr_2], axis=1)
clusters_metrics_descr.head(60)

# clusters_metrics_descr.to_excel('2024_11_12_clusters_metrics.xlsx')


# # Построение модели определения класса учащегося

# In[17]:


# определение целевой переменной
target = df['cluster'].astype('category')


# In[18]:


# разделение данных на обучающую и тестовую выборки
X_train, X_val, y_train, y_val = train_test_split(features, target, test_size=0.4, random_state=12)
X_val, X_test, y_val, y_test = train_test_split(X_val, y_val, test_size=0.2, random_state=12)


# In[19]:


# конвейер
pipe_cluster = Pipeline([ 
    ('emissions', GetRidOfEmissions()), # работа с выросами
    ('imputer', SimpleImputer(strategy='median')),  # заполнение пропусков
    ('scaler', StandardScaler()),  # нормализация признаков
    ('classify', LogisticRegression(max_iter=300, class_weight='balanced', random_state=12))
])


# In[20]:


pipe_cluster.fit(X=X_train, y=y_train)
print('Качество модели на обучающей выборке:',\
      {roc_auc_score(pd.get_dummies(y_train), pd.get_dummies(pipe_cluster.predict(X_train)), average='macro', multi_class='ovr')})

print('Качество модели на валидационной выборке:',\
      {roc_auc_score(pd.get_dummies(y_val), pd.get_dummies(pipe_cluster.predict(X_val)), average='macro', multi_class='ovr')})

print('Качество модели на тестовой выборке:',\
      {roc_auc_score(pd.get_dummies(y_test), pd.get_dummies(pipe_cluster.predict(X_test)), average='macro', multi_class='ovr')})


# In[21]:


# сериализация модели
with open('models/current_cluster_model.pk', 'wb') as file:
    pickle.dump(pipe_cluster, file)


# In[22]:


# проверка правильности загрузки модели
with open('models/current_cluster_model.pk','rb') as f:
    loaded_model = pickle.load(f)
    
print(
    'Качество модели на тестовой выборке от законсервированной модели:', 
    {roc_auc_score(pd.get_dummies(y_test), pd.get_dummies(loaded_model.predict(X_test)), average='macro', multi_class='ovr')}
)

