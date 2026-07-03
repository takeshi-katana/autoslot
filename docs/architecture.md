# Architecture

AutoSlot is built as a Phoenix application with PostgreSQL persistence.

The project follows the default Phoenix structure and separates business logic from the web layer.

## High-Level Structure

```text
Customer Browser
      |
      v
Phoenix Web Layer
      |
      v
Application Contexts
      |
      v
Ecto Repo
      |
      v
PostgreSQL