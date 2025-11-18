### Exercise 1: Show unique values

**Business Context:**  
The manager wants to describe the MPAA movie ratings related to our movie collection to a foreign client.

**Technical Details:**  
- Table: `film`  
- Column: `rating`  
- Task: Select unique values from the rating column.

**SQL Query**
```sql
-- Show unique MPAA movie ratings
SELECT DISTINCT rating FROM film;
```

**Note:**
The parenthesis in DISTINCT is optional

### Exercise 2: Find the email address of a specific user

**Business Context:**  
A client forgot their wallet at our office. The manager wants to send an email to the wallet owner, Nancy Thomas.

**Technical Details:**  
- Table: `customer`
- Columns: `first_name`, `last_name`, `email`
- Conditions: `first_name = 'Nancy'`, `last_name = 'Thomas'`
- Task: Select specified columns with the given conditions.

**SQL Query**
```sql
-- Find email of customer Nancy Thomas
SELECT 
	first_name,
	last_name,
	email
FROM 
	customer
WHERE
	first_name = 'Nancy'
	AND last_name = 'Thomas';
```

### Exercise 3: First 10 paying clients

**Business Context:**  
The manager wants to know the IDs of the first 10 paying clients

**Technical Details:**  
- Table: `payment`
- Columns: `customer_id`, `amount`, `payment_date`
- Conditions: `amount > 0`, `payment_date` in ascending order
- Task: Select specified columns meeting the conditions.

**SQL Query**
```sql
-- Show first 10 paying clients with amount > 0, ordered by payment_date
SELECT 
	customer_id,
	amount,
	payment_date
FROM 
	payment
WHERE
	amount > 0
ORDER BY 
	payment_date ASC
LIMIT 10;
```

### Exercise 4: Filter using the LIKE operator with wildcards

**Business Context:**
The manager wants to identify actors whose first name contains “her” after the first character.

**Technical Details:**  
- Table: `actor`
- Columns: `first_name`
- Conditions: `first_name LIKE '_her%'`
- Task: Select specified columns meeting the conditions.

**SQL Query**
```sql
-- Show actors whose first_name contains 'her' after the first character
SELECT 
	first_name
FROM 
	actor
WHERE
	first_name LIKE '_her%';
```

**Note**
`LIKE` is case-sensitive. `ILIKE` is case-insensitive.

### Exercise 5: Payments within a date range

**Business Context:**
The manager wants to review payments above $100 made between January 10 and January 15, 2025.

**Technical Details:**  
- Table: `payment`
- Columns: `payment_id`, `amount`, `payment_date`
- Conditions: `amount > 100`, `payment_date BETWEEN '2025-01-10' AND  '2025-01-15'`
- Task: Select rows meeting the conditions, sorted by date.

**SQL Query**
```sql
-- Show payments with amount > 100, between 2025-01-10 and 2025-01-15
SELECT 
	payment_id,
	amount,
	payment_date
FROM 
	payment
WHERE
	amount > 100
	AND payment_date BETWEEN '2025-01-10' AND '2025-01-15'
ORDER BY 
    payment_date ASC;
```

**Note:**
If the payment_date column uses a timestamp format, the above query includes results only up to midnight of 2025-01-15.
To include the full day, use:
```sql
[...] AND payment_date >= '2025-01-10' 
AND payment_date < '2025-01-16'[...]
```