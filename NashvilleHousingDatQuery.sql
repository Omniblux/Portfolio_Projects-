/*
This project involves cleaning and preparing Nashville housing data in a database 
on an offline server using SQL Server Management Studio. The goal is to ensure
the data is accurate, consistent, and ready for analysis without exporting it 
from the secure server.

It involves handling missing values, standardizing formats, removing duplicates, 
correcting errors, and normalizing data.
*/
---Clearing data for SQL querries

select *
from Portfolio_project_1..NashvilleHousing


---Standardizing date formate
select SaleDate, CONVERT(Date, SaleDate)
from Portfolio_project_1..NashvilleHousing

Alter table NashvilleHousing
add SaleDateConverted Date;

Update NashvilleHousing
Set SaleDateConverted = CONVERT(Date, SaleDate)

select Saledate, SaledateConverted
from Portfolio_project_1..NashvilleHousing
---I could remove SaleDate now but I won't


---Populating Property address data
select *
from Portfolio_project_1..NashvilleHousing
---where PropertyAddress is null
order by ParcelID, PropertyAddress

select *
from Portfolio_project_1..NashvilleHousing as a
join Portfolio_project_1..NashvilleHousing as b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ]!= b.[UniqueID ]

select a.ParcelID,b.[UniqueID ], b.ParcelID, b.PropertyAddress, 
	ISNULL(a.propertyAddress, b.PropertyAddress)
from Portfolio_project_1..NashvilleHousing as a
join Portfolio_project_1..NashvilleHousing as b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ]!= b.[UniqueID ]
where a.PropertyAddress is null

Update a
Set PropertyAddress = ISNULL(a.propertyAddress, b.PropertyAddress)
from Portfolio_project_1..NashvilleHousing as a
join Portfolio_project_1..NashvilleHousing as b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ]!= b.[UniqueID ]
where a.PropertyAddress is null


---Breaking address into individual columns (Address, city, state)
select PropertyAddress
from Portfolio_project_1..NashvilleHousing
---where PropertyAddress is null
--- by ParcelID, PropertyAddress


select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS StreetAddress,
    LTRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))) AS City
FROM Portfolio_project_1..NashvilleHousing;

---
Alter table NashvilleHousing
add SplitStreetAdress varchar(255), SplitCity varchar(255)

Update NashvilleHousing
Set SplitStreetAdress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
	SplitCity = LTRIM(SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)))

---Using parsename function to do same on OwnerAddress
Alter table NashvilleHousing
add OwnerStreet varchar(255),
    OwnerCity varchar(255),
	OwnerState varchar(255) 

update NashvilleHousing
set OwnerStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
---
select OwnerAddress, OwnerStreet, OwnerCity, OwnerState
from NashvilleHousing


---
select distinct(SoldAsVacant), COUNT(SoldAsVacant)
from NashvilleHousing
Group by SoldAsVacant
order by 2

select SoldAsVacant,
case when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end
from NashvilleHousing

update NashvilleHousing
Set SoldAsVacant = 
case when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
	end


---Removing Duplicates
---check for duplicates---
select *,
	ROW_NUMBER() OVER (
	partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 order by 
					UniqueID) Row_num
	
from NashvilleHousing
order by Row_num desc

---create CTE  to delete (caution!)
with Row_NumCTE as( 
select *,
	ROW_NUMBER() OVER (
	partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 order by 
					UniqueID) Row_num
	
from NashvilleHousing
---order by Row_num desc
)
DELETE
FROM Row_NumCTE
where Row_num > 1
---order by PropertyAddress



---Deleting Unusable columns
select *
from NashvilleHousing

alter table NashvilleHousing
drop column OwnerAddress, PropertyAddress, TaxDistrict