-- ETL in Power Query
-- data cleansing and transformation techniques to start shaping data model in Power BI.


-- Configure the Salesperson query- SalesPerson
let
    Source = Sql.Databases("localhost"),
    AdventureWorksDW2020 = Source{[Name="AdventureWorksDW2020"]}[Data],
    dbo_DimEmployee = AdventureWorksDW2020{[Schema="dbo",Item="DimEmployee"]}[Data],
    #"Filtered Rows" = Table.SelectRows(dbo_DimEmployee, each ([SalesPersonFlag] = true)),
    #"Removed Other Columns" = Table.SelectColumns(#"Filtered Rows",{"EmployeeKey", "EmployeeNationalIDAlternateKey", "FirstName", "LastName", "Title", "EmailAddress"}),
    #"Merged Columns" = Table.CombineColumns(#"Removed Other Columns",{"FirstName", "LastName"},Combiner.CombineTextByDelimiter(" ", QuoteStyle.None),"Merged"),
    #"Renamed Columns" = Table.RenameColumns(#"Merged Columns",{{"Merged", "Salesperson"}, {"EmployeeNationalIDAlternateKey", "EmployeeID"}, {"EmailAddress", "UPN"}})
in
    #"Renamed Columns"

-- Configure the Salesperson query- SalespersonRegion
let
    Source = Sql.Databases("localhost"),
    AdventureWorksDW2020 = Source{[Name="AdventureWorksDW2020"]}[Data],
    dbo_DimEmployeeSalesTerritory = AdventureWorksDW2020{[Schema="dbo",Item="DimEmployeeSalesTerritory"]}[Data],
    #"Removed Columns" = Table.RemoveColumns(dbo_DimEmployeeSalesTerritory,{"DimEmployee", "DimSalesTerritory"})
in
    #"Removed Columns"

-- Configure the Product query- Product
let
    Source = Sql.Databases("localhost"),
    AdventureWorksDW2020 = Source{[Name="AdventureWorksDW2020"]}[Data],
    dbo_DimProduct = AdventureWorksDW2020{[Schema="dbo",Item="DimProduct"]}[Data],
    #"Filtered Rows" = Table.SelectRows(dbo_DimProduct, each ([FinishedGoodsFlag] = true)),
    #"Removed Other Columns" = Table.SelectColumns(#"Filtered Rows",{"ProductKey", "EnglishProductName", "StandardCost", "Color", "DimProductSubcategory"}),
    #"Expanded DimProductSubcategory" = Table.ExpandRecordColumn(#"Removed Other Columns", "DimProductSubcategory", {"EnglishProductSubcategoryName", "DimProductCategory"}, {"DimProductSubcategory.EnglishProductSubcategoryName", "DimProductSubcategory.DimProductCategory"}),
    #"Expanded DimProductSubcategory.DimProductCategory" = Table.ExpandRecordColumn(#"Expanded DimProductSubcategory", "DimProductSubcategory.DimProductCategory", {"EnglishProductCategoryName"}, {"DimProductSubcategory.DimProductCategory.EnglishProductCategoryName"}),
    #"Filtered Rows1" = Table.SelectRows(#"Expanded DimProductSubcategory.DimProductCategory", each true),
    #"Renamed Columns" = Table.RenameColumns(#"Filtered Rows1",{{"DimProductSubcategory.DimProductCategory.EnglishProductCategoryName", "Subcategory"}, {"StandardCost", "Standard Cost"}, {"DimProductSubcategory.EnglishProductSubcategoryName", "Category"}, {"EnglishProductName", "Product"}}),
    #"Merged Queries" = Table.NestedJoin(#"Renamed Columns", {"Color"}, ColorFormats, {"Color"}, "ColorFormats", JoinKind.LeftOuter),
    #"Expanded ColorFormats" = Table.ExpandTableColumn(#"Merged Queries", "ColorFormats", {"Background Color Format", "Font Color Format"}, {"ColorFormats.Background Color Format", "ColorFormats.Font Color Format"})
in
    #"Expanded ColorFormats"

-- Configure the Reseller query- Reseller
let
    Source = Sql.Databases("localhost"),
    AdventureWorksDW2020 = Source{[Name="AdventureWorksDW2020"]}[Data],
    dbo_DimReseller = AdventureWorksDW2020{[Schema="dbo",Item="DimReseller"]}[Data],
    #"Removed Other Columns" = Table.SelectColumns(dbo_DimReseller,{"ResellerKey", "BusinessType", "ResellerName", "DimGeography"}),
    #"Expanded DimGeography" = Table.ExpandRecordColumn(#"Removed Other Columns", "DimGeography", {"City", "StateProvinceName", "EnglishCountryRegionName"}, {"DimGeography.City", "DimGeography.StateProvinceName", "DimGeography.EnglishCountryRegionName"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded DimGeography", each true),
    #"Replaced Value" = Table.ReplaceValue(#"Filtered Rows","Ware House","Warehouse",Replacer.ReplaceText,{"BusinessType"}),
    #"Renamed Columns" = Table.RenameColumns(#"Replaced Value",{{"BusinessType", "Business Type"}, {"ResellerName", "Reseller"}, {"DimGeography.StateProvinceName", "State Province"}, {"DimGeography.EnglishCountryRegionName", "Country Region"}})
