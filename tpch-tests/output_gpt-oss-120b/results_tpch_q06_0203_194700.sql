CREATE PROCEDURE [Test_Feb03].[test_tpch_q06_all_conditions_met]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.lineitem (l_shipdate, l_discount, l_quantity, l_extendedprice)
    VALUES ('1994-06-15', 0.0600, 10.00, 1000.00); -- meets all criteria

    CREATE TABLE #Expected (revenue decimal(38,4));
    INSERT INTO #Expected VALUES (1000.00 * 0.0600);

    CREATE TABLE #Actual (revenue decimal(38,4));
    INSERT INTO #Actual SELECT revenue FROM dbo.tpch_q06('1994-01-01', 0.0600, 0.0100, 24.00);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE [Test_Feb03].[test_tpch_q06_shipdate_before_start_excluded]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.lineitem (l_shipdate, l_discount, l_quantity, l_extendedprice)
    VALUES ('1993-12-31', 0.0600, 10.00, 500.00); -- shipdate too early

    CREATE TABLE #Expected (revenue decimal(38,4));
    INSERT INTO #Expected VALUES (NULL);

    CREATE TABLE #Actual (revenue decimal(38,4));
    INSERT INTO #Actual SELECT revenue FROM dbo.tpch_q06('1994-01-01', 0.0600, 0.0100, 24.00);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE [Test_Feb03].[test_tpch_q06_shipdate_at_end_excluded]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.lineitem (l_shipdate, l_discount, l_quantity, l_extendedprice)
    VALUES ('1995-01-01', 0.0600, 10.00, 750.00); -- shipdate exactly one year after start

    CREATE TABLE #Expected (revenue decimal(38,4));
    INSERT INTO #Expected VALUES (NULL);

    CREATE TABLE #Actual (revenue decimal(38,4));
    INSERT INTO #Actual SELECT revenue FROM dbo.tpch_q06('1994-01-01', 0.0600, 0.0100, 24.00);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE [Test_Feb03].[test_tpch_q06_discount_lower_boundary_included]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.lineitem (l_shipdate, l_discount, l_quantity, l_extendedprice)
    VALUES ('1994-07-01', 0.0500, 5.00, 200.00); -- discount = center - delta

    CREATE TABLE #Expected (revenue decimal(38,4));
    INSERT INTO #Expected VALUES (200.00 * 0.0500);

    CREATE TABLE #Actual (revenue decimal(38,4));
    INSERT INTO #Actual SELECT revenue FROM dbo.tpch_q06('1994-01-01', 0.0600, 0.0100, 24.00);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE [Test_Feb03].[test_tpch_q06_discount_upper_boundary_included]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.lineitem (l_shipdate, l_discount, l_quantity, l_extendedprice)
    VALUES ('1994-07-01', 0.0700, 5.00, 300.00); -- discount = center + delta

    CREATE TABLE #Expected (revenue decimal(38,4));
    INSERT INTO #Expected VALUES (300.00 * 0.0700);

    CREATE TABLE #Actual (revenue decimal(38,4));
    INSERT INTO #Actual SELECT revenue FROM dbo.tpch_q06('1994-01-01', 0.0600, 0.0100, 24.00);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE [Test_Feb03].[test_tpch_q06_discount_outside_excluded]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.lineitem (l_shipdate, l_discount, l_quantity, l_extendedprice)
    VALUES 
        ('1994-07-01', 0.0499, 5.00, 400.00), -- just below lower bound
        ('1994-07-01', 0.0701, 5.00, 500.00); -- just above upper bound

    CREATE TABLE #Expected (revenue decimal(38,4));
    INSERT INTO #Expected VALUES (NULL); -- no qualifying rows

    CREATE TABLE #Actual (revenue decimal(38,4));
    INSERT INTO #Actual SELECT revenue FROM dbo.tpch_q06('1994-01-01', 0.0600, 0.0100, 24.00);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE [Test_Feb03].[test_tpch_q06_quantity_boundary_excluded]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.lineitem (l_shipdate, l_discount, l_quantity, l_extendedprice)
    VALUES ('1994-08-01', 0.0600, 24.00, 600.00); -- quantity equals max, should be excluded

    CREATE TABLE #Expected (revenue decimal(38,4));
    INSERT INTO #Expected VALUES (NULL);

    CREATE TABLE #Actual (revenue decimal(38,4));
    INSERT INTO #Actual SELECT revenue FROM dbo.tpch_q06('1994-01-01', 0.0600, 0.0100, 24.00);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE [Test_Feb03].[test_tpch_q06_quantity_less_included]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.lineitem (l_shipdate, l_discount, l_quantity, l_extendedprice)
    VALUES ('1994-08-01', 0.0600, 23.99, 700.00); -- quantity just below max

    CREATE TABLE #Expected (revenue decimal(38,4));
    INSERT INTO #Expected VALUES (700.00 * 0.0600);

    CREATE TABLE #Actual (revenue decimal(38,4));
    INSERT INTO #Actual SELECT revenue FROM dbo.tpch_q06('1994-01-01', 0.0600, 0.0100, 24.00);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE [Test_Feb03].[test_tpch_q06_null_parameters]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.lineitem (l_shipdate, l_discount, l_quantity, l_extendedprice)
    VALUES ('1994-09-01', 0.0600, 10.00, 800.00); -- valid row but parameters are NULL

    CREATE TABLE #Expected (revenue decimal(38,4));
    INSERT INTO #Expected VALUES (NULL); -- any comparison with NULL yields NULL sum

    CREATE TABLE #Actual (revenue decimal(38,4));
    INSERT INTO #Actual SELECT revenue FROM dbo.tpch_q06(NULL, NULL, NULL, NULL);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE [Test_Feb03].[test_tpch_q06_multiple_rows_mixed]
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';

    INSERT INTO dbo.lineitem (l_shipdate, l_discount, l_quantity, l_extendedprice)
    VALUES 
        ('1994-03-15', 0.0600, 5.00, 100.00),   -- qualifies
        ('1994-04-20', 0.0550, 5.00, 200.00),   -- qualifies (within discount range)
        ('1994-12-31', 0.0800, 5.00, 300.00),   -- discount too high
        ('1995-01-01', 0.0600, 5.00, 400.00),   -- shipdate out of range
        ('1994-06-10', 0.0600, 25.00, 500.00);  -- quantity too high

    CREATE TABLE #Expected (revenue decimal(38,4));
    INSERT INTO #Expected VALUES ((100.00 * 0.0600) + (200.00 * 0.0550));

    CREATE TABLE #Actual (revenue decimal(38,4));
    INSERT INTO #Actual SELECT revenue FROM dbo.tpch_q06('1994-01-01', 0.0600, 0.0100, 24.00);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO