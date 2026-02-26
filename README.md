# IS-309 Assignment 1 - Bike Sharing DB

##  Group 1

| Candidate | E-mail | GitHub Username |
|--|------------|----------|
| Iver Kroken | iverk@uia.no | iverkroken |
| Tobias Olsen Nodland | tobiason@uia.no | Gorilla-Mode |
| Sivert Svanes Sæstad | sivertss@uia.no | sivert-svanes |
| Marie Hesseberg | marielh@uia.no | MarieHesseberg |


##  Installation / Setup

> [!CAUTION]
> ### 0. Prerequisites
> - Port `5432` is open



> [!CAUTION]
> ### 1. Dependencies
> - Docker
### 2. Setup

#### 1: Clone the repository

```bash
git clone https://github.com/Gorilla-Mode/IS-309Assignment.git
```

#### 2: Start the database

In root dir run: 

```powershell
.\setup.ps1 -d
```
*Use flag -h, for options*



```powershell
.\initdb.ps1 -rc -l
```
*Use flag -h, for options*

## 3. Project Overview

This project implements a relational database schema in PostgreSQL for a bicycle sharing system inspired by Bcycle.

The system supports programs operating in different cities, stations with docking points, bicycles, riders, memberships, trips, and historical status tracking.

The database is designed according to the assignment requirements and enforces business rules using primary keys, foreign keys, unique constraints, and check constraints.



## 4. Database Structure

The schema consists of the following main entities:

- Program
- Station
- Dock
- Rider
- Membership
- Bicycle
- Trip
- StationStatus
- BicycleStatus

Status data is stored separately from core entities to preserve historical snapshots rather than overwriting live data.




