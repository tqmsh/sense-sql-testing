CREATE PROCEDURE Test_Feb03.[test_tpch_q10_basic_match]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES (1, 'USA');

    INSERT INTO dbo.customer (c_custkey, c_name, c_acctbal, c_nationkey, c_address, c_phone, c_comment)
    VALUES (100, 'Customer#100', 5000, 1, 'Address100', '555-0100', 'Comment100');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate)
    VALUES (2000, 100, '1993-10-15');

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_returnflag)
    VALUES (2000, 100.00, 0.10, 'R');

    -- Expected result
    CREATE TABLE #Expected_basic (
        c_custkey      INT,
        c_name        VARCHAR(25),
        revenue       DECIMAL(38,6),
        c_acctbal     DECIMAL(15,2),
        n_name        VARCHAR(25),
        c_address     VARCHAR(40),
        c_phone       VARCHAR(15),
        c_comment     VARCHAR(117)
    );

    INSERT INTO #Expected_basic (c_custkey, c_name, revenue, c_acctbal, n_name, c_address, c_phone, c_comment)
    VALUES (100, 'Customer#100', 90.00, 5000.00, 'USA', 'Address100', '555-0100', 'Comment100');

    -- Act
    SELECT *
    INTO #Actual_basic
    FROM dbo.tpch_q10('1993-10-01', 3, 'R');

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_basic', @Actual = '#Actual_basic';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q10_no_match_returnflag]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES (2, 'CAN');

    INSERT INTO dbo.customer (c_custkey, c_name, c_acctbal, c_nationkey, c_address, c_phone, c_comment)
    VALUES (101, 'Customer#101', 3000, 2, 'Address101', '555-0101', 'Comment101');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate)
    VALUES (2001, 101, '1993-11-01');

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_returnflag)
    VALUES (2001, 200.00, 0.05, 'N'); -- Different return flag

    -- Expected result: empty
    CREATE TABLE #Expected_no_match (
        c_custkey      INT,
        c_name        VARCHAR(25),
        revenue       DECIMAL(38,6),
        c_acctbal     DECIMAL(15,2),
        n_name        VARCHAR(25),
        c_address     VARCHAR(40),
        c_phone       VARCHAR(15),
        c_comment     VARCHAR(117)
    );

    -- Act
    SELECT *
    INTO #Actual_no_match
    FROM dbo.tpch_q10('1993-10-01', 3, 'R');

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_no_match', @Actual = '#Actual_no_match';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q10_boundary_start_date]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES (3, 'MEX');

    INSERT INTO dbo.customer (c_custkey, c_name, c_acctbal, c_nationkey, c_address, c_phone, c_comment)
    VALUES (102, 'Customer#102', 2500, 3, 'Address102', '555-0102', 'Comment102');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate)
    VALUES (2002, 102, '1993-10-01'); -- Exactly start date

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_returnflag)
    VALUES (2002, 150.00, 0.20, 'R');

    -- Expected result
    CREATE TABLE #Expected_boundary_start (
        c_custkey      INT,
        c_name        VARCHAR(25),
        revenue       DECIMAL(38,6),
        c_acctbal     DECIMAL(15,2),
        n_name        VARCHAR(25),
        c_address     VARCHAR(40),
        c_phone       VARCHAR(15),
        c_comment     VARCHAR(117)
    );

    INSERT INTO #Expected_boundary_start
    VALUES (102, 'Customer#102', 120.00, 2500.00, 'MEX', 'Address102', '555-0102', 'Comment102');

    -- Act
    SELECT *
    INTO #Actual_boundary_start
    FROM dbo.tpch_q10('1993-10-01', 3, 'R');

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_boundary_start', @Actual = '#Actual_boundary_start';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q10_boundary_exclusive_end]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES (4, 'GER');

    INSERT INTO dbo.customer (c_custkey, c_name, c_acctbal, c_nationkey, c_address, c_phone, c_comment)
    VALUES (103, 'Customer#103', 4000, 4, 'Address103', '555-0103', 'Comment103');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate)
    VALUES (2003, 103, '1993-12-31'); -- Exactly end date (1993-10-01 + 3 months = 1993-12-31)

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_returnflag)
    VALUES (2003, 300.00, 0.10, 'R');

    -- Expected result: empty because end date is exclusive
    CREATE TABLE #Expected_exclusive_end (
        c_custkey      INT,
        c_name        VARCHAR(25),
        revenue       DECIMAL(38,6),
        c_acctbal     DECIMAL(15,2),
        n_name        VARCHAR(25),
        c_address     VARCHAR(40),
        c_phone       VARCHAR(15),
        c_comment     VARCHAR(117)
    );

    -- Act
    SELECT *
    INTO #Actual_exclusive_end
    FROM dbo.tpch_q10('1993-10-01', 3, 'R');

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_exclusive_end', @Actual = '#Actual_exclusive_end';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q10_months_zero]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES (5, 'FRA');

    INSERT INTO dbo.customer (c_custkey, c_name, c_acctbal, c_nationkey, c_address, c_phone, c_comment)
    VALUES (104, 'Customer#104', 3500, 5, 'Address104', '555-0104', 'Comment104');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate)
    VALUES (2004, 104, '1994-01-01');

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_returnflag)
    VALUES (2004, 120.00, 0.15, 'R');

    -- Expected result: empty because month range is zero
    CREATE TABLE #Expected_months_zero (
        c_custkey      INT,
        c_name        VARCHAR(25),
        revenue       DECIMAL(38,6),
        c_acctbal     DECIMAL(15,2),
        n_name        VARCHAR(25),
        c_address     VARCHAR(40),
        c_phone       VARCHAR(15),
        c_comment     VARCHAR(117)
    );

    -- Act
    SELECT *
    INTO #Actual_months_zero
    FROM dbo.tpch_q10('1994-01-01', 0, 'R');

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_months_zero', @Actual = '#Actual_months_zero';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q10_null_date]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES (6, 'JPN');

    INSERT INTO dbo.customer (c_custkey, c_name, c_acctbal, c_nationkey, c_address, c_phone, c_comment)
    VALUES (105, 'Customer#105', 2000, 6, 'Address105', '555-0105', 'Comment105');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate)
    VALUES (2005, 105, '1995-05-05');

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_returnflag)
    VALUES (2005, 250.00, 0.20, 'R');

    -- Expected result: empty because @date is NULL
    CREATE TABLE #Expected_null_date (
        c_custkey      INT,
        c_name        VARCHAR(25),
        revenue       DECIMAL(38,6),
        c_acctbal     DECIMAL(15,2),
        n_name        VARCHAR(25),
        c_address     VARCHAR(40),
        c_phone       VARCHAR(15),
        c_comment     VARCHAR(117)
    );

    -- Act
    SELECT *
    INTO #Actual_null_date
    FROM dbo.tpch_q10(NULL, 3, 'R');

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_null_date', @Actual = '#Actual_null_date';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q10_null_returnflag]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES (7, 'CHN');

    INSERT INTO dbo.customer (c_custkey, c_name, c_acctbal, c_nationkey, c_address, c_phone, c_comment)
    VALUES (106, 'Customer#106', 1800, 7, 'Address106', '555-0106', 'Comment106');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate)
    VALUES (2006, 106, '1996-06-06');

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_returnflag)
    VALUES (2006, 180.00, 0.10, 'R');

    -- Expected result: empty because @returnflag is NULL
    CREATE TABLE #Expected_null_flag (
        c_custkey      INT,
        c_name        VARCHAR(25),
        revenue       DECIMAL(38,6),
        c_acctbal     DECIMAL(15,2),
        n_name        VARCHAR(25),
        c_address     VARCHAR(40),
        c_phone       VARCHAR(15),
        c_comment     VARCHAR(117)
    );

    -- Act
    SELECT *
    INTO #Actual_null_flag
    FROM dbo.tpch_q10('1996-01-01', 3, NULL);

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_null_flag', @Actual = '#Actual_null_flag';
END;
GO

