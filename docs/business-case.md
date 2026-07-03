# Business Case

AutoSlot simulates an internal booking system for a small auto service company.

The project is not a commercial production system. It is a portfolio MVP built around a realistic business scenario.

## Background

Many small auto service companies receive booking requests through phone calls, messengers, and direct customer visits.

This process works when the number of requests is low. However, it becomes inefficient when staff are busy, several customers contact the company at the same time, or different services require different amounts of time.

## Business Problem

Manual booking creates several issues:

- customers cannot see available time slots by themselves;
- staff must manually check the schedule before confirming each booking;
- double-booking may happen by mistake;
- service duration is not always considered accurately;
- booking history is difficult to structure;
- the company depends too much on phone availability.

## Proposed MVP

AutoSlot provides a simple web-based booking flow.

The customer should be able to:

- view available services;
- select a service;
- choose a date;
- see available time slots;
- enter name, phone number, and vehicle plate;
- create a booking.

The staff side should be able to:

- view bookings;
- filter bookings by date;
- update booking status;
- cancel bookings when needed.

## MVP Goals

The MVP is focused on validating the core scheduling logic.

Main goals:

- reduce manual booking work;
- prevent basic double-booking cases;
- make the booking process more transparent for customers;
- provide a foundation for future CRM integration;
- keep the system simple enough for a small company.

## Non-Goals

The MVP does not attempt to solve every business problem.

The following features are excluded from the first version:

- online payments;
- SMS or WhatsApp notifications;
- external CRM integration;
- advanced authentication;
- staff permissions;
- financial reporting;
- mobile application.

## Success Criteria

The MVP can be considered successful if:

- a customer can create a booking without staff assistance;
- unavailable time slots are not offered to customers;
- staff can see created bookings;
- booking logic is covered with automated tests;
- the project can be started locally by another developer using README instructions.