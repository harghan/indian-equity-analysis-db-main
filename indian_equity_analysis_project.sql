-- Indian Stock Market DB by Harsha Ghandikota

-- Reset DB
DROP DATABASE IF EXISTS stock_market;
CREATE DATABASE stock_market;
USE stock_market;

-- Company info
CREATE TABLE companies (
    symbol VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    sector VARCHAR(50),
    listing_date DATE,
    INDEX(sector)
);

-- Market indices
CREATE TABLE indices (
    index_symbol VARCHAR(20) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT
);

-- Daily stock prices
CREATE TABLE stock_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    date DATE NOT NULL,
    open DECIMAL(12,2),
    high DECIMAL(12,2),
    low DECIMAL(12,2),
    close DECIMAL(12,2),
    volume BIGINT,
    source VARCHAR(50) DEFAULT 'NSE',
    FOREIGN KEY (symbol) REFERENCES companies(symbol),
    UNIQUE KEY (symbol, date)
);

-- Which stocks belong to which index
CREATE TABLE index_constituents (
    index_symbol VARCHAR(20),
    stock_symbol VARCHAR(20),
    weight DECIMAL(5,2),
    PRIMARY KEY (index_symbol, stock_symbol),
    FOREIGN KEY (index_symbol) REFERENCES indices(index_symbol),
    FOREIGN KEY (stock_symbol) REFERENCES companies(symbol)
);

-- My personal holdings
CREATE TABLE portfolio (
    portfolio_id INT AUTO_INCREMENT PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL,
    purchase_date DATE NOT NULL,
    quantity INT NOT NULL,
    purchase_price DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (symbol) REFERENCES companies(symbol)
);

-- Procedure to load or update stock prices
DELIMITER $$

CREATE PROCEDURE LoadStockData(
    IN p_symbol VARCHAR(20),
    IN p_date DATE,
    IN p_open DECIMAL(12,2),
    IN p_high DECIMAL(12,2),
    IN p_low DECIMAL(12,2),
    IN p_close DECIMAL(12,2),
    IN p_volume BIGINT,
    IN p_source VARCHAR(50)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM stock_data 
        WHERE symbol = p_symbol AND date = p_date
    ) THEN
        INSERT INTO stock_data (
            symbol, date, open, high, low, close, volume, source
        ) VALUES (
            p_symbol, p_date, p_open, p_high, p_low, p_close, p_volume, p_source
        );
    ELSE
        UPDATE stock_data
        SET 
            open = p_open,
            high = p_high,
            low = p_low,
            close = p_close,
            volume = p_volume,
            source = p_source
        WHERE symbol = p_symbol AND date = p_date;
    END IF;
END$$

DELIMITER ;

-- Sample data
INSERT INTO companies VALUES
('RELIANCE', 'Reliance Industries Ltd', 'Energy', '1995-01-01'),
('TCS', 'Tata Consultancy Services', 'IT', '2004-08-25'),
('HDFCBANK', 'HDFC Bank Ltd', 'Financial', '1995-05-01');

INSERT INTO indices VALUES
('NIFTY50', 'Nifty 50', 'Benchmark index'),
('SENSEX', 'BSE Sensex', 'Top 30 BSE stocks');

CALL LoadStockData('RELIANCE', '2024-01-01', 2500.00, 2550.00, 2490.00, 2540.00, 1000000, 'NSE');
CALL LoadStockData('TCS', '2024-01-01', 3800.00, 3850.00, 3780.00, 3840.00, 500000, 'BSE');

INSERT INTO index_constituents VALUES
('NIFTY50', 'RELIANCE', 10.5),
('NIFTY50', 'TCS', 8.75),
('SENSEX', 'RELIANCE', 12.0);

INSERT INTO portfolio VALUES
(NULL, 'RELIANCE', '2024-01-01', 10, 2500.00),
(NULL, 'TCS', '2024-01-01', 5, 3800.00);

