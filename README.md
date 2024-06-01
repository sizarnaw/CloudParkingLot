# Parking Lot Management System

## Overview
This project implements a cloud-based system to manage parking lots. It tracks the entry and exit times of vehicles, their license plates, and the IDs of their respective parking spots. The system calculates the parking fees based on the duration each car remains parked.

## Scenario
A camera at the parking lot entrance captures the license plate of each car and sends this data to the cloud service. The system handles:
- **Entry:** Logs the time of entry, the car's license plate, and the parking lot ID.
- **Exit:** Provides the license plate, total time parked, the parking lot ID, and the total charge, calculated based on the parking duration.

## Pricing
Parking fees are set at $10 per hour. Fees are prorated and charged in 15-minute increments.

## Endpoints
The system offers two primary HTTP endpoints:

### POST /entry
- **Purpose:** Records a car's entry into the parking lot.
- **Parameters:**
  - `plate`: License plate of the car.
  - `parkingLot`: ID of the parking spot.
- **Response:**
  - Returns a `ticketId`.
- **Example:**
  ```bash
  curl -X POST "http://<PUBLIC_IP>:8000/entry?plate=123-ABC-456&parkingLot=101"

### POST /exit
- **Purpose:** Logs a car's exit from the parking lot and calculates the parking fee.
- **Parameters:**
  - `ticketId`: ID of the parking ticket.
- **Response:**
  - Returns a JSON object with the license plate, total parked time in minutes, parking lot ID, and the calculated charge.
- **Example:**
  ```bash
  curl -X POST "http://<PUBLIC_IP>:8000/exit?ticketId=5678"

## Deployment

### Prerequisites
- AWS CLI configured with your credentials.
- Git installed on your local machine.

### Deployment Steps
1. **Clone the Repository:**
   ```sh
   git clone https://github.com/sizarnaw/CloudParkingLot
   cd CloudParkingLot
   ./setup.sh

  ## Testing Endpoints
To test the system's endpoints, use the following curl commands:

### Entry
- **Command:**
  ```bash
  curl -X POST "http://<PUBLIC_IP>:8000/entry?plate=<PLATE>&parkingLot=<SPOT>"

### EXIT
- **Command:**
  ```bash
  curl -X POST "http://<PUBLIC_IP>:8000/exit?ticketId=<TICKET_ID>"
