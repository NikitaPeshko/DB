use library;
-- 1.	Создать хранимую процедуру, которая:
-- a.	добавляет каждой книге два случайных жанра;
-- b.	отменяет совершённые действия, если в процессе работы хотя бы одна операция вставки завершилась
--      ошибкой в силу дублирования значения первичного ключа таблицы «m2m_books_genres»
--      (т.е. у такой книги уже был такой жанр).
-- DROP PROCEDURE [dbo].[sp_AddTwoRandomGenresForEachBook]
CREATE PROCEDURE [dbo].[sp_AddTwoRandomGenresForEachBook]
AS
BEGIN
    DECLARE @b_id_value INT
    DECLARE @genres_count INT = (SELECT count(g_id) FROM genres)
    DECLARE books_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT b_id FROM books
    Begin Try
        SET NOCOUNT ON
        Set XACT_ABORT ON
        Begin Tran
            OPEN books_cursor
            FETCH NEXT FROM books_cursor INTO @b_id_value
            WHILE @@FETCH_STATUS = 0
                BEGIN

                    INSERT INTO m2m_books_genres (b_id, g_id)
                    VALUES (@b_id_value, (SELECT g_id
                                          FROM genres
                                          ORDER BY g_id
                                          OFFSET (CAST((RAND() * ((@genres_count) - 1) + 1) AS INT)) ROWS FETCH NEXT 1 ROWS ONLY)),
                           (@b_id_value, (SELECT g_id
                                          FROM genres
                                          ORDER BY g_id
                                          OFFSET (CAST((RAND() * ((@genres_count) - 1) + 1) AS INT)) ROWS FETCH NEXT 1 ROWS ONLY))
                    FETCH NEXT FROM books_cursor INTO @b_id_value
                END
            PRINT 'We did it!'
        Commit Tran
    End Try
    Begin Catch
        RollBack;
        PRINT 'Couldn''t add genres'
    End Catch
END
go;

-- 2.	Создать хранимую процедуру, которая:
-- a.	увеличивает значение поля «b_quantity» для всех книг в два раза;
-- b.	отменяет совершённое действие, если по итогу выполнения операции
--      среднее количество экземпляров книг превысит значение 50.
-- DROP PROCEDURE [dbo].[sp_doubleUpBookQuantity]
CREATE PROCEDURE [dbo].[sp_doubleUpBookQuantity]
AS
BEGIN
    DECLARE @avg_books_quantity float
    BEGIN TRANSACTION
        UPDATE books
        SET b_quantity = b_quantity * 2
        SET @avg_books_quantity = (SELECT AVG(b_quantity) FROM books)
        IF (@avg_books_quantity > 50)
            BEGIN
                PRINT 'I guess it''s already a lot... [' + CAST(@avg_books_quantity AS VARCHAR) + ']'
                ROLLBACK
            END
        ELSE
            BEGIN
                PRINT 'OK, you can keep adding...[' + CAST(@avg_books_quantity AS VARCHAR) + ']'
                COMMIT
            END
END
go;

-- 5.	Написать код, в котором запрос, инвертирующий значения поля «sb_is_active» таблицы «subscriptions» с «Y» на «N»
-- и наоборот, будет иметь максимальные шансы на успешное завершение в случае возникновения ситуации взаимной блокировки
-- с другими транзакциями.
SET IMPLICIT_TRANSACTIONS ON
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
SET DEADLOCK_PRIORITY HIGH
BEGIN TRANSACTION
UPDATE subscriptions
SET sb_is_active = IIF(sb_is_active = 'Y', 'N', 'Y')
COMMIT
go;

-- 6.	Создать на таблице «subscriptions» триггер, определяющий уровень изолированности транзакции,
-- в котором сейчас проходит операция обновления, и отменяющий операцию, если уровень изолированности транзакции
-- отличен от REPEATABLE READ.
-- DROP TRIGGER [dbo].[update_subscriptions_isolation_level_check]
CREATE TRIGGER [dbo].[update_subscriptions_isolation_level_check]
    ON [subscriptions]
    AFTER UPDATE
    AS
BEGIN
    DECLARE @isolation_level NVARCHAR(50);
    SET @isolation_level =
            (SELECT [transaction_isolation_level] FROM [sys].[dm_exec_sessions] WHERE [session_id] = @@SPID);
    IF (@isolation_level != 3)
        BEGIN
            RAISERROR ('Please, switch your transaction to REPEATABLE READ isolation level and rerun this UPDATE again.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN
        END;
END

go;
-- 8.	Создать хранимую процедуру, выполняющую подсчёт количества записей
-- в указанной таблице таким образом, чтобы она возвращала максимально корректные данные,
-- даже если для достижения этого результата придётся пожертвовать производительностью.
-- DROP PROCEDURE [dbo].[sp_countRowsInTable]
CREATE PROCEDURE [dbo].[sp_countRowsInTable] @table_name NVARCHAR(MAX)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
    BEGIN TRANSACTION
        DECLARE @query NVARCHAR(MAX) = CONCAT('SELECT count(*) FROM [dbo].[', @table_name, ']')
        EXEC sp_sqlexec @query
    COMMIT
END
go;
-- EXEC [dbo].[sp_countRowsInTable] 'genres'
-- EXEC [dbo].[sp_countRowsInTable] 'books'
-- EXEC [dbo].[sp_countRowsInTable] 'authors'