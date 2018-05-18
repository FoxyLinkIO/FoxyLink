BeginRequest: 18.05.2018 08:11:49

REQUEST URL
External data source: DataBank
Table name: dbo_FactCustomerSalesGoods

REQUEST BODY

```sql
CREATE TABLE #346179253c214a34993b4289d6ba0822
    ([CustomerSalesRef] UNIQUEIDENTIFIER NOT NULL
    ,[LineNum] Numeric(15) NOT NULL
    ,[NomenclatureRef] UNIQUEIDENTIFIER
    ,[Quantity] Decimal(15,3) NOT NULL
    ,[Price] Decimal(15,2) NOT NULL
    ,[PriceTypeRef] UNIQUEIDENTIFIER
    ,[Amount] Decimal(15,2) NOT NULL
    ,[VatAmount] Decimal(15,2) NOT NULL
    ,[AmountIncludeVat] Decimal(15,2) NOT NULL
    ,[AmountManualDiscount] Decimal(15,2) NOT NULL
    ,[AmountAutomaticDiscount] Decimal(15,2) NOT NULL
    ,[RowCode] Numeric(10)
    ,[KeySerialNumber] Numeric(15)
    ,[BalanceAmount] Decimal(15,2) NOT NULL
    ,[RowID] UNIQUEIDENTIFIER
    ,[CustomerOrderRef] UNIQUEIDENTIFIER
    ,[NotAccrueBonus] BIT NOT NULL
    ,[UpdateDate] DATETIME NOT NULL
    ,[SubTotalAccounting] Decimal(15,3) NOT NULL);

INSERT INTO #346179253c214a34993b4289d6ba0822
    ([CustomerSalesRef], [LineNum], [NomenclatureRef], [Quantity], [Price], [PriceTypeRef], [Amount], [VatAmount], [AmountIncludeVat], [AmountManualDiscount], [AmountAutomaticDiscount], [RowCode], [KeySerialNumber], [BalanceAmount], [RowID], [CustomerOrderRef], [NotAccrueBonus], [UpdateDate], [SubTotalAccounting])
VALUES
    ('16603ed2-b4ff-4d00-9129-06a269196574', 1, '31aa4f0b-e897-482c-80c1-8925ab138ae9', 1, 70, '8bdf84ff-404c-11e0-9f98-001517115d85', 70, 0, 70, 0, 0, 0, 1, 70, 'c7d73698-e32f-4df7-8e17-99d5e20f02aa', NULL, 0, '2018-05-18T11:11:46', 2.66);

GO;

CREATE TABLE #5521ff3cb9614946a50b04af870debdd
    ([CustomerSalesRef] UNIQUEIDENTIFIER NOT NULL);

INSERT INTO #5521ff3cb9614946a50b04af870debdd
    ([CustomerSalesRef])
VALUES
    ('16603ed2-b4ff-4d00-9129-06a269196574');

GO;


WITH AffectedLines AS (
    SELECT T1.*
    FROM dbo.FactCustomerSalesGoods AS T1 
    WHERE EXISTS (
        SELECT T2.*
        FROM #5521ff3cb9614946a50b04af870debdd AS T2 
        WHERE T1.CustomerSalesRef = T2.CustomerSalesRef
    )
)
MERGE AffectedLines AS [Target]
USING #346179253c214a34993b4289d6ba0822 AS [Source]
ON ([Target].[CustomerSalesRef] = [Source].[CustomerSalesRef]
AND [Target].[LineNum] = [Source].[LineNum])
WHEN MATCHED THEN
    UPDATE
    SET
        [Target].[CustomerSalesRef] = [Source].[CustomerSalesRef]
        ,[Target].[LineNum] = [Source].[LineNum]
        ,[Target].[NomenclatureRef] = [Source].[NomenclatureRef]
        ,[Target].[Quantity] = [Source].[Quantity]
        ,[Target].[Price] = [Source].[Price]
        ,[Target].[PriceTypeRef] = [Source].[PriceTypeRef]
        ,[Target].[Amount] = [Source].[Amount]
        ,[Target].[VatAmount] = [Source].[VatAmount]
        ,[Target].[AmountIncludeVat] = [Source].[AmountIncludeVat]
        ,[Target].[AmountManualDiscount] = [Source].[AmountManualDiscount]
        ,[Target].[AmountAutomaticDiscount] = [Source].[AmountAutomaticDiscount]
        ,[Target].[RowCode] = [Source].[RowCode]
        ,[Target].[KeySerialNumber] = [Source].[KeySerialNumber]
        ,[Target].[BalanceAmount] = [Source].[BalanceAmount]
        ,[Target].[RowID] = [Source].[RowID]
        ,[Target].[CustomerOrderRef] = [Source].[CustomerOrderRef]
        ,[Target].[NotAccrueBonus] = [Source].[NotAccrueBonus]
        ,[Target].[UpdateDate] = [Source].[UpdateDate]
        ,[Target].[SubTotalAccounting] = [Source].[SubTotalAccounting]
WHEN NOT MATCHED BY TARGET THEN 
    INSERT
        ([CustomerSalesRef], [LineNum], [NomenclatureRef], [Quantity], [Price], [PriceTypeRef], [Amount], [VatAmount], [AmountIncludeVat], [AmountManualDiscount], [AmountAutomaticDiscount], [RowCode], [KeySerialNumber], [BalanceAmount], [RowID], [CustomerOrderRef], [NotAccrueBonus], [UpdateDate], [SubTotalAccounting])
    VALUES
        ([Source].[CustomerSalesRef], [Source].[LineNum], [Source].[NomenclatureRef], [Source].[Quantity], [Source].[Price], [Source].[PriceTypeRef], [Source].[Amount], [Source].[VatAmount], [Source].[AmountIncludeVat], [Source].[AmountManualDiscount], [Source].[AmountAutomaticDiscount], [Source].[RowCode], [Source].[KeySerialNumber], [Source].[BalanceAmount], [Source].[RowID], [Source].[CustomerOrderRef], [Source].[NotAccrueBonus], [Source].[UpdateDate], [Source].[SubTotalAccounting])
WHEN NOT MATCHED BY SOURCE THEN
    DELETE;

DROP TABLE #346179253c214a34993b4289d6ba0822;
DROP TABLE #5521ff3cb9614946a50b04af870debdd;
```

RESPONSE BODY
Result: 202
1

DoneResponse: 18.05.2018 08:11:49
Overall Elapsed: 47 ms
----------------------------------------------------------------------
