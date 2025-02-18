DECLARE	@date_from	DATE = '2023-01-01';
DECLARE	@date_to	DATE = '2023-01-31';

SET NOCOUNT ON;
SET XACT_ABORT ON;

;WITH top_orders
AS
(
	SELECT	ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC)	AS rn,
			o_custkey,
			o_orderkey
	FROM	dbo.orders
	WHERE	o_orderdate >= @date_from
			AND o_orderdate <= @date_to
)
SELECT	*
FROM	top_orders AS t_o
		CROSS APPLY
		(
			SELECT	SUM(li.l_extendedprice * (1.0 - li.l_discount)) AS order_sum
			FROM	dbo.lineitems AS li
			WHERE	li.l_orderkey = t_o.o_orderkey
		) AS order_sum
WHERE	rn <= 3;

SELECT	r.r_name,
		COUNT_BIG(DISTINCT c.c_custkey)	AS	num_customers,
		COUNT_BIG(DISTINCT o.o_orderkey)	AS	num_orders,
		FORMAT
		(
			SUM(val_orders),
			'#,##0.00',
			'en-us'
		)				AS	c_val_orders
FROM	dbo.regions AS r
		INNER JOIN dbo.nations AS n
		ON (r.r_regionkey = n.n_regionkey)
		INNER JOIN dbo.customers AS c
		ON (n.n_nationkey = c.c_nationkey)
		INNER JOIN
		(
			SELECT	ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC, o.o_orderkey DESC)	AS	rn,
					o.o_custkey,
					o.o_orderkey,
					ISNULL(SUM(l.l_extendedprice * (1.0 - l.l_discount)), 0)	AS	val_orders
			FROM	dbo.orders AS o
					LEFT JOIN dbo.lineitems AS l
					ON (o.o_orderkey = l.l_orderkey)
			WHERE	o.o_orderdate BETWEEN @date_from AND @date_to
			GROUP BY
					o.o_custkey,
					o.o_orderdate,
					o.o_orderkey
		) AS o
		ON
		(
			c.c_custkey = o.o_custkey
			AND o.rn <= 3
		)
GROUP BY
		r.r_name
ORDER BY
		r.r_name
OPTION (RECOMPILE);
GO