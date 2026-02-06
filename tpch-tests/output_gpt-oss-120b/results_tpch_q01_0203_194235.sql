CREATE PROCEDURE Test_Feb03.test_tpch_q01_basic_filter
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.LINEITEM';

    INSERT INTO dbo.LINEITEM
    (
        l_returnflag,
        l_linestatus,
        l_quantity,
        l_extendedprice,
        l_discount,
        l_tax,
        l_shipdate
    )
    VALUES
    (
        'N',            -- return flag
        'O',            -- line status
        10.0,           -- quantity
        1000.00,        -- extended price
        0.05,           -- discount
        0.10,           -- tax
        DATEADD(DAY, -100, '1998-12-01')  -- shipdate before cutoff (90 days)
    );

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q01('1998-12-01', 90);

    CREATE TABLE #Expected
    (
        l_returnflag char(1),
        l_linestatus char(1),
        sum_qty decimal(38,6),
        sum_base_price decimal(38,6),
        sum_disc_price decimal(38,6),
        sum_charge decimal(38,6),
        avg_qty decimal(38,6),
        avg_price decimal(38,6),
        avg_disc decimal(38,6),
        count_order bigint
    );

    INSERT INTO #Expected
    VALUES
    (
        'N',
        'O',
        10.0,                      -- sum_qty
        1000.00,                   -- sum_base_price
        1000.00 * (1 - 0.05),      -- sum_disc_price = 950.00
        1000.00 * (1 - 0.05) * (1 + 0.10), -- sum_charge = 1045.00
        10.0,                      -- avg_qty
        1000.00,                   -- avg_price
        0.05,                      -- avg_disc
        1                          -- count_order
    );

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q01_no_rows_due_to_date
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.LINEITEM';

    INSERT INTO dbo.LINEITEM
    (
        l_returnflag,
        l_linestatus,
        l_quantity,
        l_extendedprice,
        l_discount,
        l_tax,
        l_shipdate
    )
    VALUES
    (
        'R',
        'F',
        5.0,
        500.00,
        0.02,
        0.08,
        DATEADD(DAY, 10, '1998-12-01')  -- shipdate after cutoff
    );

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q01('1998-12-01', 90);

    CREATE TABLE #Expected
    (
        l_returnflag char(1),
        l_linestatus char(1),
        sum_qty decimal(38,6),
        sum_base_price decimal(38,6),
        sum_disc_price decimal(38,6),
        sum_charge decimal(38,6),
        avg_qty decimal(38,6),
        avg_price decimal(38,6),
        avg_disc decimal(38,6),
        count_order bigint
    );

    -- Expected empty result set (no rows)
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q01_multiple_groups
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.LINEITEM';

    INSERT INTO dbo.LINEITEM
    (
        l_returnflag,
        l_linestatus,
        l_quantity,
        l_extendedprice,
        l_discount,
        l_tax,
        l_shipdate
    )
    VALUES
    ( 'N', 'O', 10.0, 1000.00, 0.05, 0.10, DATEADD(DAY, -120, '1998-12-01') ),
    ( 'N', 'O', 5.0 ,  500.00, 0.05, 0.10, DATEADD(DAY, -110, '1998-12-01') ),
    ( 'R', 'F', 7.0 ,  700.00, 0.02, 0.08, DATEADD(DAY, -130, '1998-12-01') );

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q01('1998-12-01', 90);

    CREATE TABLE #Expected
    (
        l_returnflag char(1),
        l_linestatus char(1),
        sum_qty decimal(38,6),
        sum_base_price decimal(38,6),
        sum_disc_price decimal(38,6),
        sum_charge decimal(38,6),
        avg_qty decimal(38,6),
        avg_price decimal(38,6),
        avg_disc decimal(38,6),
        count_order bigint
    );

    INSERT INTO #Expected
    VALUES
    ( 'N', 'O',
        15.0,
        1500.00,
        1500.00 * (1 - 0.05),                 -- 1425.00
        1500.00 * (1 - 0.05) * (1 + 0.10),    -- 1567.50
        7.5,
        750.00,
        0.05,
        2
    ),
    ( 'R', 'F',
        7.0,
        700.00,
        700.00 * (1 - 0.02),                 -- 686.00
        700.00 * (1 - 0.02) * (1 + 0.08),    -- 740.88
        7.0,
        700.00,
        0.02,
        1
    );

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q01_null_base_date
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.LINEITEM';

    INSERT INTO dbo.LINEITEM
    (
        l_returnflag,
        l_linestatus,
        l_quantity,
        l_extendedprice,
        l_discount,
        l_tax,
        l_shipdate
    )
    VALUES
    ( 'N', 'O', 10.0, 1000.00, 0.05, 0.10, DATEADD(DAY, -100, '1998-12-01') );

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q01(NULL, 90);

    CREATE TABLE #Expected
    (
        l_returnflag char(1),
        l_linestatus char(1),
        sum_qty decimal(38,6),
        sum_base_price decimal(38,6),
        sum_disc_price decimal(38,6),
        sum_charge decimal(38,6),
        avg_qty decimal(38,6),
        avg_price decimal(38,6),
        avg_disc decimal(38,6),
        count_order bigint
    );

    -- Expect empty set because comparison with NULL yields UNKNOWN
    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q01_boundary_delta_zero
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.LINEITEM';

    INSERT INTO dbo.LINEITEM
    (
        l_returnflag,
        l_linestatus,
        l_quantity,
        l_extendedprice,
        l_discount,
        l_tax,
        l_shipdate
    )
    VALUES
    ( 'A', 'B', 3.0, 300.00, 0.01, 0.05, '1998-12-01' ),    -- exactly on base_date
    ( 'A', 'B', 2.0, 200.00, 0.01, 0.05, DATEADD(DAY, -1, '1998-12-01') );

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q01('1998-12-01', 0);

    CREATE TABLE #Expected
    (
        l_returnflag char(1),
        l_linestatus char(1),
        sum_qty decimal(38,6),
        sum_base_price decimal(38,6),
        sum_disc_price decimal(38,6),
        sum_charge decimal(38,6),
        avg_qty decimal(38,6),
        avg_price decimal(38,6),
        avg_disc decimal(38,6),
        count_order bigint
    );

    INSERT INTO #Expected
    VALUES
    ( 'A', 'B',
        5.0,
        500.00,
        500.00 * (1 - 0.01),                 -- 495.00
        500.00 * (1 - 0.01) * (1 + 0.05),    -- 519.75
        2.5,
        250.00,
        0.01,
        2
    );

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO

