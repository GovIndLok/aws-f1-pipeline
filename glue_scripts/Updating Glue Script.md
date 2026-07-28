Currently the bronze tables schemas are looking like this:
1. bronze_circuits
	- circuitid   int
    - circuitref  string
    - name  string
	- location  string
	- country  string
    - lat  double
	- lng  double
	- alt  int
    - url  string
2. bronze_constructors
	- constructorid  int
    - constructorref string
    - name string
    - nationality string
    - url string
3. bronze_driver
	- driverid int
	- driverref  string
	- number  string
	- code  string
	- forename string
	- surname string
	- dob date
	- nationality string
	- url string
4. bronze_lap_times
	- raceid  int
    - driverid int
    - lap int
    - position int
    - time string
    - milliseconds int
5. bronze_pit_stops
	- raceid int
    - driverid int
	- stop int
    - lap int
	- time timestamp
    - duration string
	- milliseconds int
6. bronze_qualifyings
	- qualifyid int
    - raceid int
	- driverid int
    - constructorid int
    - number int
	- position int
    - q1 string
    - q2 string
	- q3 string
7. bronze_races
	- raceid int
    - year int
    - round int
    - circuitid int
    - name string
    - date date
    - time string
    - url string
    - fp1_date string
    - fp1_time string
    - fp2_date string
    - fp2_time string
    - fp3_date string
    - fp3_time string
    - quali_date string
    - quali_time string
    - sprint_date string
    - sprint_time string
8. bronze_results
	- resultid int
    - raceid int
    - driverid int
    - constructorid int
    - number string
    - grid int
    - position string
    - positiontext string
    - positionorder int
    - points double
    - laps int
    - time string
    - milliseconds string
    - fastestlap string
    - rank string
    - fastestlaptime string
    - fastestlapspeed string
    - statusid int
9. bronze_sprint_results
	- resultid int
    - raceid int
    - driverid int
    - constructorid int
    - number string
    - grid int
    - position string
    - positiontext string
    - positionorder int
    - points double
    - laps int
    - time string
    - milliseconds string
    - fastestlap string
    - rank string
    - fastestlaptime string
    - fastestlapspeed string
    - statusid int

This is in  Ergast schema which is now shut down the alternative compatible api we choose is  jolpica api which provide data in Ergast format the only problem is that this dataset is that it a lightly processed to have id columns which depending on the tables are either:
1. Not present in the table so we need to create one from other candidate keys
2. They are present but are actually ref table of our dataset and can be used to create tables
These is the api root view we can use to :
`````
{
    "season": "[https://api.jolpi.ca/ergast/f1/seasons](https://api.jolpi.ca/ergast/f1/seasons)",
    "circuit": "[https://api.jolpi.ca/ergast/f1/circuits](https://api.jolpi.ca/ergast/f1/circuits)",
    "race": "[https://api.jolpi.ca/ergast/f1/2026/races](https://api.jolpi.ca/ergast/f1/2026/races)",
    "constructor": "[https://api.jolpi.ca/ergast/f1/2026/constructors](https://api.jolpi.ca/ergast/f1/2026/constructors)",
    "driver": "[https://api.jolpi.ca/ergast/f1/2026/drivers](https://api.jolpi.ca/ergast/f1/2026/drivers)",
    "result": "[https://api.jolpi.ca/ergast/f1/2026/results](https://api.jolpi.ca/ergast/f1/2026/results)",
    "sprint": "[https://api.jolpi.ca/ergast/f1/2026/sprint](https://api.jolpi.ca/ergast/f1/2026/sprint)",
    "qualifying": "[https://api.jolpi.ca/ergast/f1/2026/qualifying](https://api.jolpi.ca/ergast/f1/2026/qualifying)",
    "pitstop": "[https://api.jolpi.ca/ergast/f1/2026/1/pitstops](https://api.jolpi.ca/ergast/f1/2026/1/pitstops)",
    "lap": "[https://api.jolpi.ca/ergast/f1/2026/1/laps](https://api.jolpi.ca/ergast/f1/2026/1/laps)",
    "driverstanding": "[https://api.jolpi.ca/ergast/f1/2026/driverstandings](https://api.jolpi.ca/ergast/f1/2026/driverstandings)",
    "constructorstanding": "[https://api.jolpi.ca/ergast/f1/2026/constructorstandings](https://api.jolpi.ca/ergast/f1/2026/constructorstandings)",
    "status": "[https://api.jolpi.ca/ergast/f1/status](https://api.jolpi.ca/ergast/f1/status)"
}
`````
