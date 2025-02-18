USE ERP_Demo;
GO

SELECT [type]
FROM
(
	VALUES ('1-URGENT'),
			('2-HIGH'),
			('3-MEDIUM'),
			('4-NOT SPECIFIED'),
			('5-LOW')
) AS priority(type)

--ALTER TABLE dbo.orders
--ALTER COLUMN o_orderdate DATE NOT NULL;
--GO

CREATE NONCLUSTERED INDEX priority_date
ON dbo.orders
(
	o_orderpriority,
	o_orderdate
);
GO

SET STATISTICS TIME, IO ON;
GO

SELECT	o_orderpriority,
		MAX(o_orderdate)	AS LastOrderDate
FROM	dbo.Orders
WHERE	o_orderpriority = '5-LOW' (Variable????!
)
GROUP BY
		o_orderpriority;
GO

;WITH prioritylist
AS
(
	SELECT [type]
	FROM
	(
		VALUES ('1-URGENT'),
				('2-HIGH'),
				('3-MEDIUM'),
				('4-NOT SPECIFIED'),
				('5-LOW')
	) AS priority(type)
)
SELECT	pl.[type]		AS o_orderpriority,
		(
			SELECT	MAX(o_orderdate)
			FROM	dbo.orders
			WHERE	o_orderpriority = pl.[type]
		) AS LastOrderDate
FROM	prioritylist AS pl
GO

;WITH prioritylist
AS
(
	SELECT [type]
	FROM
	(
		VALUES ('1-URGENT'),
				('2-HIGH'),
				('3-MEDIUM'),
				('4-NOT SPECIFIED'),
				('5-LOW')
	) AS priority(type)
)
SELECT	pl.[type]		AS o_orderpriority,
		lod.o_orderdate
FROM	prioritylist AS pl
		CROSS APPLY	/* INNER JOIN */
		OUTER APPLY /* LEFT JOIN */
		(
			SELECT	MAX(o_orderdate) AS o_orderdate
			FROM	dbo.orders
			WHERE	o_orderpriority = pl.[type]
		) AS lod

GO

SET STATISTICS TIME, IO OFF;
GO
