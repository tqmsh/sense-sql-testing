CREATE PROCEDURE Test_Feb03.test_tpch_q09_basic_match
AS
BEGIN
    -- Fake source tables
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.part';
    EXEC tSQLt.FakeTable 'dbo.partsupp';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';

    -- Populate nation
    INSERT INTO dbo.nation (n_nationkey, n_name)
    VALUES (1, 'USA'),
           (2, 'CHINA');

    -- Populate supplier
    INSERT INTO dbo.supplier (s_suppkey, s_nationkey)
    VALUES (10, 1),
           (20, 2);

    -- Populate part
    INSERT INTO dbo.part (p_partkey, p_name)
    VALUES (100, 'green widget'),
           (101, 'red widget');

    -- Populate partsupp
    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost)
    VALUES (100, 10, 5.00),
           (100, 20, 6.00);

    -- Populate orders
    INSERT INTO dbo.orders (o_orderkey, o_orderdate)
    VALUES (1000, '1995-05-01'),
           (1001, '1995-09-01');

    -- Populate lineitem
    INSERT INTO dbo.lineitem (l_orderkey, l_partkey, l_suppkey, l_extendedprice, l_discount, l_quantity)
    VALUES (1000, 100, 10, 100.00, 0.10, 2),
           (1001, 100, 20, 200.00, 0.20, 3);

    -- Expected result
    CREATE TABLE #Expected_basic (
        nation   VARCHAR(50),
        o_year   INT,
        sum_profit DECIMAL(18,2)
    );

    INSERT INTO #Expected_basic (nation, o_year, sum_profit)
    VALUES ('USA',   1995, 80.00),
           ('CHINA', 1995, 142.00);

    -- Actual result
    SELECT *
    INTO   #Actual_basic
    FROM   dbo.tpch_q09('%green%');

    -- Assertion
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_basic', @Actual = '#Actual_basic';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q09_no_match
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.part';
    EXEC tSQLt.FakeTable 'dbo.partsupp';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES (1,'USA');
    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (10,1);
    INSERT INTO dbo.part (p_partkey, p_name) VALUES (100,'green widget');
    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost) VALUES (100,10,5.00);
    INSERT INTO dbo.orders (o_orderkey, o_orderdate) VALUES (1000,'1995-05-01');
    INSERT INTO dbo.lineitem (l_orderkey,l_partkey,l_suppkey,l_extendedprice,l_discount,l_quantity)
    VALUES (1000,100,10,100.00,0.10,2);

    -- Expected: empty set with correct columns
    CREATE TABLE #Expected_no_match (
        nation   VARCHAR(50),
        o_year   INT,
        sum_profit DECIMAL(18,2)
    );

    SELECT *
    INTO   #Actual_no_match
    FROM   dbo.tpch_q09('%blue%');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_no_match', @Actual = '#Actual_no_match';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q09_null_parameter
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.part';
    EXEC tSQLt.FakeTable 'dbo.partsupp';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES (1,'USA');
    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (10,1);
    INSERT INTO dbo.part (p_partkey, p_name) VALUES (100,'green widget');
    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost) VALUES (100,10,5.00);
    INSERT INTO dbo.orders (o_orderkey, o_orderdate) VALUES (1000,'1995-05-01');
    INSERT INTO dbo.lineitem (l_orderkey,l_partkey,l_suppkey,l_extendedprice,l_discount,l_quantity)
    VALUES (1000,100,10,100.00,0.10,2);

    CREATE TABLE #Expected_null (
        nation   VARCHAR(50),
        o_year   INT,
        sum_profit DECIMAL(18,2)
    );

    SELECT *
    INTO   #Actual_null
    FROM   dbo.tpch_q09(NULL);

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_null', @Actual = '#Actual_null';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q09_all_match
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.part';
    EXEC tSQLt.FakeTable 'dbo.partsupp';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES (1,'GERMANY'), (2,'FRANCE');

    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (10,1), (20,2);

    INSERT INTO dbo.part (p_partkey, p_name) VALUES (100,'green widget'), (101,'blue widget');

    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost)
    VALUES (100,10,4.00),
           (101,20,7.00);

    INSERT INTO dbo.orders (o_orderkey, o_orderdate)
    VALUES (1000,'1996-03-15'),
           (1001,'1996-07-20');

    INSERT INTO dbo.lineitem (l_orderkey,l_partkey,l_suppkey,l_extendedprice,l_discount,l_quantity)
    VALUES (1000,100,10,150.00,0.05,5),
           (1001,101,20,250.00,0.10,4);

    CREATE TABLE #Expected_all (
        nation   VARCHAR(50),
        o_year   INT,
        sum_profit DECIMAL(18,2)
    );

    -- Calculations:
    -- Row1: 150*(0.95)=142.5 - 4*5=20 => 122.5
    -- Row2: 250*(0.90)=225 - 7*4=28 => 197
    INSERT INTO #Expected_all (nation, o_year, sum_profit)
    VALUES ('GERMANY',1996,122.50),
           ('FRANCE',1996,197.00);

    SELECT *
    INTO   #Actual_all
    FROM   dbo.tpch_q09('%');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_all', @Actual = '#Actual_all';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q09_null_orderdate
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.lineitem';
    EXEC tSQLt.FakeTable 'dbo.orders';
    EXEC tSQLt.FakeTable 'dbo.part';
    EXEC tSQLt.FakeTable 'dbo.partsupp';
    EXEC tSQLt.FakeTable 'dbo.supplier';
    EXEC tSQLt.FakeTable 'dbo.nation';

    INSERT INTO dbo.nation (n_nationkey, n_name) VALUES (1,'JAPAN');
    INSERT INTO dbo.supplier (s_suppkey, s_nationkey) VALUES (10,1);
    INSERT INTO dbo.part (p_partkey, p_name) VALUES (100,'green gadget');
    INSERT INTO dbo.partsupp (ps_partkey, ps_suppkey, ps_supplycost) VALUES (100,10,3.00);
    INSERT INTO dbo.orders (o_orderkey, o_orderdate) VALUES (1000,NULL);
    INSERT INTO dbo.lineitem (l_orderkey,l_partkey,l_suppkey,l_extendedprice,l_discount,l_quantity)
    VALUES (1000,100,10,120.00,0.10,2);

    CREATE TABLE #Expected_null_date (
        nation   VARCHAR(50),
        o_year   INT,
        sum_profit DECIMAL(18,2)
    );

    SELECT *
    INTO   #Actual_null_date
    FROM   dbo.tpch_q09('%green%');

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected_null_date', @Actual = '#Actual_null_date';
END;
GO