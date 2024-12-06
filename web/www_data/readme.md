# Административная часть проекта EduTech

## Точка входа

Адрес ``/admin`` при входе запрашивается логин и пароль, если удалить все записи из таблицы users то при первом входе создается пользователь с указанным логином и паролем.

В административном интерфейсе реализована система разграничения прав пользователей, можно указывать к каким страницам имеет доступ пользователь. Основные страницы для пользователя главная и обучающиеся. На странице обучающиеся заблокирован доступ к пользователю по выбору строки.

Все данные выбираются из таблиц базы данных PostgreSQL, работа python скриптов сохраняет результаты в таблицы PostgreSQL.

В системе реализована проверка работы получения данных.

Для полноценной работы необходимо настроить cron на обработку данных о пользователях (см. python/progon_users_v4.py)