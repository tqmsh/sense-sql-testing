CREATE PROCEDURE Test_Feb03.test_tpch_q04_basic_case
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = N'dbo.orders';
    EXEC tSQLt.FakeTable @TableName = N'dbo.lineitem';

    INSERT INTO dbo.orders (o_orderkey, o_orderdate, o_orderpriority)
    VALUES
        (1, '1993-07-05', '1-URGENT'),
        (2, '1993-08-15', '2-HIGH');

    INSERT INTO dbo.lineitem (l_orderkey, l_commitdate, l_receiptdate)
    VALUES
        (1, '1993-07-06', '1993-07-07'),
        (2, '1993-08-16', '1993-08-18');

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q04('1993-07-01', 3);

    CREATE TABLE #Expected_order_count
    (
        o_orderpriority varchar(10) NOT NULL,
        order_count    bigint NOT NULL
    );

    INSERT INTO #Expected_order_count (o_orderpriority, order_count)
    VALUES
        ('1-URGENT', 1),
        ('2-HIGH',   1);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_order_count', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q04_no_matching_lineitems
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = N'dbo.orders';
    EXEC tSQLt.FakeTable @TableName = N'dbo.lineitem';

    INSERT INTO dbo.orders (o_orderkey, o_orderdate, o_orderpriority)
    VALUES (10, '1993-09-10', '3-MEDIUM');

    -- Commitdate is NOT less than receiptdate, so EXISTS should fail
    INSERT INTO dbo.lineitem (l_orderkey, l_commitdate, l_receiptdate)
    VALUES (10, '1993-09-15', '1993-09-14');

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q04('1993-07-01', 3);

    CREATE TABLE #Expected_order_count (o_orderpriority varchar(10) NOT NULL, order_count bigint NOT NULL);
    -- Expecting no rows
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_order_count', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q04_out_of_range_dates
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = N'dbo.orders';
    EXEC tSQLt.FakeTable @TableName = N'dbo.lineitem';

    INSERT INTO dbo.orders (o_orderkey, o_orderdate, o_orderpriority)
    VALUES
        (20, '1993-06-30', '1-URGENT'),   -- before start date
        (21, '1993-10-01', '2-HIGH');    -- exactly at end date (exclusive)

    INSERT INTO dbo.lineitem (l_orderkey, l_commitdate, l_receiptdate)
    VALUES
        (20, '1993-06-30', '1993-07-01'),
        (21, '1993-10-01', '1993-10-02');

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q04('1993-07-01', 3);

    CREATE TABLE #Expected_order_count (o_orderpriority varchar(10) NOT NULL, order_count bigint NOT NULL);
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_order_count', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q04_null_date_parameter
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = N'dbo.orders';
    EXEC tSQLt.FakeTable @TableName = N'dbo.lineitem';

    INSERT INTO dbo.orders (o_orderkey, o_orderdate, o_orderpriority)
    VALUES (30, '1993-07-10', '1-URGENT');

    INSERT INTO dbo.lineitem (l_orderkey, l_commitdate, l_receiptdate)
    VALUES (30, '1993-07-11', '1993-07-12');

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q04(NULL, 3);

    CREATE TABLE #Expected_order_count (o_orderpriority varchar(10) NOT NULL, order_count bigint NOT NULL);
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_order_count', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q04_zero_months
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = N'dbo.orders';
    EXEC tSQLt.FakeTable @TableName = N'dbo.lineitem';

    INSERT INTO dbo.orders (o_orderkey, o_orderdate, o_orderpriority)
    VALUES (40, '1993-07-01', '1-URGENT');

    INSERT INTO dbo.lineitem (l_orderkey, l_commitdate, l_receiptdate)
    VALUES (40, '1993-07-02', '1993-07-03');

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q04('1993-07-01', 0);

    CREATE TABLE #Expected_order_count (o_orderpriority varchar(10) NOT NULL, order_count bigint NOT NULL);
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_order_count', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q04_boundary_dates_inclusive_exclusive
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = N'dbo.orders';
    EXEC tSQLt.FakeTable @TableName = N'dbo.lineitem';

    INSERT INTO dbo.orders (o_orderkey, o_orderdate, o_orderpriority)
    VALUES
        (50, '1993-07-01', '1-URGENT'),   -- exactly start date, should be included
        (51, '1993-10-01', '2-HIGH');    -- exactly end date, should be excluded

    INSERT INTO dbo.lineitem (l_orderkey, l_commitdate, l_receiptdate)
    VALUES
        (50, '1993-07-02', '1993-07-03'),
        (51, '1993-10-02', '1993-10-03');

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q04('1993-07-01', 3);

    CREATE TABLE #Expected_order_count
    (
        o_orderpriority varchar(10) NOT NULL,
        order_count    bigint NOT NULL
    );

    INSERT INTO #Expected_order_count (o_orderpriority, order_count)
    VALUES ('1-URGENT', 1);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_order_count', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q04_multiple_lineitems_per_order
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = N'dbo.orders';
    EXEC tSQLt.FakeTable @TableName = N'dbo.lineitem';

    INSERT INTO dbo.orders (o_orderkey, o_orderdate, o_orderpriority)
    VALUES (60, '1993-08-15', '3-MEDIUM');

    INSERT INTO dbo.lineitem (l_orderkey, l_commitdate, l_receiptdate)
    VALUES
        (60, '1993-08-16', '1993-08-17'),  -- valid
        (60, '1993-08-18', '1993-08-19'),  -- another valid
        (60, '1993-08-20', '1993-08-19');  -- invalid (commit > receipt)

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q04('1993-07-01', 3);

    CREATE TABLE #Expected_order_count
    (
        o_orderpriority varchar(10) NOT NULL,
        order_count    bigint NOT NULL
    );

    INSERT INTO #Expected_order_count (o_orderpriority, order_count)
    VALUES ('3-MEDIUM', 1);  -- order counted once despite multiple lineitems

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_order_count', @Actual = '#Actual';
END;
GO