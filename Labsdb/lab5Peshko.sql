use library;
GO;
-- 6.	Создать представление, извлекающее информацию о книгах, переводя весь текст в верхний регистр и при этом допускающее модификацию списка книг.
-- DROP VIEW books_upper_case
-- DROP TRIGGER books_upper_case_upd
-- DROP TRIGGER books_upper_case_ins
CREATE VIEW [books_upper_case] WITH SCHEMABINDING AS
SELECT [b_id], UPPER([b_name]) AS [b_name]
FROM [dbo].[books]
CREATE TRIGGER [books_upper_case_ins]
    ON [books_upper_case]
    INSTEAD OF INSERT
    AS
    SET IDENTITY_INSERT [books] ON;
    INSERT INTO [books] ([b_id], [b_name])
    SELECT (IIF([b_id] IS NULL OR [b_id] = 0, IDENT_CURRENT('books') +
                                              IDENT_INCR('books') +
                                              ROW_NUMBER() OVER (ORDER BY (SELECT 1)) -
                                              1, [b_id])) AS [b_id],
           [b_name]
    FROM [inserted];
    SET IDENTITY_INSERT [books] OFF;
GO
CREATE TRIGGER [books_upper_case_upd]
    ON [books_upper_case]
    INSTEAD OF UPDATE AS IF UPDATE([b_id])
    BEGIN
        RAISERROR ('UPDATE of Primary Key through [books_upper_case_upd] view is prohibited.', 16, 1)
        ROLLBACK
    END
ELSE
    UPDATE [books]
    SET [books].[b_name] = [inserted].[b_name]
    FROM [books]
             JOIN [inserted] ON [books].[b_id] = [inserted].[b_id]
GO

-- 10. Модифицировать схему базы данных таким образом, чтобы таблица «authors» хранила актуальную информацию
--   о дате последней выдачи книги автора читателю.
ALTER TABLE [authors]
    ADD [a_last_taken_book_datetime] DATE NULL;
GO
UPDATE [authors]
SET [a_last_taken_book_datetime] = [max_sb_start]
FROM [authors]
         LEFT JOIN
     (SELECT [a_id],
             MAX([sb_start]) [max_sb_start]
      FROM [subscriptions]
               JOIN [m2m_books_authors] ON [subscriptions].[sb_book] = [m2m_books_authors].[b_id]
      GROUP BY [m2m_books_authors].[a_id]) [data] ON
         [authors].[a_id] = [data].[a_id]
GO
-- DROP TRIGGER trigger_taken_books_number_on_subscriptions_ins_upd_del
CREATE TRIGGER trigger_taken_books_number_on_subscriptions_ins_upd_del
    ON [subscriptions]
    AFTER INSERT, UPDATE, DELETE
    AS
    UPDATE [authors]
    SET [a_last_taken_book_datetime] = [max_sb_start]
    FROM [authors]
             LEFT JOIN
         (SELECT [a_id],
                 MAX([sb_start]) [max_sb_start]
          FROM [subscriptions]
                   JOIN [m2m_books_authors] ON [subscriptions].[sb_book] = [m2m_books_authors].[b_id]
          GROUP BY [m2m_books_authors].[a_id]) [data] ON
             [authors].[a_id] = [data].[a_id]
GO;

-- 16.	Создать триггер, корректирующий название книги таким образом, чтобы оно удовлетворяло следующим условиям:
--  a.	не допускается наличие пробелов в начале и конце названия;
--  b.	не допускается наличие повторяющихся пробелов;
--  c.	первая буква в названии всегда должна быть заглавной.
-- DROP TRIGGER trigger_correct_book_name
CREATE TRIGGER [trigger_correct_book_name]
    ON [dbo].[books]
    AFTER INSERT, UPDATE
    AS
    UPDATE [dbo].[books]
    SET b_name=STUFF(replace(replace(replace(TRIM(i.b_name), ' ', '\#$@%^'), '@%^\#$', ''), '\#$@%^', ' '), 1, 1,
                     UPPER(LEFT(TRIM(i.b_name), 1)))
      , [b_year]=i.b_year
      , [b_quantity]=i.b_quantity
    FROM [dbo].[books] b
             JOIN [inserted] i on b.b_id = i.b_id
    ;
GO;
-- 17.	Создать триггер, меняющий дату выдачи книги на текущую, если указанная в
-- INSERT- или UPDATE-запросе дата выдачи книги меньше текущей на полгода и более.
-- DROP TRIGGER trigger_switch_date_now
CREATE TRIGGER [trigger_switch_date_now]
    ON [dbo].[subscriptions]
    AFTER INSERT, UPDATE
    AS
    UPDATE [dbo].[subscriptions]
    SET [sb_start] = IIF(GETDATE() < (DATEADD(month, 6, i.sb_start)), i.sb_start, GETDATE())
    FROM [subscriptions] s
             JOIN [inserted] i on s.sb_id = i.sb_id
    ;
GO;

-- 15.	Создать триггер, допускающий регистрацию в библиотеке только таких авторов,
-- имя которых не содержит никаких символов кроме
-- букв, цифр, знаков - (минус), ' (апостроф) и пробелов (не допускается два и более идущих подряд пробела).
-- DROP TRIGGER trigger_control_author_names
CREATE TRIGGER trigger_control_author_names
    ON [dbo].[authors]
    INSTEAD OF INSERT
    AS
    DECLARE
        @names TABLE
               (
                   name            NVARCHAR(150),
                   is_name_correct bit
               )
    INSERT INTO @names (name, is_name_correct)
    SELECT i.a_name
         , case
               when i.a_name LIKE '%[^а-яА-Яa-ZA-Z0-9\-\ ]%' ESCAPE '\' then 0
               when CHARINDEX('  ', i.a_name) > 0 then 0
               else 1 end
    FROM inserted i
    INSERT INTO [dbo].[authors] (a_name)
    SELECT name
    FROM @names
    WHERE is_name_correct = 1;
    IF (SELECT COUNT(name)
        FROM @names
        WHERE is_name_correct = 0) > 0
        BEGIN
            DECLARE @msg NVARCHAR(max) = 'Some records were NOT inserted!'
            RAISERROR (@msg, 16, 1)
        END;
GO;
