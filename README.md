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
     |    |           |─── applewatch_1_1.csv *
     |    |           └─── garmin_1_1.csv *
     |    |
     |    |─── sessionX
     |    |
     |    |─── user_1.csv
     |    |
     |    └─── Questionnaires 1 
     |
     └─── UserX
```
* The folder `UserX` identifies the folder named with the id of the user, containing the sessions and the files related to each session of the user.
* The folder `sessionX` identifies the specific session for the user, replacing with the actual id of the session the `X`.
* In the file `user_X.csv`, `X` represents the user id.
* In the .csv files with the structure `_X_X` the first number identifies the user and the second the number of session.
* `applewatch_X_X`, `garmin_X_X` .csv file have to be generated using the functions in the folder from a .csv file containing also data out of the specific session for the user.
* In the [TimeRun](https://github.com/fraca98/TimeRun) study only 2 files with `*` for session are generated.