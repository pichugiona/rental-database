-- а) создание и использование хранимой процедуры для иллюстрации присваивания значений переменным;
-- Создаём процедуру
CREATE PROC sp_ГодоваяАренда
  @ID_арендатора INT
AS
BEGIN
-- Объявляем переменные
  DECLARE @месячная_плата MONEY;
  DECLARE @годовая_плата MONEY;
  DECLARE @скидка MONEY;
-- Присваиваем значения
  SET @скидка = 5000;
-- Берём месячную плату из таблицы
  SELECT @месячная_плата = Value
  FROM Contracts
  WHERE CustomerID = @ID_арендатора;
-- Считаем годовую плату
  SET @годовая_плата = (@месячная_плата * 12)- @скидка;
-- Выводим результат
  SELECT @годовая_плата AS ГодоваяАренда;
END;
GO
-- Запускаем процедуру
EXEC sp_ГодоваяАренда @ID_арендатора = 1;
GO


-- в) создание и использование хранимой функции COMPUTE_DISCOUNTS для иллюстрации возможностей оператора IF;
-- Создаём функцию
CREATE FUNCTION fn_Скидка (@сумма MONEY)
RETURNS MONEY
AS
BEGIN
  DECLARE @скидка MONEY;
-- Оператор IF
  IF @сумма > 100000
    SET @скидка = @сумма * 0.15; -- 15% скидки
  ELSE IF @сумма > 50000
    SET @скидка = @сумма * 0.10; -- 10% скидки
  ELSE IF @сумма > 30000
    SET @скидка = @сумма * 0.05; -- 5% скидки
  ELSE
    SET @скидка = 0;
    
  RETURN @скидка;
END;
GO
-- Используем функцию
SELECT
  TreatyID AS НомерДоговора,
  Value AS Сумма,
  dbo.fn_Скидка(Value) AS Скидка,
  Value - dbo.fn_Скидка(Value) AS ИтогоПослеСкидки
FROM Contracts;
GO


-- г) блоки, иллюстрирующие использование операторов цикла LOOP, WHILE, FOR;
-- Цикл WHILE (простой)
DECLARE @i INT = 1;
DECLARE @output NVARCHAR(MAX) = '';
WHILE @i <= 5
BEGIN
  SET @output = @output + 'WHILE итерация: ' + CAST(@i AS VARCHAR) + CHAR(13);
  SET @i = @i + 1;
END;

SELECT @output AS Сообщение;
GO
-- Цикл WHILE с BREAK (выход при 3)
DECLARE @j INT = 1;
DECLARE @out2 NVARCHAR(MAX) = '';
WHILE @j <= 5
BEGIN
  IF @j = 3
    BREAK;
  SET @out2 = @out2 + 'BREAK итерация: ' + CAST(@j AS VARCHAR) + CHAR(13);
  SET @j = @j + 1;
END;
SELECT @out2 AS Сообщение;
GO
-- Цикл WHILE с CONTINUE (пропуск чётных)
DECLARE @k INT = 0;
DECLARE @out3 NVARCHAR(MAX) = '';
WHILE @k < 5
BEGIN
  SET @k = @k + 1;
  IF @k % 2 = 0
    CONTINUE;
  SET @out3 = @out3 + 'Нечётное: ' + CAST(@k AS VARCHAR) + CHAR(13);
END;
SELECT @out3 AS Сообщение;
GO


-- д) использование курсора для снижения цены товара на 3% в таблице PRODUCT;
-- Объявляем переменные
DECLARE @id_договора INT;
DECLARE @старая_цена MONEY;
-- Объявляем курсор
DECLARE курсор_договоров CURSOR FOR
SELECT TreatyID, Value FROM Contracts WHERE Type = 1;
-- Открываем курсор
OPEN курсор_договоров;
-- Читаем первую запись
FETCH NEXT FROM курсор_договоров INTO @id_договора, @старая_цена;
-- Цикл по всем записям
WHILE @@FETCH_STATUS = 0
BEGIN
-- Снижаем цену на 3%
UPDATE Contracts
SET Value = @старая_цена * 0.97
WHERE TreatyID = @id_договора;
-- Читаем следующую запись
FETCH NEXT FROM курсор_договоров INTO @id_договора, @старая_цена;
END;
-- Закрываем и удаляем курсор
CLOSE курсор_договоров;
DEALLOCATE курсор_договоров;
-- Смотрим результат
SELECT TreatyID, Value FROM Contracts WHERE Type = 1;
GO


