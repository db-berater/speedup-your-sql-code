select @Anzahl = 1
    while @Anzahl > 0
    begin
        insert into @work
        (
            UID_SingleGuid
        )
        select distinct
            acc.UID_DPRSchemaPropertyTrg
        from dbo.DPRSchemaAccess acc
            join @work ph
                on ph.UID_SingleGuid = acc.UID_DPRSchemaPropertySrc
        where acc.AccessType = 'Direct'
              and not exists
        (
            select top 1
                1
            from @work e
            where e.UID_SingleGuid = acc.UID_DPRSchemaPropertyTrg
        )
        select @Anzahl = @@ROWCOUNT
    end
