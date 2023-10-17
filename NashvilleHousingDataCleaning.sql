/*
Nashville Housing Data
Cleaning Data in SQL
*/

SELECT * FROM PortfolioProject.dbo.NashvilleHousing$

/*STANDARDIZE DATE FORMAT - CONVERT TO DATE INSTEAD OF DATETIME*/
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing$

	ALTER TABLE NashvilleHousing$
	ADD SaleDateConverted Date;

	UPDATE NashvilleHousing$
	SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted FROM PortfolioProject.dbo.NashvilleHousing$


/*POPULATE PROPERTY ADDRESS DATA*/
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing$
WHERE PropertyAddress IS NULL

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing$
ORDER BY ParcelID
--Parcel IDs have the same Property Address - update address for Parcel IDs where addresses is null

--Self-join to join the table to itself - confirm that the parcelIDs addresses match - if null then replace the value
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) --updates null values with property addresses
FROM PortfolioProject.dbo.NashvilleHousing$ a
JOIN PortfolioProject.dbo.NashvilleHousing$ b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL
ORDER BY a.ParcelID
--Run this again after running below UPDATE statement to confirm there are no null values


UPDATE a --use an alias for joins in an UPDATE statement
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing$ a
JOIN PortfolioProject.dbo.NashvilleHousing$ b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL



/*BREAKING OUT PROPERTY ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY)*/
SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing$
--delimiter is a comma


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address, --Using substrings and CHARINDEX to store everything before comma & get rid of comma with -1
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address --Using substrings and CHARINDEX to store everything after comma - +1 to remove comma
FROM PortfolioProject.dbo.NashvilleHousing$


ALTER TABLE NashvilleHousing$
ADD PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing$
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing$
ADD PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing$
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT * FROM PortfolioProject.dbo.NashvilleHousing$



/*BREAKING OUT OWNER ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)*/
SELECT OwnerAddress FROM PortfolioProject.dbo.NashvilleHousing$

--PARSENAME works with periods instead of commas - need to REPLACE with periods - PARSENAME works backwards so start with 3 isntead of 1
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM PortfolioProject.dbo.NashvilleHousing$

ALTER TABLE NashvilleHousing$
ADD OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing$
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing$
ADD OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing$
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing$
ADD OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing$
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT * FROM PortfolioProject.dbo.NashvilleHousing$







/*CHANGE Y AND N INTO YES AND NO IN "SOLD AS VACANT" FIELD*/
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS ResponseCount
FROM PortfolioProject.dbo.NashvilleHousing$ 
GROUP BY SoldAsVacant
ORDER BY 2
--returns answer values and count of eah answer

SELECT SoldAsVacant,
CASE	WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM PortfolioProject.dbo.NashvilleHousing$ 

UPDATE NashvilleHousing$ 
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS ResponseCount
FROM PortfolioProject.dbo.NashvilleHousing$ 
GROUP BY SoldAsVacant
ORDER BY 2
--returns answer values and count of each answer



/*REMOVE DUPLICATES*/ --note: not as common as it is not standard practice to delete data from database

--CTE to locate duplicate values - Partition on things that are unique to each row
WITH RowNumCTE AS
(
	SELECT *, 
	ROW_NUMBER() OVER 
	(
		PARTITION BY	ParcelID, 
						PropertyAddress,
						SalePrice,
						SaleDate,
						LegalReference
		ORDER BY UniqueID
	) 
	row_num
FROM PortfolioProject.dbo.NashvilleHousing$
)
SELECT * FROM RowNumCTE WHERE row_num > 1 ORDER BY PropertyAddress


DELETE FROM RowNumCTE WHERE row_num > 1 --run this with CTE above to remove duplicates, then run the above CTE again wtih the select statement - nothing should be returned













/*DELETE UNUSED COLUMNS*/

SELECT * FROM PortfolioProject.dbo.NashvilleHousing$

--Can remove PropertyAddress and OwnerAddress because they are not useful after splitting the addresses
--Can remove TaxDistrict and SaleDate because this is not needed
ALTER TABLE PortfolioProject.dbo.NashvilleHousing$
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict, SaleDate