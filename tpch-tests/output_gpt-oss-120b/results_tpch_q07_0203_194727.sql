CREATE PROCEDURE Test_Feb03.test_tpch_q07_basic_filter
AS
BEGIN
    EXEC tSQLt.FakeTable N'dbo.supplier';
    EXEC tSQLt.FakeTable N'dbo.lineitem';
    EXEC tSQLt.FakeTable N'dbo.orders';
    EXEC tSQLt.FakeTable N'dbo.customer';
    EXEC tSQLt.FakeTable N'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES
        (1, 'FRANCE      '),
        (2, 'GERMANY      ');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES
        (10, 1),  -- FRANCE
        (20, 2);  -- GERMANY

    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES
        (100, 2), -- GERMANY
        (200, 1); -- FRANCE

    INSERT INTO dbo.orders (o_orderkey, o_custkey) VALUES
        (1000, 100),
        (2000, 200);

    INSERT INTO dbo.lineitem (l_suppkey, l_orderkey, l_shipdate, l_extendedprice, l_discount) VALUES
        (10, 1000, '1995-03-15', 1000.00, 0.05),  -- FRANCE->GERMANY
        (20, 2000, '1995-07-20', 2000.00, 0.10);  -- GERMANY->FRANCE

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q07('FRANCE', 'GERMANY', '1995-01-01', '1996-12-31');

    CREATE TABLE #Expected (
        supp_nation char(25) NOT NULL,
        cust_nation char(25) NOT NULL,
        l_year int NOT NULL,
        revenue decimal(38,2) NOT NULL
    );

    INSERT INTO #Expected (supp_nation, cust_nation, l_year, revenue) VALUES
        ('FRANCE      ', 'GERMANY      ', 1995, 950.00),
        ('GERMANY      ', 'FRANCE      ', 1995, 1800.00);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q07_swapped_nations
AS
BEGIN
    EXEC tSQLt.FakeTable N'dbo.supplier';
    EXEC tSQLt.FakeTable N'dbo.lineitem';
    EXEC tSQLt.FakeTable N'dbo.orders';
    EXEC tSQLt.FakeTable N'dbo.customer';
    EXEC tSQLt.FakeTable N'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES
        (1, 'FRANCE      '),
        (2, 'GERMANY      ');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES
        (10, 1),
        (20, 2);

    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES
        (100, 2),
        (200, 1);

    INSERT INTO dbo.orders (o_orderkey, o_custkey) VALUES
        (1000, 100),
        (2000, 200);

    INSERT INTO dbo.lineitem (l_suppkey, l_orderkey, l_shipdate, l_extendedprice, l_discount) VALUES
        (10, 1000, '1995-03-15', 1000.00, 0.05),
        (20, 2000, '1995-07-20', 2000.00, 0.10);

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q07('GERMANY', 'FRANCE', '1995-01-01', '1996-12-31');

    CREATE TABLE #Expected (
        supp_nation char(25) NOT NULL,
        cust_nation char(25) NOT NULL,
        l_year int NOT NULL,
        revenue decimal(38,2) NOT NULL
    );

    INSERT INTO #Expected (supp_nation, cust_nation, l_year, revenue) VALUES
        ('FRANCE      ', 'GERMANY      ', 1995, 950.00),
        ('GERMANY      ', 'FRANCE      ', 1995, 1800.00);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q07_no_matching_rows
