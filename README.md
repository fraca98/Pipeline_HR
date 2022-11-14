# How to use?
Create the folder data in the same folder where you have the script. Be sure that the structure of the folder will be the following one:
```
pipeline_hr
│
│─── pipeline_hr.m 
│
|─── retimeHR.m
|
└─── data
     │─── 1 
     |    |─── session1
     |    |           |─── session_1_1.csv
     |    |           |─── intervals_1_1.csv
     |    |           |─── fitbit_1_1.csv *
     |    |           |─── polar_1_1.csv *
     |    |           |─── AppleWatch_date.csv *
     |    |           └─── Garmin_date.csv *
     |    |
     |    |
     |    |
     |    |─── sessionX
     |    |
     |    └─── user_1.csv
     |
     |─── 2
     |
     └─── UserX
```
* The folder `UserX` identifies the folder named with the id of the user, containing the sessions and the files related to each session of the user.
* The folder `sessionX` identifies the specific session for the user, replacing with the actual id of the session the `X`.
* In the file `user_X.csv`, `X` represents the user id.
* In the .csv files with the structure `_X_X` the first number identifies the user and the second the number of session.
* `AppleWatch`, `Garmin` .csv file contains in the field `date` the date when the data were collected.
* In the [TimeRun](https://github.com/fraca98/TimeRun) study only 2 files with `*` for session are generated.