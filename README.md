# practLua
Простой пример, как можно работать с таблицами в MySQL на Lua

Внешний вид сайта:

![image](https://user-images.githubusercontent.com/10297748/232950423-90909530-7056-49cf-ae42-b8cfafbdf7c8.png)

Пример не требует Apache. Достаточно базовых компонентов, которые есть в LuaForWindows_v5.1.4-46.exe (https://code.google.com/archive/p/luaforwindows/). Для работы с базой данных test необходимо экспортировать таблицы из файла import_test.sql в каталоге с исходниками.

Для запуска сервера на lua (на модуле socket с luasql), нужно запустить файл serv.bat и открыть страницу: http://localhost:8880/
