use library;
-- 1.	Создать хранимую функцию, получающую на вход идентификатор читателя и возвращающую
-- список идентификаторов книг, которые он уже прочитал и вернул в библиотеку.
-- DROP FUNCTION [dbo].[ufn_getReturnedBooksIdBySubscriberId]
CREATE FUNCTION [dbo].[ufn_getReturnedBooksIdBySubscriberId](@id INT)
    RETURNS @return_table TABLE
                          (
                              book_id INT
                          )
AS
BEGIN
    DECLARE @subscriber_id INT = @id

    INSERT INTO @return_table
    SELECT sb_book [book_id]
    FROM [dbo].[subscriptions] s
    WHERE s.sb_subscriber = @subscriber_id
      and s.sb_is_active = 'N'

    RETURN
END

-- 2.	Создать хранимую функцию, возвращающую список первого диапазона свободных значений
-- автоинкрементируемых первичных ключей в указанной таблице (например, если в таблице есть
-- первичные ключи 1, 4, 8, то первый свободный диапазон — это значения 2 и 3).
-- MS SQL SERVER не поддерживает динамические SQL запросы внутри хранимых функций,
-- поэтому была выбрана конкретная таблица - books
-- DROP FUNCTION [dbo].[ufn_getFreeKeysInBooks]
CREATE FUNCTION [dbo].[ufn_getFreeKeysInBooks]()
    RETURNS @free_keys TABLE
                       (
                           [start] INT,
                           [stop]  INT
                       ) AS
BEGIN
    INSERT @free_keys
    SELECT [start], [stop]
    FROM (SELECT [min_t].[b_id] + 1                                                                [start],
                 (SELECT MIN([b_id]) - 1 FROM [dbo].[books] [x] WHERE [x].[b_id] > [min_t].[b_id]) [stop]
          FROM [dbo].[books] [min_t]
          UNION
          SELECT 1                                                                [start],
                 (SELECT MIN([b_id]) - 1 FROM [dbo].[books] [x] WHERE [b_id] > 0) [stop]) [data]
    WHERE [stop] >= [start]
    ORDER BY [start], [stop]
    RETURN
END;

-- 3.	Создать хранимую функцию, получающую на вход идентификатор читателя и возвращающую 1,
-- если у читателя на руках сейчас менее десяти книг, и 0 в противном случае.
-- DROP FUNCTION [dbo].[ufn_isSubscriberHaveMoreThan10Books]
CREATE FUNCTION [dbo].[ufn_isSubscriberHaveMoreThan10Books](@id INT)
    RETURNS BIT
AS
BEGIN
    DECLARE @subscriber_id INT = @id
    RETURN (
        SELECT IIF(count(s.sb_book) > 1, 1, 0) [result]
        FROM [dbo].[subscriptions] [s]
        WHERE s.sb_subscriber = @subscriber_id
          and s.sb_is_active = 'Y'
    )
END

-- 4.	Создать хранимую функцию, получающую на вход год издания книги и возвращающую 1,
-- если книга издана менее ста лет назад, и 0 в противном случае.
-- DROP FUNCTION [dbo].[ufn_isBookPublishedEarlierThan100Years]
CREATE FUNCTION [dbo].[ufn_isBookPublishedEarlierThan100Years](@year INT)
    RETURNS BIT
AS
BEGIN
    DECLARE @publish_year INT = @year
    RETURN (
        IIF(DATEPART(YEAR, GETDATE()) - @publish_year > 100, 1, 0)
        )
END

-- 5.	Создать хранимую процедуру, обновляющую все поля типа DATE (если такие есть)
-- всех записей указанной таблицы на значение текущей даты.
-- DROP PROCEDURE [dbo].[sp_updateDateColumns]
CREATE PROCEDURE [dbo].[sp_updateDateColumns] @nameTable NVARCHAR(MAX)
AS
BEGIN
    DECLARE @table_name NVARCHAR(MAX) = @nameTable
    DECLARE @column NVARCHAR(MAX);
    DECLARE @isCommaSet BIT = 0;
    DECLARE @column_names TABLE
                          (
                              name NVARCHAR(max)
                          )
    INSERT INTO @column_names
    SELECT COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @table_name
      and DATA_TYPE = 'date'

    IF ((SELECT count(name) FROM @column_names) = 0)
        BEGIN
            DECLARE @error_message NVARCHAR(max) = 'Records with the date type were not found'
            RAISERROR (@error_message, 16, 1);
        END

    DECLARE @update_query NVARCHAR(max) = CONCAT('UPDATE ', @table_name, ' SET ')
    DECLARE db_cursor CURSOR FOR
        SELECT name FROM @column_names
    OPEN db_cursor
    FETCH NEXT FROM db_cursor INTO @column
    WHILE @@FETCH_STATUS = 0
        BEGIN
            IF (@isCommaSet = 1)
                BEGIN
                    SET @update_query = CONCAT(@update_query, ', ')
                END
            SET @isCommaSet = 1
            SET @update_query = CONCAT(@update_query, ' ', @column, '= ''', convert(varchar, getdate(), 23), '''')
            FETCH NEXT FROM db_cursor INTO @column
        END
    EXECUTE sp_sqlexec @update_query
    CLOSE db_cursor
    DEALLOCATE db_cursor
END;