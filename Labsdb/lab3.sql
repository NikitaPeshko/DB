USE library;

-- 6.	Показать список книг, которые никто из читателей никогда не брал.
SELECT [b_name] [Title]
FROM [dbo].[books] [b]
         LEFT JOIN [dbo].[subscriptions] [s] ON [b].[b_id] = [s].[sb_book]
GROUP BY [b_name]
HAVING count([sb_id]) = 0;

-- 11.	Показать книги, относящиеся к более чем одному жанру.
SELECT [b_name] [Title]
FROM [dbo].[m2m_books_genres] [mbg]
         JOIN [dbo].[books] [b] on [b].[b_id] = [mbg].[b_id]
GROUP BY [b].[b_name]
HAVING count([g_id]) > 1;

-- 15.	Показать всех авторов и количество книг (не экземпляров книг, а «книг как изданий») по каждому автору.
WITH [AuthorsBooks] ([count], [a_id]) AS (
    SELECT count([b_id]) [count]
         , [a_id]
    FROM [m2m_books_authors]
    GROUP BY [a_id]
)
SELECT [a_name] [Author]
     , [count]  [Number of books]
FROM [AuthorsBooks] [ab]
         JOIN [dbo].[authors] [a] on [ab].[a_id] = [a].[a_id];

-- 19.	Показать среднюю читаемость жанров, т.е. среднее значение от того, сколько раз читатели брали книги каждого жанра.
SELECT AVG(CAST([books] AS FLOAT)) [Average reading]
FROM (SELECT COUNT([sb_book]) [books]
      FROM [dbo].[genres] [g]
               JOIN [dbo].[m2m_books_genres] [mbg] ON [g].[g_id] = [mbg].[g_id]
               LEFT JOIN [dbo].[subscriptions] [s] ON [mbg].[b_id] = [s].[sb_book]
      GROUP BY [g].[g_id]) [prepared_data];

-- 23.	Показать читателя, последним взявшего в библиотеке книгу.
SELECT TOP (1) [subscribers].[s_name] [Name]
FROM [dbo].[subscriptions]
         JOIN [dbo].[subscribers] ON [subscriptions].[sb_subscriber] = [subscribers].[s_id]
ORDER BY [sb_start] DESC