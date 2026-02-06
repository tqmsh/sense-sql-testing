CREATE PROCEDURE Test_Feb03.test_tpch_q05_region_match
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';
    EXEC tSQLt.FakeTable 'dbo.region';

    /* Populate REGION */
    INSERT INTO dbo.region (r_regionkey, r_name)
    VALUES (1, 'ASIA');

    /* Populate NATION */
    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey)
    VALUES (10, 'NationA', 1);

    /* Populate CUSTOMER (same nation as supplier) */
    INSERT INTO dbo.customer (c_custkey, c_nationkey)
    VALUES (100, 10);

    /* Populate SUPPLIER (same nation as customer) */
    INSERT INTO dbo.supplier (s_suppkey, s_nationkey)
    VALUES (200, 10);

    /* Populate ORDERS (within date range) */
    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate)
    VALUES (300, 100, '1994-06-15');

    /* Populate LINEITEM */
    INSERT INTO dbo.lineitem (l_orderkey, l_suppkey, l_extendedprice, l_discount)
    VALUES (300, 200, 1000.00, 0.10); -- revenue = 1000 * (1-0.10) = 900

    CREATE TABLE #Expected (n_name varchar(25), revenue decimal(18,2));
    INSERT INTO #Expected (n_name, revenue) VALUES ('NationA', 900.00);

    CREATE TABLE #Actual (n_name varchar(25), revenue decimal(18,2));
    INSERT INTO #Actual
    SELECT n_name, revenue
    FROM dbo.tpch_q05('ASIA', '1994-01-01');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q05_region_mismatch
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';
    EXEC tSQLt.FakeTable 'dbo.region';

    INSERT INTO dbo.region (r_regionkey, r_name) VALUES (1, 'EUROPE');
    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey) VALUES (10, 'NationA', 1);
    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES (100, 10);
    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (200, 10);
    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate) VALUES (300, 100, '1994-06-15');
    INSERT INTO dbo.lineitem (l_orderkey, l_suppkey, l_extendedprice, l_discount) VALUES (300, 200, 500.00, 0.05);

    CREATE TABLE #Expected (n_name varchar(25), revenue decimal(18,2));
    /* Expect empty result set */
    CREATE TABLE #Actual (n_name varchar(25), revenue decimal(18,2));
    INSERT INTO #Actual
    SELECT n_name, revenue
    FROM dbo.tpch_q05('ASIA', '1994-01-01');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q05_date_boundary
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';
    EXEC tSQLt.FakeTable 'dbo.region';

    INSERT INTO dbo.region (r_regionkey, r_name) VALUES (1, 'ASIA');
    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey) VALUES (10, 'NationA', 1);
    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES (100, 10);
    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (200, 10);

    /* Order on start date (inclusive) */
    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate) VALUES (301, 100, '1994-01-01');
    INSERT INTO dbo.lineitem (l_orderkey, l_suppkey, l_extendedprice, l_discount) VALUES (301, 200, 800.00, 0.10); -- 720

    /* Order on end date (exclusive) */
    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate) VALUES (302, 100, '1995-01-01');
    INSERT INTO dbo.lineitem (l_orderkey, l_suppkey, l_extendedprice, l_discount) VALUES (302, 200, 1200.00, 0.20); -- 960 (should be excluded)

    CREATE TABLE #Expected (n_name varchar(25), revenue decimal(18,2));
    INSERT INTO #Expected (n_name, revenue) VALUES ('NationA', 720.00);

    CREATE TABLE #Actual (n_name varchar(25), revenue decimal(18,2));
    INSERT INTO #Actual
    SELECT n_name, revenue
    FROM dbo.tpch_q05('ASIA', '1994-01-01');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q05_null_parameters
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';
    EXEC tSQLt.FakeTable 'dbo.region';

    /* No data needed; any data would be filtered out by NULL comparison */

    CREATE TABLE #Expected (n_name varchar(25), revenue decimal(18,2));
    CREATE TABLE #Actual (n_name varchar(25), revenue decimal(18,2));
    INSERT INTO #Actual
    SELECT n_name, revenue
    FROM dbo.tpch_q05(NULL, NULL);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q05_customer_supplier_nation_mismatch
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';
    EXEC tSQLt.FakeTable 'dbo.region';

    INSERT INTO dbo.region (r_regionkey, r_name) VALUES (1, 'ASIA');
    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey) VALUES (10, 'NationA', 1);
    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey) VALUES (20, 'NationB', 1);

    /* Customer from NationA, Supplier from NationB (mismatch) */
    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES (100, 10);
    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (200, 20);
    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate) VALUES (300, 100, '1994-06-15');
    INSERT INTO dbo.lineitem (l_orderkey, l_suppkey, l_extendedprice, l_discount) VALUES (300, 200, 1500.00, 0.15);

    CREATE TABLE #Expected (n_name varchar(25), revenue decimal(18,2));
    /* Expect empty because nation keys do not match */
    CREATE TABLE #Actual (n_name varchar(25), revenue decimal(18,2));
    INSERT INTO #Actual
    SELECT n_name, revenue
    FROM dbo.tpch_q05('ASIA', '1994-01-01');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO