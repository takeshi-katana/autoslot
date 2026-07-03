# AutoSlot

AutoSlot is a Phoenix LiveView MVP for online booking management in a small auto service company.

The project simulates a real business case where customers can choose an auto service, select an available time slot, enter vehicle information, and create a booking online. Staff members can manage bookings from a simple admin-oriented interface.

## Problem

Small auto service companies often manage customer bookings manually through phone calls, messengers, or spreadsheets.

This creates several operational problems:

- staff spend too much time answering repetitive booking requests;
- customers cannot see available time slots before contacting the company;
- double-booking can happen during busy working hours;
- booking history is difficult to track and analyze;
- service duration is often handled manually instead of being calculated by the system.

## Solution

AutoSlot provides a simple online booking flow for customers and a basic booking management foundation for staff.

The MVP focuses on the core scheduling process:

1. the customer selects a service;
2. the customer selects a date;
3. the system shows available time slots;
4. the customer enters contact and vehicle information;
5. the system creates a booking;
6. staff can view and manage bookings.

## MVP Scope

Current planned MVP scope:

- service catalog;
- booking creation;
- available time slot calculation;
- prevention of double-booking;
- booking statuses;
- admin booking dashboard;
- seed data for local development;
- tests for booking logic;
- GitHub Actions CI.

## Out of Scope

The following features are intentionally not included in the initial MVP:

- online payments;
- SMS notifications;
- CRM integration;
- customer authentication;
- staff role management;
- analytics dashboard;
- production deployment.

## Tech Stack

- Elixir
- Phoenix Framework
- Phoenix LiveView
- Ecto
- PostgreSQL
- ExUnit
- GitHub Actions

## Local Development

### Requirements

- Elixir
- Erlang/OTP
- PostgreSQL
- Node.js is not required for the default Phoenix 1.8 asset pipeline
- Git

### Setup

Clone the repository:

```bash
git clone https://github.com/takeshi-katana/autoslot.git
cd autoslot