CREATE PROCEDURE Test_Feb03.[test_tpch_q10_multiple_customers]
AS
BEGIN
    -- Arrange
    EXEC tSQLt.FakeTable 'dbo.customer';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES (8, 'BRA'), (9, 'ARG');

    INSERT INTO dbo.customer (c_custkey, c_name, c_acctbal, c_nationkey, c_address, c_phone, c_comment)
    VALUES 
        (107, 'Customer#107', 6000, 8, 'Address107', '555-0107', 'Comment107'),
        (108, 'Customer#108', 4500, 9, 'Address108', '555-0108', 'Comment108');

    INSERT INTO dbo.orders (o_orderkey, o_custkey, o_orderdate)
    VALUES 
        (2007, 107, '1993-10-10'),
        (2008, 107, '1993-11-15'),
        (2009, 108, '1993-11-20');

    INSERT INTO dbo.lineitem (l_orderkey, l_extendedprice, l_discount, l_returnflag)
    VALUES 
        (2007, 100.00, 0.00, 'R'),   -- revenue 100
        (2008, 200.00, 0.10, 'R'),   -- revenue 180
        (2009, 150.00, 0.20, 'R');   -- revenue 120

    -- Expected result: two rows with summed revenue per customer
    CREATE TABLE #Expected_multi (
        c_custkey      INT,
        c_name        VARCHAR(25),
        revenue       DECIMAL(38,6),
        c_acctbal     DECIMAL(15,2),
        n_name        VARCHAR(25),
        c_address     VARCHAR(40),
        c_phone       VARCHAR(15),
        c_comment     VARCHAR(117)
    );

    INSERT INTO #Expected_multi
    VALUES 
        (107, 'Customer#107', 280.00, 6000.00, 'BRA', 'Address107', '555-0107', 'Comment107'), -- 100+180
        (108, 'Customer#108', 120.00, 4500.00, 'ARG', 'Address108', '555-0108', 'Comment108');

    -- Act
    SELECT *
    INTO #Actual_multi
    FROM dbo.tpch_q10('1993-10-01', 3, 'R');

    -- Assert
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_multi', @Actual = '#Actual_multi';
END;
GO