-- е) создание и использование хранимой процедуры DO_COMMISSIONS для иллюстрации использования вложенных циклов и курсоров;
CREATE PROC sp_РасчетКомиссионных
AS
BEGIN
--Переменные для внешнего цикла (арендаторы)
DECLARE @id_арендатора INT;
DECLARE @тип_арендатора BIT;
--Переменные для внутреннего цикла (договоры)
DECLARE @id_договора INT;
DECLARE @сумма MONEY;
DECLARE @комиссия MONEY;
-- Внешний курсор по арендаторам
DECLARE курсор_арендаторов CURSOR FOR
SELECT CustomerID, CustomerType FROM Tenants;
OPEN курсор_арендаторов;
FETCH NEXT FROM курсор_арендаторов INTO @id_арендатора, @тип_арендатора;
WHILE @@FETCH_STATUS = 0
BEGIN
-- Внутренний курсор по договорам арендатора
DECLARE курсор_договоров CURSOR FOR
SELECT TreatyID, Value FROM Contracts
WHERE CustomerID = @id_арендатора AND Type = 1;
OPEN курсор_договоров;
FETCH NEXT FROM курсор_договоров INTO @id_договора, @сумма;
WHILE @@FETCH_STATUS = 0
-- Расчёт комиссии (разная для юр и физ лиц)
IF @тип_арендатора = 1 -- юридическое лицо
  SET @комиссия = @сумма * 0.05;
ELSE -- физическое лицо
  SET @комиссия = @сумма * 0.03;
-- Выводим результат
SELECT @id_арендатора AS ID_арендатора, @id_договора AS ID_договора, @комиссия AS Комиссия;
FETCH NEXT FROM курсор_договоров INTO @id_договора, @сумма;
END;
CLOSE курсор_договоров;
DEALLOCATE курсор_договоров;
FETCH NEXT FROM курсор_арендаторов INTO @id_арендатора, @тип_арендатора;
END;
CLOSE курсор_арендаторов;
DEALLOCATE курсор_арендаторов;
END;
GO
-- Запускаем
EXEC sp_РасчетКомиссионных;
GO


-- и) объявление и использование записей, динамических типов и курсоров для расчета эффективности работы продавца;
-- Создаём таблицы
CREATE TABLE #Продавцы (ID INT, Имя NVARCHAR(50));
CREATE TABLE #Продажи (ПродавецID INT, Сумма MONEY);
INSERT INTO #Продавцы VALUES (1, 'Иванов'), (2, 'Петров'), (3, 'Сидоров');
INSERT INTO #Продажи VALUES (1, 50000), (1, 30000), (2, 20000), (2, 25000), (2,
15000), (3, 10000);
-- Курсор для расчёта эффективности
DECLARE @id INT, @имя NVARCHAR(50), @сумма MONEY, @колво INT;
DECLARE курс CURSOR FOR SELECT ID, Имя FROM #Продавцы;
OPEN курс;
FETCH NEXT FROM курс INTO @id, @имя;
WHILE @@FETCH_STATUS = 0
BEGIN
  SELECT @сумма = SUM(Сумма), @колво = COUNT(*) FROM #Продажи WHERE ПродавецID = @id;
  SELECT @имя AS Продавец, @сумма AS ОбщаяСумма, @колво AS КолвоПродаж, @сумма/@колво AS Эффективность;
