### Exercise 1: Show all columns

**Business Context:**  
Quick overview of all columns in the actor table.

**Technical Details:**  
- Table: `actor`
- Task: Select all columns to inspect the table structure.

**SQL Query**
```sql
-- Select all from actor table
SELECT * FROM actor;
```

### Exercise 2: Show table layout

**Business Context:**  
Check the structure of the actor table by viewing a single row.

**Technical Details:**  
- Table: `actor` 
- Task: Return only one row to preview table layout.

**SQL Query**
```sql
-- Select 1 row from actor table
SELECT * FROM actor 
LIMIT 1;
```

### Exercise 3: Show multiple columns

**Business Context:**  
The manager wants to send out a promotional email to existing clients.

**Technical Details:**  
- Table: `customer`
- Columns: `first_name`, `last_name`, `email`
- Task: Select the specified columns from customer table.

**SQL Query**
```sql
-- Select first_name, last_name and email columns from customer table
SELECT 
	first_name, 
	last_name, 
	email
FROM 
	customer;
```

