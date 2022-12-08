use library;

-- 1.	Добавить в базу данных информацию о троих новых читателях: «Орлов О.О.», «Соколов С.С.», «Беркутов Б.Б.».
INSERT INTO [dbo].[subscribers] ([s_name])
VALUES (N'Орлов О.О.'),
       (N'Соколов С.С.'),
       (N'Беркутов Б.Б.');

-- 6.	Отметить как невозвращённые все выдачи, полученные читателем с идентификаором 2.
UPDATE [dbo].[subscriptions]
SET [sb_is_active]='Y'
WHERE [sb_subscriber] = 2;

-- 7.	Удалить информацию обо всех выдачах читателям книги с идентификатором 1.
DELETE
FROM [dbo].[subscriptions]
WHERE [sb_book] = 1;

-- 8.	Удалить все книги, относящиеся к жанру «Классика».
DELETE
FROM [dbo].[books]
WHERE [b_id] IN (SELECT [b_id]
                 FROM [dbo].[m2m_books_genres] [m2bg]
                          JOIN [dbo].[genres] g on [g].[g_id] = [m2bg].[g_id]
                 WHERE [g_name] = N'Классика')

-- 10.	Добавить в базу данных жанры «Политика», «Психология», «История».
MERGE INTO [dbo].[genres] [g]
USING (VALUES (N'Политика'),
              (N'Психология'),
              (N'История')) AS [new_genres]([g_name])
ON [g].[g_name] = [new_genres].[g_name]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([g_name])
    VALUES ([new_genres].[g_name]);