FETCH NEXT FROM курс INTO @id, @имя;
END;
CLOSE курс;
DEALLOCATE курс;
DROP TABLE #Продавцы;
DROP TABLE #Продажи;
GO


-- к) использование неявных курсоров в программах, добавляющих, обновляющих и удаляющих строки таблиц учебной базы данных;
-- При INSERT срабатывает неявный курсор
INSERT INTO Tenants (CustomerID, Phone, CustomerType)
VALUES (3000, '+79990000000', 1);
-- Проверяем @@ROWCOUNT (количество затронутых строк)
IF @@ROWCOUNT > 0
SELECT 'Добавлено строк: ' + CAST(@@ROWCOUNT AS VARCHAR) AS Результат;
GO
-- При UPDATE тоже срабатывает неявный курсор
UPDATE Contracts SET Value = Value * 1.05 WHERE Value < 40000;
SELECT 'Обновлено строк: ' + CAST(@@ROWCOUNT AS VARCHAR) AS Результат;
GO
-- При DELETE тоже
DELETE FROM Tenants WHERE CustomerID = 3000;
SELECT 'Удалено строк: ' + CAST(@@ROWCOUNT AS VARCHAR) AS Результат;
GO
-- Неявный курсор для SELECT INTO
SELECT TreatyID, Value INTO #временная_таблица FROM Contracts WHERE Value > 50000;
SELECT 'Создано строк во временной таблице: ' + CAST(@@ROWCOUNT AS VARCHAR) AS Результат;
DROP TABLE #временная_таблица;
GO

-- л) измерение времени выполнения программы;
DECLARE @время_старта DATETIME;
DECLARE @время_конца DATETIME;
SET @время_старта = GETDATE();
-- Действие, время которого измеряем
WAITFOR DELAY '00:00:02';
SET @время_конца = GETDATE();
SELECT
  @время_старта AS ВремяСтарта,
  @время_конца AS ВремяОкончания,
  DATEDIFF(MILLISECOND, @время_старта, @время_конца) AS ВремяВ_мс;
GO


-- н) создание триггера, записывающего номера заказов в таблицу покупок PURCHASE учебной базы данных и аудиторские сведения в таблицу AUDIT_TAB.
-- Создаём учебные таблицы
CREATE TABLE PURCHASE (
  OrderID INT PRIMARY KEY,
  ProductName NVARCHAR(50),
  Amount MONEY
);
GO
CREATE TABLE AUDIT_TAB (
  AuditID INT IDENTITY(1,1) PRIMARY KEY,
  OrderID INT,
  ActionType NVARCHAR(10),
  ActionDate DATETIME DEFAULT GETDATE(),
  UserName NVARCHAR(50) DEFAULT SUSER_NAME()
);
GO
-- Создаём триггер (должен быть первым в своём пакете)
CREATE TRIGGER trg_PURCHASE_Audit
ON PURCHASE
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
-- При вставке
  IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
  BEGIN
    INSERT INTO AUDIT_TAB (OrderID, ActionType)
    SELECT OrderID, 'INSERT' FROM inserted;
  END
-- При удалении
  IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
  BEGIN
    INSERT INTO AUDIT_TAB (OrderID, ActionType)
    SELECT OrderID, 'DELETE' FROM deleted;
  END
-- При обновлении
  IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
  BEGIN
    INSERT INTO AUDIT_TAB (OrderID, ActionType)
    SELECT OrderID, 'UPDATE' FROM inserted;
  END
END;
GO
-- Вставляем данные
INSERT INTO PURCHASE VALUES (1, 'Ноутбук', 50000);
INSERT INTO PURCHASE VALUES (2, 'Мышь', 1000);
GO
-- Обновляем
UPDATE PURCHASE SET Amount = 1200 WHERE OrderID = 2;
GO
-- Удаляем
DELETE FROM PURCHASE WHERE OrderID = 1;
GO
-- Смотрим результаты
SELECT * FROM PURCHASE;
SELECT * FROM AUDIT_TAB;
GO
