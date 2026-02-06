CREATE PROCEDURE Test_Feb03.test_tpch_q03_basic_match
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';

    INSERT INTO dbo.customer (c_custkey, c_mktsegment)
    VALUES (1, 'BUILDING');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate, o_shippriority)
    VALUES (10, 1, '1995-03-14', 1);

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_shipdate)
    VALUES (10, 100.00, 0.10, '1995-03-16');

    SELECT l_orderkey, 
           SUM(l_extendedprice * (1 - l_discount)) AS revenue, 
           o_orderdate, 
           o_shippriority
    INTO #Expected_basic_match
    FROM dbo.customer AS c
    JOIN dbo.orders AS o ON o.o_custkey = c.c_custkey
    JOIN dbo.lineitem AS l ON l.l_orderkey = o.o_orderkey
    WHERE c.c_mktsegment = 'BUILDING'
      AND o.o_orderdate < '1995-03-15'
      AND l.l_shipdate > '1995-03-15'
    GROUP BY l.l_orderkey, o.o_orderdate, o.o_shippriority;

    SELECT * 
    INTO #Actual_basic_match
    FROM dbo.tpch_q03('BUILDING','1995-03-15');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_basic_match', @Actual = '#Actual_basic_match';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q03_no_match_due_to_segment
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';

    INSERT INTO dbo.customer (c_custkey, c_mktsegment)
    VALUES (2, 'AUTOMOBILE'); -- different segment

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate, o_shippriority)
    VALUES (20, 2, '1995-03-10', 2);

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_shipdate)
    VALUES (20, 200.00, 0.05, '1995-04-01');

    SELECT * INTO #Expected_no_match_segment FROM (SELECT 1 AS dummy) AS t WHERE 1 = 0; -- empty table

    SELECT * 
    INTO #Actual_no_match_segment
    FROM dbo.tpch_q03('BUILDING','1995-03-15');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_no_match_segment', @Actual = '#Actual_no_match_segment';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q03_no_match_due_to_orderdate
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';

    INSERT INTO dbo.customer (c_custkey, c_mktsegment)
    VALUES (3, 'BUILDING');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate, o_shippriority)
    VALUES (30, 3, '1995-03-15', 3); -- orderdate not < @date

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_shipdate)
    VALUES (30, 150.00, 0.20, '1995-04-10');

    SELECT * INTO #Expected_no_match_orderdate FROM (SELECT 1 AS dummy) AS t WHERE 1 = 0; -- empty

    SELECT * 
    INTO #Actual_no_match_orderdate
    FROM dbo.tpch_q03('BUILDING','1995-03-15');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_no_match_orderdate', @Actual = '#Actual_no_match_orderdate';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q03_no_match_due_to_shipdate
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';

    INSERT INTO dbo.customer (c_custkey, c_mktsegment)
    VALUES (4, 'BUILDING');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate, o_shippriority)
    VALUES (40, 4, '1995-03-10', 4);

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_shipdate)
    VALUES (40, 120.00, 0.15, '1995-03-15'); -- shipdate not > @date

    SELECT * INTO #Expected_no_match_shipdate FROM (SELECT 1 AS dummy) AS t WHERE 1 = 0; -- empty

    SELECT * 
    INTO #Actual_no_match_shipdate
    FROM dbo.tpch_q03('BUILDING','1995-03-15');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_no_match_shipdate', @Actual = '#Actual_no_match_shipdate';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q03_null_parameters
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';

    -- Even with data present, NULL parameters should filter out all rows
    INSERT INTO dbo.customer (c_custkey, c_mktsegment)
    VALUES (5, 'BUILDING');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate, o_shippriority)
    VALUES (50, 5, '1995-01-01', 5);

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_shipdate)
    VALUES (50, 300.00, 0.10, '1995-06-01');

    SELECT * INTO #Expected_null_params FROM (SELECT 1 AS dummy) AS t WHERE 1 = 0; -- empty

    SELECT * 
    INTO #Actual_null_params
    FROM dbo.tpch_q03(NULL,NULL);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_null_params', @Actual = '#Actual_null_params';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q03_boundary_dates
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';

    INSERT INTO dbo.customer (c_custkey, c_mktsegment)
    VALUES (6, 'BUILDING');

    -- Orderdate exactly equal to @date (should be excluded)
    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate, o_shippriority)
    VALUES (60, 6, '1995-03-15', 6);

    -- Shipdate exactly equal to @date (should be excluded)
    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_shipdate)
    VALUES (60, 250.00, 0.05, '1995-03-15');

    SELECT * INTO #Expected_boundary FROM (SELECT 1 AS dummy) AS t WHERE 1 = 0; -- empty

    SELECT * 
    INTO #Actual_boundary
    FROM dbo.tpch_q03('BUILDING','1995-03-15');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_boundary', @Actual = '#Actual_boundary';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q03_multiple_lineitems_aggregation
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';

    INSERT INTO dbo.customer (c_custkey, c_mktsegment)
    VALUES (7, 'BUILDING');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate, o_shippriority)
    VALUES (70, 7, '1995-02-28', 7);

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_shipdate)
    VALUES 
        (70, 100.00, 0.10, '1995-04-01'), -- contributes 90
        (70, 200.00, 0.20, '1995-04-02'); -- contributes 160

    -- Expected revenue = 90 + 160 = 250

    SELECT
        70 AS l_orderkey,
        250.00 AS revenue,
        CAST('1995-02-28' AS date) AS o_orderdate,
        7 AS o_shippriority
    INTO #Expected_aggregation;

    SELECT * 
    INTO #Actual_aggregation
    FROM dbo.tpch_q03('BUILDING','1995-03-15');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_aggregation', @Actual = '#Actual_aggregation';
END;
GO