in
    #"Renamed Columns"

--Configure the Region query- Region
let
    Source = Sql.Databases("localhost"),
    AdventureWorksDW2020 = Source{[Name="AdventureWorksDW2020"]}[Data],
    dbo_DimSalesTerritory = AdventureWorksDW2020{[Schema="dbo",Item="DimSalesTerritory"]}[Data],
    #"Filtered Rows" = Table.SelectRows(dbo_DimSalesTerritory, each ([SalesTerritoryAlternateKey] <> 0)),
    #"Removed Other Columns" = Table.SelectColumns(#"Filtered Rows",{"SalesTerritoryKey", "SalesTerritoryRegion", "SalesTerritoryCountry", "SalesTerritoryGroup"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Other Columns",{{"SalesTerritoryRegion", "Region"}, {"SalesTerritoryCountry", "Country"}, {"SalesTerritoryGroup", "Group"}})
in
    #"Renamed Columns"

--Configure the Sales query- Sales
let
    Source = Sql.Databases("localhost"),
    AdventureWorksDW2020 = Source{[Name="AdventureWorksDW2020"]}[Data],
    dbo_FactResellerSales = AdventureWorksDW2020{[Schema="dbo",Item="FactResellerSales"]}[Data],
    #"Removed Other Columns" = Table.SelectColumns(dbo_FactResellerSales,{"SalesOrderNumber", "OrderDate", "ProductKey", "ResellerKey", "EmployeeKey", "SalesTerritoryKey", "OrderQuantity", "UnitPrice", "TotalProductCost", "SalesAmount", "DimProduct"}),
    #"Expanded DimProduct" = Table.ExpandRecordColumn(#"Removed Other Columns", "DimProduct", {"StandardCost"}, {"DimProduct.StandardCost"}),
    #"Added Custom" = Table.AddColumn(#"Expanded DimProduct", "Cost", each if [TotalProductCost] = null then [OrderQuantity] * [DimProduct.StandardCost] else [TotalProductCost]),
    #"Removed Columns" = Table.RemoveColumns(#"Added Custom",{"DimProduct.StandardCost", "TotalProductCost"}),
    #"Renamed Columns" = Table.RenameColumns(#"Removed Columns",{{"OrderQuantity", "Quantity"}, {"UnitPrice", "Unit Price"}, {"SalesAmount", "Sales"}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Renamed Columns",{{"Unit Price", Currency.Type}, {"Sales", Currency.Type}, {"Cost", Currency.Type}})
in
    #"Changed Type"

--Configure the Targets query- Targets
let
    Source = Csv.Document(File.Contents("D:\PL300\Resources\ResellerSalesTargets.csv"),[Delimiter=",", Columns=14, Encoding=1200, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"Year", Int64.Type}, {"EmployeeID", Int64.Type}, {"M01", type text}, {"M02", type text}, {"M03", type text}, {"M04", type text}, {"M05", type text}, {"M06", type text}, {"M07", type text}, {"M08", type text}, {"M09", type text}, {"M10", type text}, {"M11", type text}, {"M12", type text}}),
    #"Unpivoted Other Columns" = Table.UnpivotOtherColumns(#"Changed Type", {"Year", "EmployeeID"}, "Attribute", "Value"),
    #"Filtered Rows" = Table.SelectRows(#"Unpivoted Other Columns", each ([Value] <> "-")),
    #"Renamed Columns" = Table.RenameColumns(#"Filtered Rows",{{"Value", "Target"}, {"Attribute", "MonthNumber"}}),
    #"Replaced Value" = Table.ReplaceValue(#"Renamed Columns","M","",Replacer.ReplaceText,{"MonthNumber"}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Replaced Value",{{"MonthNumber", Int64.Type}}),
    #"Inserted Merged Column" = Table.AddColumn(#"Changed Type1", "TargetMonth", each Text.Combine({Text.From([MonthNumber], "en-US"), "/1/", Text.From([Year], "en-US")}), type text),
    #"Removed Columns" = Table.RemoveColumns(#"Inserted Merged Column",{"Year", "MonthNumber"}),
    #"Changed Type2" = Table.TransformColumnTypes(#"Removed Columns",{{"Target", Currency.Type}, {"TargetMonth", type date}}),
    #"Multiplied Column" = Table.TransformColumns(#"Changed Type2", {{"Target", each _ * 1000, Currency.Type}})
in
    #"Multiplied Column"

--Configure the ColorFormats query- ColorFormats
let
    Source = Csv.Document(File.Contents("D:\PL300\Resources\ColorFormats.csv"),[Delimiter=",", Columns=3, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    #"Changed Type" = Table.TransformColumnTypes(Source,{{"Column1", type text}, {"Column2", type text}, {"Column3", type text}}),
    #"Promoted Headers" = Table.PromoteHeaders(#"Changed Type", [PromoteAllScalars=true]),
    #"Changed Type1" = Table.TransformColumnTypes(#"Promoted Headers",{{"Color", type text}, {"Background Color Format", type text}, {"Font Color Format", type text}})
in
    #"Changed Type1"


