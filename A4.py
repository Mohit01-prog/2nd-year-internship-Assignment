#2)  Practice DATABASE  
# 1) Create Database
# 2) Create 2-3 tables
# 3) Insert some records
# 4) Perform diffrent select operations
# 5) Update some data
# 6) Delete some data

import sqlite3

conn = sqlite3.connect("Student.db")

sql = """
create table student_info(
id integer primary key autoincrement,
name varchar(30),
email varchar(40),
mob integer
)"""

conn.execute(sql)

sql = """
create table Courses(
Course_Id integer primary key,
Course_name varchar(40)
)"""

conn.execute(sql)

sql = """
insert into student_info(name,email,mob) values 
("Priyanjal","123@gmail.com","7897897895"),
("Aman","hello@gmail.com","7895124579"),
("Riya","1@gmail.com","7564924598")
"""

conn.execute(sql)

sql = """
insert into Courses(Course_Id,Course_name) values 
(123,"B-Tech"),
(148,"M-Tech")
"""

conn.execute(sql)

sql = 'select * from student_info'
res = conn.execute(sql)

for i in res:
    print(i)

sql = 'select * from Courses where Course_Id = 148'
res1 = conn.execute(sql)

for i in res1:
    print(i)

sql = "UPDATE student_info SET name = 'Pranjal' WHERE id = 1"
conn.execute(sql)

sql = 'delete from student_info where id = 1'
conn.execute(sql)

conn.commit()
conn.close()