-- Validation
SELECT symbol, date, COUNT(*) AS dupes
FROM stock_data
GROUP BY symbol, date
HAVING dupes > 1;

SELECT 
    symbol,
    SUM(CASE WHEN open IS NULL THEN 1 ELSE 0 END) AS missing_open,
    SUM(CASE WHEN volume = 0 THEN 1 ELSE 0 END) AS zero_volume_days
FROM stock_data
GROUP BY symbol;

SELECT 
    index_symbol,
    COUNT(DISTINCT stock_symbol) AS num_stocks,
    SUM(weight) AS total_weight
FROM index_constituents
GROUP BY index_symbol
HAVING total_weight NOT BETWEEN 99 AND 101;

-- RSI (14-day)
WITH price_deltas AS (
    SELECT symbol, date, close,
           LAG(close) OVER (PARTITION BY symbol ORDER BY date) AS prev_close
    FROM stock_data
),
rsi_base AS (
    SELECT symbol, date, close,
           GREATEST(close - prev_close, 0) AS gain,
           GREATEST(prev_close - close, 0) AS loss
    FROM price_deltas
),
rsi_agg AS (
    SELECT symbol, date, close,
           AVG(gain) OVER (PARTITION BY symbol ORDER BY date ROWS 13 PRECEDING) AS avg_gain,
           AVG(loss) OVER (PARTITION BY symbol ORDER BY date ROWS 13 PRECEDING) AS avg_loss
    FROM rsi_base
)
SELECT symbol, date, close,
       ROUND(100 - 100 / (1 + avg_gain / NULLIF(avg_loss, 0)), 2) AS rsi_14
FROM rsi_agg
WHERE date >= '2024-01-01';

-- Sector returns during elections
SELECT c.sector,
       AVG((sd.close - sd.open)/sd.open * 100) AS avg_daily_return,
       STDDEV((sd.close - sd.open)/sd.open) AS volatility
FROM stock_data sd
JOIN companies c ON sd.symbol = c.symbol
WHERE sd.date BETWEEN '2024-04-01' AND '2024-06-30'
GROUP BY c.sector
ORDER BY avg_daily_return DESC;

-- My portfolio gains
SELECT p.symbol, p.quantity, p.purchase_price,
       sd.close AS current_price,
       (sd.close - p.purchase_price) * p.quantity AS unrealized_pnl,
       ROUND((sd.close / p.purchase_price - 1) * 100, 2) AS percent_return
FROM portfolio p
JOIN (
    SELECT symbol, MAX(date) AS latest_date
    FROM stock_data
    GROUP BY symbol
) latest ON p.symbol = latest.symbol
JOIN stock_data sd ON p.symbol = sd.symbol AND sd.date = latest.latest_date;

-- Bollinger Bands
WITH stats AS (
    SELECT symbol, date, close,
           AVG(close) OVER (PARTITION BY symbol ORDER BY date ROWS 19 PRECEDING) AS ma_20,
           STDDEV(close) OVER (PARTITION BY symbol ORDER BY date ROWS 19 PRECEDING) AS std_20
    FROM stock_data
)
SELECT symbol, date, close, ma_20,
       ma_20 + 2 * std_20 AS upper_band,
       ma_20 - 2 * std_20 AS lower_band
FROM stats
WHERE date >= '2024-01-01';

-- Speed things up
CREATE INDEX idx_symbol_date ON stock_data(symbol, date);
CREATE INDEX idx_sector ON companies(sector);
CREATE INDEX idx_index_constituents ON index_constituents(index_symbol, stock_symbol);

-- Optional partitioning (if using MySQL 8+)
ALTER TABLE stock_data 
PARTITION BY RANGE COLUMNS(date) (
    PARTITION p2023 VALUES LESS THAN ('2024-01-01'),
    PARTITION p2024 VALUES LESS THAN ('2025-01-01'),
    PARTITION pfuture VALUES LESS THAN MAXVALUE
);
