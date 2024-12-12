--https://www.freeformatter.com/xpath-tester.html

	DECLARE @xmlData XML = '
<Employees>
    <Employee>
        <EmployeeID attrib1="4" color="yellow">1</EmployeeID>
        <FirstName>John</FirstName>
        <LastName>Doe</LastName>
	   <address>
		  <street>18620 Agua Dr </street>
		  <city>Edmond</city>
	   </address>
	   <phone type="home">405 3326712</phone>
	   <phone type="mobile">405 330337</phone>
    </Employee>
    <Employee>
        <EmployeeID attrib1="5" color="white">2</EmployeeID>
        <FirstName>Jane</FirstName>
        <LastName>Smith</LastName>
	   <address>
		  <street>2585 Penn Tr </street>
		  <city>OKC</city>
	   </address>

    </Employee>
</Employees>';

------ Extract the FirstName of the first Employee
------ Extract all Employee details
--SELECT 
--    employee.value('(EmployeeID)[1]', 'INT') AS EmployeeID, 
--    employee.value('(FirstName)[1]', 'NVARCHAR(50)') AS FirstName,
--    employee.value('(LastName)[1]', 'NVARCHAR(50)') AS LastName
--FROM @xmlData.nodes('/Employees/Employee') AS T(employee);

----return every object
--SELECT 
--    x.query('.') AS Employee
--FROM @xmlData.nodes('/Employees/Employee') AS T(x);

----return child node in the select & attrib of node
--SELECT 
--    x.query('address/city').value('.', 'varchar(70)') AS city, --node child
--    x.query('(phone)[1]').value('.', 'varchar(70)') AS HomePhone,-- node with many instances ie []
--    x.query('(phone)[2]').value('.', 'varchar(70)') AS MobilePhone,
--    x.value('(EmployeeID/@attrib1)[1]', 'INT') as attrib1,
--    x.value('(EmployeeID/@color)[1]', 'varchar(70)') as Color -- node's attribute
--FROM @xmlData.nodes('/Employees/Employee') AS T(x);


----return attribut id where ever is found beneath EmployeeID element
--SELECT 
--    employee.value('(@attrib1)[1]','NVARCHAR(500)') AS Employee
--FROM @xmlData.nodes('//Employee/EmployeeID') AS T(employee);

--retrieve all/node values
SELECT 
 @xmlData.query('*') AS Complete_Sequence,
 @xmlData.query('data(*)') AS Complete_Data,
 @xmlData.query('data(Employees/Employee/EmployeeID)') AS Element_c_Data;