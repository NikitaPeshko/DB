USE library

-- 5.	Показать, сколько всего читателей зарегистрировано в библиотеке.
SELECT COUNT([s_id]) [Number of readers]
FROM [dbo].[subscribers];

-- 6.	Показать, сколько всего раз читателям выдавались книги.
SELECT COUNT(sb_id) [Number of issues of books]
FROM [dbo].[subscriptions];

-- 12.	Показать идентификатор одного (любого) читателя, взявшего в библиотеке больше всего книг.
SELECT TOP (1) [sb_subscriber]
FROM [dbo].[subscriptions]
GROUP BY sb_subscriber
ORDER BY COUNT([sb_subscriber]) DESC;


-- 15.	Показать, сколько в среднем экземпляров книг есть в библиотеке(всего числиться)
SELECT AVG(CAST(b_quantity as float)) [number of books]
FROM [dbo].[books];

-- 17.	Показать, сколько книг было возвращено и не возвращено в библиотеку (СУБД должна оперировать
-- исходными значениями поля sb_is_active (т.е. «Y» и «N»), а после подсчёта
-- значения «Y» и «N» должны быть преобразованы в «Returned» и «Not returned»).
SELECT (IIF([sb_is_active] = 'Y', 'Not returned', 'Returned')) [status]
       ,COUNT([sb_id])                                          [books]
FROM [dbo].[subscriptions]
GROUP BY (IIF([sb_is_active] = 'Y', 'Not returned', 'Returned'))
ORDER BY [status] DESC;