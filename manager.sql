----9. User Management and Privileges 
alter session set  "_oracle_script"=true;
CREATE USER user1 IDENTIFIED BY 0000;
CREATE USER user2 IDENTIFIED BY 0000;
GRANT CREATE session TO USER1;
grant create table to user1;
ALTER USER USER1 QUOTA 100M ON USERS;
grant insert any table to user2;
GRANT SELECT ON MAIN_MANAGER.Professor TO user1;
GRANT REFERENCES ON MAIN_MANAGER.Professor TO user1;
grant insert any table ,create session to user2;
grant update any table to user1,user2;


