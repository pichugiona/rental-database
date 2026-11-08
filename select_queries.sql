-- (а) Добавление строк с текущей датой и датой двухнедельной давности (добавляют в таблицу, содержащую поля с датами, две строки для сохранения текущей даты и даты двухнедельной давности. Если в базе данных нет таблицы с такими полями, то запрограммировать вывод этих дат оператором SELECT для таблицы DUAL)
-- Добавляем два новых договора с текущей датой и датой двухнедельной давности
INSERT INTO Contracts VALUES
(2001, 1, 101, 1, GETDATE(), DATEADD(day, 365, GETDATE()), N'ежемес.', 50000, N'Иванов И.И.', N'офис', 5000),
(2002, 2, 102, 1, DATEADD(day, -14, GETDATE()), DATEADD(day, 365, DATEADD(day, - 14, GETDATE())), N'ежемес.', 35000, N'Петров П.П.', N'магазин', 3000);
-- Проверка добавленных строк
SELECT TreatyID, DateStart, DateStop
FROM Contracts
WHERE TreatyID IN (2001, 2002);
GO


-- (б) Добавление строк с именем пользователя и именем компьютера (добавляют в таблицу две строки, содержащие текстовое поле: (1) с именем пользователя-студента и (2) именем компьютера, за которым работает студент)
-- Добавляем в таблицу Tenants нового арендатора с системными данными
INSERT INTO Tenants VALUES
(100, 0, USER_NAME(), NULL, NULL, NULL, N'+70000000000', N'Системный
пользователь', NULL, N'Центральный', USER_NAME(), N'+70000000001'),
(101, 0, HOST_NAME(), NULL, NULL, NULL, N'+70000000002', N'Компьютер
пользователя', NULL, N'Центральный', HOST_NAME(), N'+70000000003');
-- Проверка
SELECT CustomerID, CustomerFio, Worker FROM Tenants WHERE CustomerID IN (100, 101);
GO


-- (г) Преобразование регистра текста (выбирают из таблицы значения одного из полей текстового типа, содержащего несколько слов, чтобы (1) все слова выводились только прописными буквами, (2) все слова выводились только строчными буквами, (3) каждое слово выводилось строчными буквами, но начиналось прописной буквой)
-- Выбираем названия арендаторов (юр.лица) в разных регистрах
SELECT
  CustomerName AS ИсходноеНазвание,
  UPPER(CustomerName) AS ВсеПрописные,
  LOWER(CustomerName) AS ВсеСтрочные,
-- Каждое слово с заглавной буквы (упрощённый вариант)
  UPPER(LEFT(CustomerName, 1)) + LOWER(SUBSTRING(CustomerName, 2,
LEN(CustomerName))) AS ПерваяЗаглавнаяОстальныеСтрочные
FROM Tenants
WHERE CustomerName IS NOT NULL;
GO


-- (д) Минимальная, максимальная и средняя длина текста (определяют минимальную, максимальную и среднюю длину текста в одном из табличных полей текстового типа. Для столбцов задать псевдонимы, отражающие смысл содержимого столбцов)
SELECT
  MIN(LEN(CustomerFio)) AS МинимальнаяДлинаФИО,
  MAX(LEN(CustomerFio)) AS МаксимальнаяДлинаФИО,
  AVG(CAST(LEN(CustomerFio) AS FLOAT)) AS СредняяДлинаФИО
FROM Tenants
WHERE CustomerFio IS NOT NULL;
-- Для поля CustomerName (юридические лица)
SELECT
  MIN(LEN(CustomerName)) AS МинимальнаяДлинаНазвания,
  MAX(LEN(CustomerName)) AS МаксимальнаяДлинаНазвания,
  AVG(CAST(LEN(CustomerName) AS FLOAT)) AS СредняяДлинаНазвания
FROM Tenants
WHERE CustomerName IS NOT NULL;
GO


-- (е) Разделение строки на отдельные слова (выбирают из таблицы текстовый столбец, содержащий последовательности слов, разделенных пробелами, (например, ФИО, полные названия изделий и т.п.) и формируют отдельные столбцы для каждого слова (например, Фамилия, Имя, Отчество). Для сформированных столбцов задать псевдонимы)
SELECT
  CustomerFio AS ПолноеФИО,
  -- Фамилия (до первого пробела)
  CASE
    WHEN CHARINDEX(' ', CustomerFio) > 0
    THEN LEFT(CustomerFio, CHARINDEX(' ', CustomerFio) - 1)
    ELSE CustomerFio
  END AS Фамилия,
-- Имя (между первым и вторым пробелом)
  CASE
    WHEN CHARINDEX(' ', CustomerFio) > 0
      AND CHARINDEX(' ', CustomerFio, CHARINDEX(' ', CustomerFio) + 1) > 0
    THEN SUBSTRING(
      CustomerFio,
      CHARINDEX(' ', CustomerFio) + 1,
      CHARINDEX(' ', CustomerFio, CHARINDEX(' ', CustomerFio) + 1) - CHARINDEX(' ', CustomerFio) - 1
    )
    ELSE ''
  END AS Имя,
-- Отчество (после второго пробела)
  CASE
    WHEN CHARINDEX(' ', CustomerFio) > 0
      AND CHARINDEX(' ', CustomerFio, CHARINDEX(' ', CustomerFio) + 1) > 0
    THEN SUBSTRING(
      CustomerFio,
      CHARINDEX(' ', CustomerFio, CHARINDEX(' ', CustomerFio) + 1) + 1,
      LEN(CustomerFio)
    )
    ELSE ''
  END AS Отчество
FROM Tenants
WHERE CustomerType = 0 AND CustomerFio IS NOT NULL;
GO


-- (ж)Выборка данных, относящихся к текущей дате (выбирают из таблицы (см. п.2а) данные, относящиеся к текущей дате. Объяснить полученный результат)
-- Выбираем договоры, которые начинаются сегодня или позже
SELECT TreatyID, DateStart, DateStop, Value, Target
FROM Contracts
WHERE DateStart >= CAST(GETDATE() AS DATE);
GO


-- (з) Обновление дат и определение количества месяцев между ними (обновляют даты в строках, добавленных в п.2а, уменьшая одну из дат на 3 месяца и увеличивая другую дату на 2 месяца, и определяют количество месяцев, разделяющих эти две даты. Если в базе данных нет таблицы с такими полями, то запрограммировать указанные вычисления оператором SELECT для таблицы DUAL)
-- Находим добавленные ранее договоры (с большими TreatyID)
DECLARE @MaxTrID INT;
SELECT @MaxTrID = MAX(TreatyID) - 1 FROM Contracts;
-- Обновляем даты
UPDATE Contracts
SET DateStart = DATEADD(MONTH, -3, DateStart), -- уменьшаем на 3 месяца
  DateStop = DATEADD(MONTH, 2, DateStop) -- увеличиваем на 2 месяца
WHERE TreatyID IN (@MaxTrID, @MaxTrID + 1);
-- Определяем количество месяцев между DateStart и DateStop
SELECT
  TreatyID,
  DateStart,
  DateStop,
  DATEDIFF(MONTH, DateStart, DateStop) AS КоличествоМесяцев
FROM Contracts
WHERE TreatyID IN (@MaxTrID, @MaxTrID + 1);
GO


-- (и) количество дней в месяце для каждой даты (определяют количество дней в месяце для каждой даты, сформированной в п.2з. Если в базе данных нет таблицы с такими полями, то запрограммировать указанные вычисления оператором SELECT для таблицы DUAL)
DECLARE @MaxTrID1 INT;
SELECT @MaxTrID1 = MAX(TreatyID) - 1 FROM Contracts;

SELECT
TreatyID,
  DateStart AS ИсходнаяДата,
  DATEFROMPARTS(YEAR(DateStart), MONTH(DateStart), 1) AS ПервыйДеньМесяца,
  EOMONTH(DateStart) AS ПоследнийДеньМесяца,
  DAY(EOMONTH(DateStart)) AS КоличествоДнейВМесяце
FROM Contracts
WHERE TreatyID IN (@MaxTrID1, @MaxTrID1 + 1);
GO


-- (к) Вывод даты, времени и числа в разных форматах
DECLARE @CurrentDate DATETIME = GETDATE();
DECLARE @Number MONEY = 123456.789;

SELECT
  @CurrentDate AS ИсходнаяДата,
-- Форматы даты (стили CONVERT)
CONVERT(NVARCHAR, @CurrentDate, 101) AS США_мм_дд_гггг,
CONVERT(NVARCHAR, @CurrentDate, 103) AS Великобритания_дд_мм_гггг,
CONVERT(NVARCHAR, @CurrentDate, 104) AS Германия_дд_мм_гггг,
CONVERT(NVARCHAR, @CurrentDate, 105) AS Италия_дд_мм_гггг,
CONVERT(NVARCHAR, @CurrentDate, 106) AS дд_мес_гггг,
CONVERT(NVARCHAR, @CurrentDate, 107) AS мес_дд_гггг,
CONVERT(NVARCHAR, @CurrentDate, 108) AS Время_чч_мм_сс,
CONVERT(NVARCHAR, @CurrentDate, 112) AS ГГГГММДД,
-- Форматы времени
CONVERT(NVARCHAR, @CurrentDate, 114) AS Время_чч_мм_сс_мс,
-- Форматирование чисел
@Number AS ИсходноеЧисло,
CONVERT(NVARCHAR, CAST(@Number AS INT)) AS БезДробнойЧасти,
FORMAT(@Number, 'N2') AS СРазделителямиРазрядов,
FORMAT(@Number, 'C', 'ru-RU') AS ВалютныйФорматРубли;
GO


-- (л) Добавление строк с датами в разных форматах (добавляют в таблицу, содержащую поля с датами, строки, для которых значения полей с датами задаются в разных форматах)
INSERT INTO Contracts VALUES
(3001, 1, 101, 1, CONVERT(DATE, '2024-01-15', 126), CONVERT(DATE, '2025-01-15',
126), N'ежемес.', 60000, N'Иванов И.И.', N'офис', 5000),
(3002, 2, 102, 1, CONVERT(DATE, '15/02/2024', 103), CONVERT(DATE, '15/02/2025',
103), N'ежемес.', 40000, N'Петров П.П.', N'магазин', 3000);
-- Проверка
SELECT TreatyID, DateStart, DateStop, Period, Value, Target
FROM Contracts
WHERE TreatyID BETWEEN 3001 AND 3002;
GO