AS
BEGIN
    EXEC tSQLt.FakeTable N'dbo.supplier';
    EXEC tSQLt.FakeTable N'dbo.lineitem';
    EXEC tSQLt.FakeTable N'dbo.orders';
    EXEC tSQLt.FakeTable N'dbo.customer';
    EXEC tSQLt.FakeTable N'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES
        (1, 'FRANCE      '),
        (2, 'GERMANY      ');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (10, 1);
    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES (100, 2);
    INSERT INTO dbo.orders (o_orderkey, o_custkey) VALUES (1000, 100);
    INSERT INTO dbo.lineitem (l_suppkey, l_orderkey, l_shipdate, l_extendedprice, l_discount) VALUES
        (10, 1000, '1994-12-31', 1000.00, 0.05); -- outside date_to

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q07('FRANCE', 'GERMANY', '1995-01-01', '1995-12-31');

    CREATE TABLE #Expected (
        supp_nation char(25) NOT NULL,
        cust_nation char(25) NOT NULL,
        l_year int NOT NULL,
        revenue decimal(38,2) NOT NULL
    );

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q07_boundary_dates
AS
BEGIN
    EXEC tSQLt.FakeTable N'dbo.supplier';
    EXEC tSQLt.FakeTable N'dbo.lineitem';
    EXEC tSQLt.FakeTable N'dbo.orders';
    EXEC tSQLt.FakeTable N'dbo.customer';
    EXEC tSQLt.FakeTable N'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES
        (1, 'FRANCE      '),
        (2, 'GERMANY      ');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (10, 1);
    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES (100, 2);
    INSERT INTO dbo.orders (o_orderkey, o_custkey) VALUES (1000, 100);
    INSERT INTO dbo.lineitem (l_suppkey, l_orderkey, l_shipdate, l_extendedprice, l_discount) VALUES
        (10, 1000, '1995-01-01', 500.00, 0.10),  -- exactly date_from
        (10, 1000, '1996-12-31', 800.00, 0.20);  -- exactly date_to

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q07('FRANCE', 'GERMANY', '1995-01-01', '1996-12-31');

    CREATE TABLE #Expected (
        supp_nation char(25) NOT NULL,
        cust_nation char(25) NOT NULL,
        l_year int NOT NULL,
        revenue decimal(38,2) NOT NULL
    );

    INSERT INTO #Expected (supp_nation, cust_nation, l_year, revenue) VALUES
        ('FRANCE      ', 'GERMANY      ', 1995, 450.00),   -- 500 * (1-0.10)
        ('FRANCE      ', 'GERMANY      ', 1996, 640.00);   -- 800 * (1-0.20)

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q07_null_parameters
AS
BEGIN
    EXEC tSQLt.FakeTable N'dbo.supplier';
    EXEC tSQLt.FakeTable N'dbo.lineitem';
    EXEC tSQLt.FakeTable N'dbo.orders';
    EXEC tSQLt.FakeTable N'dbo.customer';
    EXEC tSQLt.FakeTable N'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES
        (1, 'FRANCE      '),
        (2, 'GERMANY      ');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (10, 1);
    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES (100, 2);
    INSERT INTO dbo.orders (o_orderkey, o_custkey) VALUES (1000, 100);
    INSERT INTO dbo.lineitem (l_suppkey, l_orderkey, l_shipdate, l_extendedprice, l_discount) VALUES
        (10, 1000, '1995-06-15', 1000.00, 0.05);

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q07(NULL, NULL, '1995-01-01', '1996-12-31');

    CREATE TABLE #Expected (
        supp_nation char(25) NOT NULL,
        cust_nation char(25) NOT NULL,
        l_year int NOT NULL,
        revenue decimal(38,2) NOT NULL
    );

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q07_nonexistent_nations
AS
BEGIN
    EXEC tSQLt.FakeTable N'dbo.supplier';
    EXEC tSQLt.FakeTable N'dbo.lineitem';
    EXEC tSQLt.FakeTable N'dbo.orders';
    EXEC tSQLt.FakeTable N'dbo.customer';
    EXEC tSQLt.FakeTable N'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES
        (1, 'FRANCE      '),
        (2, 'GERMANY      ');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (10, 1);
    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES (100, 2);
    INSERT INTO dbo.orders (o_orderkey, o_custkey) VALUES (1000, 100);
    INSERT INTO dbo.lineitem (l_suppkey, l_orderkey, l_shipdate, l_extendedprice, l_discount) VALUES
        (10, 1000, '1995-06-15', 1000.00, 0.05);

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q07('ARGENTINA', 'BRAZIL', '1995-01-01', '1996-12-31');

    CREATE TABLE #Expected (
        supp_nation char(25) NOT NULL,
        cust_nation char(25) NOT NULL,
        l_year int NOT NULL,
        revenue decimal(38,2) NOT NULL
    );

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO