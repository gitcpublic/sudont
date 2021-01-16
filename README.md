# sudont
A small bash script &amp; MySQL db to define who is &amp; isn't allowed to use sudo.

### Prerequisites;  
- Installed & configured MySQL/MariaDB
- Your users must have 24h clock enabled: ```LANG='en_GB.UTF-8'```

### Configuration;  
Create the directory ```/etc/sudont/``` and place the sudont.sh script in there.  
Create the directory ```/etc/sudont/temp/``` (leave it blank, it'll be used temporarily during the checking process).  
Apply 777 permissions to the temp folder: ```chmod 777 /etc/sudont/temp```  
In the user's .bashrc file, add: ```alias sudo="bash /etc/sudont/sudont.sh && sudo"```  

### Times permitted for sudo;  
In the table ```access_control```, insert your data in the following structure:  

```
mysql> select * from access_control;
+----+-----------------+-----------------------------+-----------------+
| id | localuser       | dayscanaccess               | accesstimeframe |
+----+-----------------+-----------------------------+-----------------+
|  1 | gitcpublic      | mon,tue,wed,thu,fri,sat,sun | 0001-1620       |
+----+-----------------+-----------------------------+-----------------+
1 row in set (0.00 sec)
```

The above record will allow the user ```gitcpublic``` to use sudo on all days of the week, from ```00:01``` until ```16:20```.  
You may add multiple records for different days of the week, like so:  

```
mysql> select * from access_control;
+----+-----------------+---------------+-----------------+
| id | localuser       | dayscanaccess | accesstimeframe |
+----+-----------------+---------------+-----------------+
|  1 | gitcpublic      | mon           | 0001-1620       |
|  1 | gitcpublic      | thu           | 0001-1920       |
+----+-----------------+---------------+-----------------+
1 row in set (0.00 sec)
```

The above records will allow the user ```gitcpublic``` to use sudo on Monday from ```00:01``` until ```16:20```, and Thursday from ```00:01``` until ```19:20```. 
