CREATE PROCEDURE Test_Feb03.[test_tpch_q02_basic_match]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.part';
    EXEC tSQLt.FakeTable 'dbo.partsupp';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';
    EXEC tSQLt.FakeTable 'dbo.region';

    INSERT INTO dbo.part (p_partkey, p_size, p_type, p_mfgr)
    VALUES (1, 15, 'SMALL BRASS', 'MFGR#1');

    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost)
    VALUES (1, 10, 10.00),   -- cheaper supplier
           (1, 20, 20.00);   -- more expensive supplier

    INSERT INTO dbo.supplier (s_suppkey, s_acctbal, s_name, s_address, s_phone, s_comment, s_nationkey)
    VALUES (10, 1000.00, 'Supplier A', 'Addr A', '123-456', 'Comment A', 100),
           (20, 2000.00, 'Supplier B', 'Addr B', '789-012', 'Comment B', 200);

    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey)
    VALUES (100, 'NationA', 1000),
           (200, 'NationB', 1000);

    INSERT INTO dbo.region (r_regionkey, r_name)
    VALUES (1000, 'EUROPE');

    CREATE TABLE #Expected (
        s_acctbal       numeric(12,2),
        s_name          varchar(25),
        n_name          varchar(25),
        p_partkey       int,
        p_mfgr          varchar(25),
        s_address       varchar(40),
        s_phone         varchar(15),
        s_comment       varchar(100)
    );

    INSERT INTO #Expected (s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment)
    VALUES (1000.00, 'Supplier A', 'NationA', 1, 'MFGR#1', 'Addr A', '123-456', 'Comment A');

    SELECT * INTO #Actual FROM dbo.tpch_q02(15, '%BRASS', 'EUROPE');

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q02_no_match_due_to_size]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.part';
    EXEC tSQLt.FakeTable 'dbo.partsupp';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';
    EXEC tSQLt.FakeTable 'dbo.region';

    INSERT INTO dbo.part (p_partkey, p_size, p_type, p_mfgr)
    VALUES (1, 20, 'SMALL BRASS', 'MFGR#1'); -- size does NOT match @p_size = 15

    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost)
    VALUES (1, 10, 5.00);

    INSERT INTO dbo.supplier (s_suppkey, s_acctbal, s_name, s_address, s_phone, s_comment, s_nationkey)
    VALUES (10, 500.00, 'Supplier X', 'Addr X', '111-222', 'Comment X', 300);

    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey)
    VALUES (300, 'NationX', 2000);

    INSERT INTO dbo.region (r_regionkey, r_name)
    VALUES (2000, 'EUROPE');

    CREATE TABLE #Expected (
        s_acctbal       numeric(12,2),
        s_name          varchar(25),
        n_name          varchar(25),
        p_partkey       int,
        p_mfgr          varchar(25),
        s_address       varchar(40),
        s_phone         varchar(15),
        s_comment       varchar(100)
    );

    SELECT * INTO #Actual FROM dbo.tpch_q02(15, '%BRASS', 'EUROPE');

    -- Assert - expect empty result set
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q02_type_like_mismatch]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.part';
    EXEC tSQLt.FakeTable 'dbo.partsupp';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';
    EXEC tSQLt.FakeTable 'dbo.region';

    INSERT INTO dbo.part (p_partkey, p_size, p_type, p_mfgr)
    VALUES (1, 15, 'SMALL STEEL', 'MFGR#2'); -- type does NOT end with BRASS

    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost)
    VALUES (1, 10, 12.00);

    INSERT INTO dbo.supplier (s_suppkey, s_acctbal, s_name, s_address, s_phone, s_comment, s_nationkey)
    VALUES (10, 750.00, 'Supplier Y', 'Addr Y', '333-444', 'Comment Y', 400);

    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey)
    VALUES (400, 'NationY', 3000);

    INSERT INTO dbo.region (r_regionkey, r_name)
    VALUES (3000, 'EUROPE');

    CREATE TABLE #Expected (
        s_acctbal       numeric(12,2),
        s_name          varchar(25),
        n_name          varchar(25),
        p_partkey       int,
        p_mfgr          varchar(25),
        s_address       varchar(40),
        s_phone         varchar(15),
        s_comment       varchar(100)
    );

    SELECT * INTO #Actual FROM dbo.tpch_q02(15, '%BRASS', 'EUROPE');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q02_region_mismatch]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.part';
    EXEC tSQLt.FakeTable 'dbo.partsupp';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';
    EXEC tSQLt.FakeTable 'dbo.region';

    INSERT INTO dbo.part (p_partkey, p_size, p_type, p_mfgr)
    VALUES (1, 15, 'SMALL BRASS', 'MFGR#1');

    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost)
    VALUES (1, 10, 8.00);

    INSERT INTO dbo.supplier (s_suppkey, s_acctbal, s_name, s_address, s_phone, s_comment, s_nationkey)
    VALUES (10, 1200.00, 'Supplier Z', 'Addr Z', '555-666', 'Comment Z', 500);

    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey)
    VALUES (500, 'NationZ', 4000);

    INSERT INTO dbo.region (r_regionkey, r_name)
    VALUES (4000, 'ASIA'); -- different region

    CREATE TABLE #Expected (
        s_acctbal       numeric(12,2),
        s_name          varchar(25),
        n_name          varchar(25),
        p_partkey       int,
        p_mfgr          varchar(25),
        s_address       varchar(40),
        s_phone         varchar(15),
        s_comment       varchar(100)
    );

    SELECT * INTO #Actual FROM dbo.tpch_q02(15, '%BRASS', 'EUROPE');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q02_min_supplycost_selection]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.part';
    EXEC tSQLt.FakeTable 'dbo.partsupp';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';
    EXEC tSQLt.FakeTable 'dbo.region';

    INSERT INTO dbo.part (p_partkey, p_size, p_type, p_mfgr)
    VALUES (1, 15, 'MEDIUM BRASS', 'MFGR#3');

    -- Multiple suppliers for same part with varying costs
    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost)
    VALUES (1, 10, 15.00),   -- higher cost
           (1, 20, 10.00),   -- lowest cost (should be returned)
           (1, 30, 12.00);   -- middle cost

    INSERT INTO dbo.supplier (s_suppkey, s_acctbal, s_name, s_address, s_phone, s_comment, s_nationkey)
    VALUES (10, 800.00, 'Supplier High', 'Addr High', '777-888', 'Comment High', 600),
           (20, 900.00, 'Supplier Low',  'Addr Low',  '999-000', 'Comment Low',  700),
           (30, 850.00, 'Supplier Mid',  'Addr Mid',  '111-222', 'Comment Mid',  800);

    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey)
    VALUES (600, 'NationHigh', 5000),
           (700, 'NationLow',  5000),
           (800, 'NationMid',  5000);

    INSERT INTO dbo.region (r_regionkey, r_name)
    VALUES (5000, 'EUROPE');

    CREATE TABLE #Expected (
        s_acctbal       numeric(12,2),
        s_name          varchar(25),
        n_name          varchar(25),
        p_partkey       int,
        p_mfgr          varchar(25),
        s_address       varchar(40),
        s_phone         varchar(15),
        s_comment       varchar(100)
    );

    INSERT INTO #Expected (s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment)
    VALUES (900.00, 'Supplier Low', 'NationLow', 1, 'MFGR#3', 'Addr Low', '999-000', 'Comment Low');

    SELECT * INTO #Actual FROM dbo.tpch_q02(15, '%BRASS', 'EUROPE');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q02_null_parameters]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.part';
    EXEC tSQLt.FakeTable 'dbo.partsupp';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';
    EXEC tSQLt.FakeTable 'dbo.region';

    -- No data needed; any NULL comparison will filter out rows

    CREATE TABLE #Expected (
        s_acctbal       numeric(12,2),
        s_name          varchar(25),
        n_name          varchar(25),
        p_partkey       int,
        p_mfgr          varchar(25),
        s_address       varchar(40),
        s_phone         varchar(15),
        s_comment       varchar(100)
    );

    SELECT * INTO #Actual FROM dbo.tpch_q02(NULL, NULL, NULL);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q02_boundary_size_zero]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.part';
    EXEC tSQLt.FakeTable 'dbo.partsupp';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';
    EXEC tSQLt.FakeTable 'dbo.region';

    INSERT INTO dbo.part (p_partkey, p_size, p_type, p_mfgr)
    VALUES (1, 0, 'ZERO BRASS', 'MFGR#Z'); -- size matches boundary test

    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost)
    VALUES (1, 10, 1.00);

    INSERT INTO dbo.supplier (s_suppkey, s_acctbal, s_name, s_address, s_phone, s_comment, s_nationkey)
    VALUES (10, 300.00, 'Supplier Zero', 'Addr Zero', '333-333', 'Comment Zero', 900);

    INSERT INTO dbo.nation (n_nationkey, n_name, n_regionkey)
    VALUES (900, 'NationZero', 6000);

    INSERT INTO dbo.region (r_regionkey, r_name)
    VALUES (6000, 'EUROPE');

    CREATE TABLE #Expected (
        s_acctbal       numeric(12,2),
        s_name          varchar(25),
        n_name          varchar(25),
        p_partkey       int,
        p_mfgr          varchar(25),
        s_address       varchar(40),
        s_phone         varchar(15),
        s_comment       varchar(100)
    );

    INSERT INTO #Expected (s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment)
    VALUES (300.00, 'Supplier Zero', 'NationZero', 1, 'MFGR#Z', 'Addr Zero', '333-333', 'Comment Zero');

    SELECT * INTO #Actual FROM dbo.tpch_q02(0, '%BRASS', 'EUROPE');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO