CREATE PROCEDURE Test_Feb03.test_tpch_q08_normal_share
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo', 'part';
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';
    EXEC tSQLt.FakeTable 'dbo', 'orders';
    EXEC tSQLt.FakeTable 'dbo', 'customer';
    EXEC tSQLt.FakeTable 'dbo', 'nation';
    EXEC tSQLt.FakeTable 'dbo', 'region';
    EXEC tSQLt.FakeTable 'dbo', 'supplier';

    INSERT INTO dbo.region (r_regionkey, r_name) VALUES
        (1, 'AMERICA');

    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey) VALUES
        (10, 'BRAZIL', 1),      -- target nation
        (20, 'USA', 1);         -- other nation

    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES
        (100, 10), (200, 20);

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES
        (500, 10), (600, 20);

    INSERT INTO dbo.part (p_partkey, p_type) VALUES
        (1000, 'ECONOMY ANODIZED STEEL');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate) VALUES
        (10000, 100, '1995-06-15'),   -- year 1995
        (20000, 200, '1995-07-20');   -- year 1995

    INSERT INTO dbo.lineitem (l_orderkey, l_partkey, l_suppkey, l_extendedprice, l_discount) VALUES
        (10000, 1000, 500, 1000.00, 0.1),   -- volume = 900
        (20000, 1000, 600, 2000.00, 0.2);   -- volume = 1600

    -- Expected result: 1995 year share = 900 / (900+1600) = 0.36
    CREATE TABLE #Expected (o_year int, mkt_share decimal(38,6));
    INSERT INTO #Expected (o_year, mkt_share) VALUES (1995, 0.36);

    -- Act
    SELECT * INTO #Actual
    FROM dbo.tpch_q08('BRAZIL', 'AMERICA', '1995-01-01', '1996-12-31', 'ECONOMY ANODIZED STEEL');

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q08_no_data
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo', 'part';
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';
    EXEC tSQLt.FakeTable 'dbo', 'orders';
    EXEC tSQLt.FakeTable 'dbo', 'customer';
    EXEC tSQLt.FakeTable 'dbo', 'nation';
    EXEC tSQLt.FakeTable 'dbo', 'region';
    EXEC tSQLt.FakeTable 'dbo', 'supplier';

    -- No rows inserted

    CREATE TABLE #Expected (o_year int, mkt_share decimal(38,6));
    -- Expected empty result set

    -- Act
    SELECT * INTO #Actual
    FROM dbo.tpch_q08('BRAZIL', 'AMERICA', '1995-01-01', '1996-12-31', 'ECONOMY ANODIZED STEEL');

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q08_null_parameters
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo', 'part';
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';
    EXEC tSQLt.FakeTable 'dbo', 'orders';
    EXEC tSQLt.FakeTable 'dbo', 'customer';
    EXEC tSQLt.FakeTable 'dbo', 'nation';
    EXEC tSQLt.FakeTable 'dbo', 'region';
    EXEC tSQLt.FakeTable 'dbo', 'supplier';

    INSERT INTO dbo.region (r_regionkey, r_name) VALUES (1, 'AMERICA');

    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey) VALUES (10, 'BRAZIL', 1);

    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES (100, 10);

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (500, 10);

    INSERT INTO dbo.part (p_partkey, p_type) VALUES (1000, 'ECONOMY ANODIZED STEEL');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate) VALUES (10000, 100, '1995-06-15');

    INSERT INTO dbo.lineitem (l_orderkey, l_partkey, l_suppkey, l_extendedprice, l_discount) VALUES (10000, 1000, 500, 1000.00, 0.0);

    CREATE TABLE #Expected (o_year int, mkt_share decimal(38,6));
    -- With NULL inputs the WHERE clause will never match, result set empty

    -- Act
    SELECT * INTO #Actual
    FROM dbo.tpch_q08(NULL, NULL, NULL, NULL, NULL);

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q08_zero_volume
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo', 'part';
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';
    EXEC tSQLt.FakeTable 'dbo', 'orders';
    EXEC tSQLt.FakeTable 'dbo', 'customer';
    EXEC tSQLt.FakeTable 'dbo', 'nation';
    EXEC tSQLt.FakeTable 'dbo', 'region';
    EXEC tSQLt.FakeTable 'dbo', 'supplier';

    INSERT INTO dbo.region (r_regionkey, r_name) VALUES (1, 'AMERICA');

    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey) VALUES
        (10, 'BRAZIL', 1),
        (20, 'USA', 1);

    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES (100, 10), (200, 20);

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (500, 10), (600, 20);

    INSERT INTO dbo.part (p_partkey, p_type) VALUES (1000, 'ECONOMY ANODIZED STEEL');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate) VALUES
        (10000, 100, '1996-03-10'),   -- target
        (20000, 200, '1996-04-15');   -- other

    -- Both rows have zero volume (discount = 1)
    INSERT INTO dbo.lineitem (l_orderkey, l_partkey, l_suppkey, l_extendedprice, l_discount) VALUES
        (10000, 1000, 500, 500.00, 1.0),
        (20000, 1000, 600, 800.00, 1.0);

    CREATE TABLE #Expected (o_year int, mkt_share decimal(38,6));
    INSERT INTO #Expected (o_year, mkt_share) VALUES (1996, NULL); -- division by zero yields NULL

    -- Act
    SELECT * INTO #Actual
    FROM dbo.tpch_q08('BRAZIL', 'AMERICA', '1995-01-01', '1996-12-31', 'ECONOMY ANODIZED STEEL');

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q08_boundary_dates
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo', 'part';
    EXEC tSQLt.FakeTable 'dbo', 'lineitem';
    EXEC tSQLt.FakeTable 'dbo', 'orders';
    EXEC tSQLt.FakeTable 'dbo', 'customer';
    EXEC tSQLt.FakeTable 'dbo', 'nation';
    EXEC tSQLt.FakeTable 'dbo', 'region';
    EXEC tSQLt.FakeTable 'dbo', 'supplier';

    INSERT INTO dbo.region (r_regionkey, r_name) VALUES (1, 'AMERICA');

    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey) VALUES (10, 'BRAZIL', 1);

    INSERT INTO dbo.customer (c_custkey, c_nationkey) VALUES (100, 10);

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (500, 10);

    INSERT INTO dbo.part (p_partkey, p_type) VALUES (1000, 'ECONOMY ANODIZED STEEL');

    -- Orders exactly on the date boundaries
    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate) VALUES
        (10000, 100, '1995-01-01'),   -- start boundary
        (10001, 100, '1996-12-31');   -- end boundary

    INSERT INTO dbo.lineitem (l_orderkey, l_partkey, l_suppkey, l_extendedprice, l_discount) VALUES
        (10000, 1000, 500, 1000.00, 0.1),   -- volume = 900
        (10001, 1000, 500, 2000.00, 0.2);   -- volume = 1600

    CREATE TABLE #Expected (o_year int, mkt_share decimal(38,6));
    INSERT INTO #Expected (o_year, mkt_share) VALUES (1995, 1.0); -- only 1995 row, all volume belongs to target nation
    INSERT INTO #Expected (o_year, mkt_share) VALUES (1996, 1.0); -- only 1996 row, all volume belongs to target nation

    -- Act
    SELECT * INTO #Actual
    FROM dbo.tpch_q08('BRAZIL', 'AMERICA', '1995-01-01', '1996-12-31', 'ECONOMY ANODIZED STEEL');

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END
GO