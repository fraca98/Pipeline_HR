# Pipeline_HR

## What is it?
Pipeline_HR is a repository containing a series of MATLAB scripts used to process data from the [TimeRun app project](https://github.com/fraca98/TimeRun).

## Organization
The repository includes the following files and folders:
```
pipeline_hr
│   boxplotGroup.m
│   pipeline_hr.m
│   timestep.m
|
├───data
│
├───pop_study
│
└───src
```

### boxplotGroup.m
A [MATLAB function](https://www.mathworks.com/matlabcentral/fileexchange/74437-boxplotgroup) used to display groups of boxplots.

### pipeline_hr.m
The main script used to preprocess data series, compute error and statistical metrics, and generate boxplots based on the obtained data series.

### timestep.m
A MATLAB function used to determine the most common timestep across all data series, in order to understand the best timestep to retime the data series for computing metrics and making comparisons.

### data
It's a folder where you should copy all the folders and files structures contained in the `TimeRun` folder that the application `TimeRun` exports in the memory of the smarthphone when the user submits it in the application
For example (considering only user 1 with 2 sessions):
```
data
└───1
    │   user_1.csv
    │
    ├───session1
    │       fitbit_1_1.csv
    │       garmin_1_1.csv
    │       intervals_1_1.csv
    │       polar_1_1.csv
    │       session_1_1.csv
    │
    └───session4
            applewatch_1_4.csv
            intervals_1_4.csv
            polar_1_4.csv
            session_1_4.csv
            withings_1_4.csv
```

> **Warning**
> Files related to Apple Watch and Garmin data will not be contained in these folders. To add them, you should follow the procedure reported below in this [section](#2-create-the-files-for-apple-watch-and-garmin-and-eventually-atmotube).

### pop_study
In the `pop_study` folder, you will find a MATLAB script `pop_study.m` which calculates characteristics of the study population.

### src
In the `src` folder, you will find a series of subfolders containing scripts useful for preprocessing data.
```
src
├───dataCutter
│       appleSessionCutter.m
│       atmotubeSessionCutter.m
│       garminSessionCutter.m
│
├───errorMetrics
│       cod.m
│       mae.m
│       mard.m
│       rmse.m
│       timeDelay.m
│       xcorrN.m
│
└───retime
        retimeHR.m
        retimeINT.m
```

#### dataCutter
The `dataCutter` folder contains a series of MATLAB files used to create individual files for each user and their specific `Apple Watch` and `Garmin` sessions. This is necessary because these sessions are extracted into files that contain much more data than just the session data itself. The `atmotubeSessionCutter.m` file allows for the creation of a file containing the `Atmotube` data for a specific session for each user.

#### errorMetrics
The `errorMetrics` folder contains a series of MATLAB files used to calculate error metrics between the analyzed device series and the reference `Polar` track for each session.

#### retime
The `retime` folder contains a series of MATLAB files used to retime the data series.

Here's the text you requested:

## How to use it?
### 1. Populate the `data` folder
Copy in the folder `data` all the folders and files structures contained in the `TimeRun` folder that the application `TimeRun` exports in the memory of the smarthphone when the user submits it in the application
### 2. Create the files for `Apple Watch` and `Garmin` (and eventually `Atmotube`)
For each user, for each session including an `Apple Watch` or `Garmin` device, create the respective file using the MATLAB functions `appleSessionCutter.m` and `garminSessionCutter.m` contained in the `src/dataCutter` folder.

> **Note**
> If you want, for each session, for each user, you can create a file containing the data of `Atmotube` for that specific session, using `atmotubeSessionCutter.m`.

### 3. (Optional) Study of population
If you want to perform a study of the population, create a file ```.csv``` containing data of the population with the following columns in order:
* id
* sex
* birth_year
* completed (indicating the number of sessions completed by the participant)
and put it in the folder `pop_study` and then use the script `pop_study.m` to get the results.

### 4. Get the perfect timestep
Since the data series do not always have the same timestep even within the same series, use the script `timestep.m` to calculate the most common timestep among all the series for each device. At this point, select the largest timestep and assign it to the variable `timestep` at line 15 of the file `pipeline_hr.m`.

### 5. Execute `pipeline_hr.m`
Open the script `pipeline_hr.m` and join the results.

# Acknowledgements
Thank you [@gcappon](https://github.com/gcappon) and [@KingLudwig94](https://github.com/KingLudwig94) for the help :smile:
