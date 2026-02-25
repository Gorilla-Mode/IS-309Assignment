# IS-309 Assignment 1 - Bike Sharing Database

## 1️. Project Overview

This project implements a relational database schema in PostgreSQL for a bicycle sharing system inspired by Bcycle.

The system supports programs operating in different cities, stations with docking points, bicycles, riders, memberships, trips, and historical status tracking.

The database is designed according to the assignment requirements and enforces business rules using primary keys, foreign keys, unique constraints, and check constraints.

---

## 2️. Database Structure

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

---

## 3️. Setup
### 1. Clone repository

```bash
git clone https://github.com/Gorilla-Mode/IS-309Assignment.git

