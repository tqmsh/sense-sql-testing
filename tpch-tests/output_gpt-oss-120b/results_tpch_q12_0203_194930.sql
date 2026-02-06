EXEC tSQLt.NewTestClass 'Test_Feb03';
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q12_default_parameters]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'orders';
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.orders (o_orderkey, o_orderpriority) VALUES (1, '1-URGENT');
    INSERT INTO dbo.lineitem (l_orderkey, l_shipmode, l_commitdate, l_receiptdate, l_shipdate)
        VALUES (1, 'MAIL',      '1994-01-15', '1994-06-01', '1994-01-10');

    CREATE TABLE #Expected
    (
        l_shipmode   char(10) NOT NULL,
        high_line_count int NOT NULL,
        low_line_count  int NOT NULL
    );

    INSERT INTO #Expected VALUES ('MAIL', 1, 0);

    EXEC tSQLt.AssertEqualsTable
        @Expected = '#Expected',
        @Actual   = 'SELECT * FROM dbo.tpch_q12(''1994-01-01'', ''MAIL'', ''SHIP'', ''1-URGENT'', ''2-HIGH'')';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q12_low_priority_counts]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'orders';
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.orders (o_orderkey, o_orderpriority) VALUES (2, '3-MEDIUM');
    INSERT INTO dbo.lineitem (l_orderkey, l_shipmode, l_commitdate, l_receiptdate, l_shipdate)
        VALUES (2, 'SHIP', '1994-02-05', '1994-12-31', '1994-02-01');

    CREATE TABLE #Expected
    (
        l_shipmode   char(10) NOT NULL,
        high_line_count int NOT NULL,
        low_line_count  int NOT NULL
    );

    INSERT INTO #Expected VALUES ('SHIP', 0, 1);

    EXEC tSQLt.AssertEqualsTable
        @Expected = '#Expected',
        @Actual   = 'SELECT * FROM dbo.tpch_q12(''1994-01-01'', ''MAIL'', ''SHIP'', ''1-URGENT'', ''2-HIGH'')';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q12_multiple_shipmodes_mixed_priorities]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'orders';
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    -- Order 1: high priority, MAIL
    INSERT INTO dbo.orders (o_orderkey, o_orderpriority) VALUES (10, '1-URGENT');
    INSERT INTO dbo.lineitem (l_orderkey, l_shipmode, l_commitdate, l_receiptdate, l_shipdate)
        VALUES (10, 'MAIL', '1994-03-01', '1994-04-15', '1994-02-28');

    -- Order 2: low priority, SHIP
    INSERT INTO dbo.orders (o_orderkey, o_orderpriority) VALUES (20, '5-LOW');
    INSERT INTO dbo.lineitem (l_orderkey, l_shipmode, l_commitdate, l_receiptdate, l_shipdate)
        VALUES (20, 'SHIP', '1994-05-10', '1994-07-20', '1994-05-01');

    CREATE TABLE #Expected
    (
        l_shipmode   char(10) NOT NULL,
        high_line_count int NOT NULL,
        low_line_count  int NOT NULL
    );

    INSERT INTO #Expected VALUES ('MAIL', 1, 0), ('SHIP', 0, 1);

    EXEC tSQLt.AssertEqualsTable
        @Expected = '#Expected',
        @Actual   = 'SELECT * FROM dbo.tpch_q12(''1994-01-01'', ''MAIL'', ''SHIP'', ''1-URGENT'', ''2-HIGH'')';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q12_boundary_dates_exclusive_upper]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'orders';
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    -- Receipt date exactly on lower bound (should be included)
    INSERT INTO dbo.orders (o_orderkey, o_orderpriority) VALUES (100, '1-URGENT');
    INSERT INTO dbo.lineitem (l_orderkey, l_shipmode, l_commitdate, l_receiptdate, l_shipdate)
        VALUES (100, 'MAIL', '1994-01-01', '1994-01-01', '1993-12-30');

    -- Receipt date exactly on upper bound (should be excluded)
    INSERT INTO dbo.orders (o_orderkey, o_orderpriority) VALUES (200, '1-URGENT');
    INSERT INTO dbo.lineitem (l_orderkey, l_shipmode, l_commitdate, l_receiptdate, l_shipdate)
        VALUES (200, 'MAIL', '1995-01-01', '1995-01-01', '1994-12-30');

    CREATE TABLE #Expected
    (
        l_shipmode   char(10) NOT NULL,
        high_line_count int NOT NULL,
        low_line_count  int NOT NULL
    );

    INSERT INTO #Expected VALUES ('MAIL', 1, 0);

    EXEC tSQLt.AssertEqualsTable
        @Expected = '#Expected',
        @Actual   = 'SELECT * FROM dbo.tpch_q12(''1994-01-01'', ''MAIL'', ''SHIP'', ''1-URGENT'', ''2-HIGH'')';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q12_null_shipmode_parameters]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'orders';
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.orders (o_orderkey, o_orderpriority) VALUES (300, '1-URGENT');
    INSERT INTO dbo.lineitem (l_orderkey, l_shipmode, l_commitdate, l_receiptdate, l_shipdate)
        VALUES (300, NULL, '1994-06-01', '1994-07-01', '1994-05-30');

    CREATE TABLE #Expected (l_shipmode char(10) NOT NULL, high_line_count int NOT NULL, low_line_count int NOT NULL);
    -- Expect no rows because l_shipmode is NULL and cannot match NULL parameters
    -- So the result set is empty

    EXEC tSQLt.AssertEqualsTable
        @Expected = '#Expected',
        @Actual   = 'SELECT * FROM dbo.tpch_q12(''1994-01-01'', NULL, ''SHIP'', ''1-URGENT'', ''2-HIGH'')';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q12_non_matching_shipmode]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'orders';
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.orders (o_orderkey, o_orderpriority) VALUES (400, '1-URGENT');
    INSERT INTO dbo.lineitem (l_orderkey, l_shipmode, l_commitdate, l_receiptdate, l_shipdate)
        VALUES (400, 'AIR', '1994-08-01', '1994-09-01', '1994-07-30');

    CREATE TABLE #Expected (l_shipmode char(10) NOT NULL, high_line_count int NOT NULL, low_line_count int NOT NULL);
    -- No rows expected because shipmode 'AIR' is not in the allowed list

    EXEC tSQLt.AssertEqualsTable
        @Expected = '#Expected',
        @Actual   = 'SELECT * FROM dbo.tpch_q12(''1994-01-01'', ''MAIL'', ''SHIP'', ''1-URGENT'', ''2-HIGH'')';
END;
GO