CREATE PROCEDURE Test_Feb03.test_tpch_q01_negative_delta
AS
BEGIN
    EXEC tSQLt.FakeTable 'dbo.LINEITEM';

    INSERT INTO dbo.LINEITEM
    (
        l_returnflag,
        l_linestatus,
        l_quantity,
        l_extendedprice,
        l_discount,
        l_tax,
        l_shipdate
    )
    VALUES
    ( 'X', 'Y', 8.0, 800.00, 0.03, 0.07, DATEADD(DAY, -5, '1998-12-01') ),   -- within 5 days after base_date
    ( 'X', 'Y', 4.0, 400.00, 0.03, 0.07, DATEADD(DAY, -20,'1998-12-01') );

    SELECT *
    INTO #Actual
    FROM dbo.tpch_q01('1998-12-01', -10);

    CREATE TABLE #Expected
    (
        l_returnflag char(1),
        l_linestatus char(1),
        sum_qty decimal(38,6),
        sum_base_price decimal(38,6),
        sum_disc_price decimal(38,6),
        sum_charge decimal(38,6),
        avg_qty decimal(38,6),
        avg_price decimal(38,6),
        avg_disc decimal(38,6),
        count_order bigint
    );

    INSERT INTO #Expected
    VALUES
    ( 'X', 'Y',
        12.0,
        1200.00,
        1200.00 * (1 - 0.03),                 -- 1164.00
        1200.00 * (1 - 0.03) * (1 + 0.07),    -- 1245.48
        6.0,
        600.00,
        0.03,
        2
    );

    EXEC tSQLt.AssertEqualsTable @Expected = '#Expected', @Actual = '#Actual';
END;
GO