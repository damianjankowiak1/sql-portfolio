### Exercise 1: Count total customers

**Business Context:**  
The manager wants to know the total number of users of our service.

**Technical Details:**  
- Table: `customer`  
- Column: `customer_id`  
- Task: Count the number of rows in the `customer` table.

**SQL Query**
```sql
-- Count total customers
SELECT COUNT(customer_id) FROM customer;
```

**Note:**
`COUNT` can be used with or without a column; for readability we use customer_id.

### Exercise 2: Count unique rental rates

**Business Context:**  
The manager wants to know how many unique rental rates exist in the film table.

**Technical Details:**  
- Table: `film`
- Columns: `rental_rate`
- Task: Count the number of unique values in the `rental_rate` column.

**SQL Query**
```sql
-- Count distinct rental rates
SELECT COUNT(DISTINCT rental_rate) FROM film;
```
