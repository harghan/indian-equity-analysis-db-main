**Indian Equity Analysis DB**

A Structured, SQL-Only Sandbox for Equity Research, Built from Scratch

This project simulates a lean research engine for analyzing the Indian stock market using only SQL. It’s designed to test trading ideas, track portfolio performance, and run technical analysis — all within a well-indexed, query-efficient database.

I built this because I wanted full control over structure, integrity, and insights without relying on external dashboards or bloated tools.

**What This Project Covers**

 - Relational schema for equities, indices, and portfolios

 - A stored procedure for loading and updating price data

 - Queries for technical indicators like RSI, Bollinger Bands, and moving averages

 - Sector-level return and volatility tracking

 - Personal portfolio performance: unrealized P&L, percent return

 - Built-in data validation logic for duplicates, weight mismatches, and missing values

 - Indexing and partitioning for scale

**Why I Built This**

Most equity analysis tools abstract away the logic. I wanted the opposite — a transparent, SQL-based system that reflects how real trading and portfolio tracking work.

This was a hands-on way to push my SQL thinking beyond just syntax:

 - Schema design

 - Window functions

 - Data cleaning

 - Query performance

**Technical indicator logic**

The result is something that feels real — something I can run live ideas on.

**Use Cases**

This project has helped me:

 - Compare sector-wise performance during the **2024 Indian elections**

 - Backtest a simple RSI-based momentum filter across my portfolio

 - Flag errors in index weighting logic (e.g., NIFTY50 total ≠ 100%)

 - Quantify the unrealized returns of each holding on my books

 - Simulate signals like moving average crossovers using only SQL

These aren’t hypothetical. Every query here was written to answer a real question I had while trading.

**Key Features**

 - **Schema Design**
   
    Clean, normalized tables: companies, stock_data, indices, index_constituents, and portfolio, with all necessary foreign keys and constraints.

 - **Data Ingestion**

    The LoadStockData procedure handles conditional insert/update logic for daily stock price data. Easily extensible.

**Technical Indicators**

 - **RSI (14-day)**

 - **Bollinger Bands**

 - **Moving averages (via window functions)**


**Portfolio Logic** 

   - P&L calculation using latest price
   
   - % returns and investment gain/loss
   
   - Tracks by symbol, purchase price, and quantity
   
   - Validation Checks
   
   - Duplicate detection (symbol/date)
   
   - Missing value flags
   
   - Index weight validation

**Performance Scaling**

 - Composite indexing on (symbol, date)

 - Partitioning by date for scalable performance


**How to Use** 

 - Clone the repo

 - Load the indian_equity_analysis_project.sql file in any MySQL 8+ instance

 - Sample data is included — no external dependencies

 - Run analysis directly via included query blocks

**What This Project Demonstrates**
 
 - Structured thinking in schema design

 - Applied SQL using CTEs, window functions, and procedural logic

 - End-to-end problem solving: from ingestion to insight

 - Performance-aware indexing and validation

 - Practical use of SQL in real capital market workflows

**Contact**

**Harsha Ghandikota** 

linkedin.com/in/harsha-ghandikota
