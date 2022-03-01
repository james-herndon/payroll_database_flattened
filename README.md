# payroll_database_flattened

This R code was used to consolidate and flatten a large number of spreadsheets containing payroll data.

First, all documents in a folder are combined by row.
Second, where any cell contains more than one piece of information, these are broken out. For example, if we see a "\n" indicating a new line, that new line gets its own cell.
Third, in a given category, we find all unique "types" and place them in their own column (for example, all possible deductions get their own column, all possible types of hours worked get their own columns, etc.)
There are some lines unique to this data set, used to convert the data. For example, data in parentheses is converted to a negative number. 
