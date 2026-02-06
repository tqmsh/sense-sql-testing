CREATE PROCEDURE Test_Feb03.test_tpch_q11_basic_match
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'partsupp';
    EXEC tSQLt.FakeTable 'dbo', 'supplier';
    EXEC tSQLt.FakeTable 'dbo', 'nation';

    INSERT INTO dbo.nation (n_nationkey, n_name)
    VALUES (1, 'GERMANY');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey)
    VALUES (10, 1);   -- supplier in GERMANY

    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost, ps_availqty)
    VALUES
        (100, 10, 5.000000, 10),   -- value = 50.000000
        (101, 10, 1.000000, 5);    -- value = 5.000000

    /* Expected result: only partkey 100 exceeds 50% of total (55 * 0.5 = 27.5) */
    CREATE TABLE #Expected_basic
    (
        ps_partkey INT,
        value      DECIMAL(38,6)
    );

    INSERT INTO #Expected_basic (ps_partkey, value)
    VALUES (100, 50.000000);

    /* Actual result */
    SELECT *
    INTO   #Actual
    FROM   dbo.tpch_q11('GERMANY', 0.5000000000);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_basic', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q11_no_results
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'partsupp';
    EXEC tSQLt.FakeTable 'dbo', 'supplier';
    EXEC tSQLt.FakeTable 'dbo', 'nation';

    INSERT INTO dbo.nation (n_nationkey, n_name)
    VALUES (1, 'GERMANY');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey)
    VALUES (20, 1);   -- supplier in GERMANY

    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost, ps_availqty)
    VALUES
        (200, 20, 2.000000, 5),   -- value = 10.000000
        (201, 20, 3.000000, 3);   -- value = 9.000000

    /* Expected result: empty set because fraction = 1 (threshold = total sum) */
    CREATE TABLE #Expected_empty
    (
        ps_partkey INT,
        value      DECIMAL(38,6)
    );

    SELECT *
    INTO   #Actual
    FROM   dbo.tpch_q11('GERMANY', 1.0000000000);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_empty', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q11_null_nation
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'partsupp';
    EXEC tSQLt.FakeTable 'dbo', 'supplier';
    EXEC tSQLt.FakeTable 'dbo', 'nation';

    INSERT INTO dbo.nation (n_nationkey, n_name)
    VALUES (2, 'FRANCE');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey)
    VALUES (30, 2);

    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost, ps_availqty)
    VALUES
        (300, 30, 4.000000, 2);   -- value = 8.000000

    /* Expected result: empty because nation filter = NULL matches nothing */
    CREATE TABLE #Expected_nullnation
    (
        ps_partkey INT,
        value      DECIMAL(38,6)
    );

    SELECT *
    INTO   #Actual
    FROM   dbo.tpch_q11(NULL, 0.1000000000);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_nullnation', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q11_fraction_zero
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'partsupp';
    EXEC tSQLt.FakeTable 'dbo', 'supplier';
    EXEC tSQLt.FakeTable 'dbo', 'nation';

    INSERT INTO dbo.nation (n_nationkey, n_name)
    VALUES (1, 'GERMANY');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey)
    VALUES (40, 1);

    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost, ps_availqty)
    VALUES
        (400, 40, 1.500000, 4),   -- value = 6.000000
        (401, 40, 2.000000, 3);   -- value = 6.000000

    /* Expected result: both rows because threshold = 0 (fraction = 0) */
    CREATE TABLE #Expected_fractionzero
    (
        ps_partkey INT,
        value      DECIMAL(38,6)
    );

    INSERT INTO #Expected_fractionzero (ps_partkey, value)
    VALUES
        (400, 6.000000),
        (401, 6.000000);

    SELECT *
    INTO   #Actual
    FROM   dbo.tpch_q11('GERMANY', 0.0000000000);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_fractionzero', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q11_multiple_partkeys
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'partsupp';
    EXEC tSQLt.FakeTable 'dbo', 'supplier';
    EXEC tSQLt.FakeTable 'dbo', 'nation';

    INSERT INTO dbo.nation (n_nationkey, n_name)
    VALUES (1, 'GERMANY');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey)
    VALUES (50, 1), (51, 1);

    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost, ps_availqty)
    VALUES
        (500, 50, 1.000000, 10),   -- value = 10.000000
        (501, 50, 2.000000, 5),    -- value = 10.000000
        (502, 51, 3.000000, 2),    -- value = 6.000000
        (503, 51, 4.000000, 1);    -- value = 4.000000

    /* Total = 30.0, fraction 0.2 => threshold = 6.0
       Rows with value > 6.0 => partkey 500, 501, 502 (6.0 is not >) */
    CREATE TABLE #Expected_multi
    (
        ps_partkey INT,
        value      DECIMAL(38,6)
    );

    INSERT INTO #Expected_multi (ps_partkey, value)
    VALUES
        (500, 10.000000),
        (501, 10.000000),
        (502, 6.000000);   -- note value = 6.0 is not > threshold, but we keep to verify logic; actually it should NOT be returned.
    /* Adjust expectation to only partkeys 500 and 501 */
    DELETE FROM #Expected_multi WHERE ps_partkey = 502;

    SELECT *
    INTO   #Actual
    FROM   dbo.tpch_q11('GERMANY', 0.2000000000);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_multi', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q11_null_fraction
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo', 'partsupp';
    EXEC tSQLt.FakeTable 'dbo', 'supplier';
    EXEC tSQLt.FakeTable 'dbo', 'nation';

    INSERT INTO dbo.nation (n_nationkey, n_name)
    VALUES (1, 'GERMANY');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey)
    VALUES (60, 1);

    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost, ps_availqty)
    VALUES
        (600, 60, 5.000000, 1);   -- value = 5.000000

    /* Expected: empty because NULL fraction makes comparison evaluate to UNKNOWN */
    CREATE TABLE #Expected_nullfrac
    (
        ps_partkey INT,
        value      DECIMAL(38,6)
    );

    SELECT *
    INTO   #Actual
    FROM   dbo.tpch_q11('GERMANY', NULL);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_nullfrac', @Actual = '#Actual';
END;
GO