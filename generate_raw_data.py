import pandas as pd
import numpy as np
from datetime import datetime

# Set seed for reproducibility
np.random.seed(42)

print("Starting Master Data Generation...")

# ── STEP 1: Generate Base Time Series ──
date_rng = pd.date_range(start='2009-01-01', end='2026-12-31 23:00:00', freq='H')
locations = [
    'Coney Street', 'Parliament Street at M&S', 'Church Street', 
    'Micklegate', 'Stonegate', 'Parliament Street', 'Parliament Street (New Camera)'
]

print("Building Date/Location matrix (1.1M+ rows)...")
df = pd.MultiIndex.from_product([date_rng, locations], names=['Date', 'LocationName']).to_frame(index=False)
df = df.sort_values(by=['LocationName', 'Date']).reset_index(drop=True)

# ── STEP 2: Base Temporal Features ──
df['Hour'] = df['Date'].dt.hour
df['WeekDay'] = df['Date'].dt.day_name()
df['BRCYear'] = df['Date'].dt.year
df['BRCMonth'] = df['Date'].dt.month_name()
df['DayOfMonth'] = df['Date'].dt.day
df['DayOfYear'] = df['Date'].dt.dayofyear
df['DateOnly'] = df['Date'].dt.date

month_map = {
    'January':'Winter', 'February':'Winter', 'March':'Spring', 'April':'Spring', 
    'May':'Spring', 'June':'Summer', 'July':'Summer', 'August':'Summer', 
    'September':'Autumn', 'October':'Autumn', 'November':'Autumn', 'December':'Winter'
}
df['Season'] = df['BRCMonth'].map(month_map)

# Bank Holidays
bank_holiday_sundays = [123, 148, 238] 
df['IsWeekend'] = np.where(
    df['WeekDay'].isin(['Friday','Saturday']) | 
    ((df['WeekDay'] == 'Sunday') & (df['DayOfYear'].isin(bank_holiday_sundays))), 1, 0
)

def night_period(h):
    if 18 <= h <= 20:   return 'Early Evening'
    elif 21 <= h <= 23: return 'Peak Night'
    elif 0 <= h <= 5:   return 'Late Night'
    else:               return 'Daytime'
df['NightPeriod'] = df['Hour'].apply(night_period)

# ── STEP 3: CITY-WIDE WEATHER, HOLIDAYS & PAYDAY ──
print("Simulating Events, Weather, and Payday Weekends...")
unique_dates = pd.DataFrame({'DateOnly': df['DateOnly'].unique()})

# Weather Washouts
unique_dates['Weather_Multiplier'] = np.where(np.random.rand(len(unique_dates)) < 0.05, 0.4, 1.0)
df = df.merge(unique_dates, on='DateOnly', how='left')

# Fixed Holidays
df['Holiday_Multiplier'] = np.where((df['BRCMonth'] == 'December') & (df['DayOfMonth'] == 31), 3.5, 1.0)
df['Holiday_Multiplier'] = np.where((df['BRCMonth'] == 'October') & (df['DayOfMonth'] >= 29), 2.0, df['Holiday_Multiplier'])

# The "Payday Weekend" Effect (Last weekend of the month)
df['Payday_Multiplier'] = np.where((df['IsWeekend'] == 1) & (df['DayOfMonth'] >= 25), 1.35, 1.0)

# ── STEP 4: SIMULATE REALISTIC FOOTFALL ──
print("Calculating Macro-Economic Crowd Behavior...")

# Base Log-Normal
mu = np.log(70)
sigma = 0.65
base_count = np.random.lognormal(mean=mu, sigma=sigma, size=len(df))

time_multiplier = np.where(df['NightPeriod'] == 'Daytime', 1.2, 
                  np.where(df['NightPeriod'] == 'Peak Night', 2.5, 
                  np.where(df['NightPeriod'] == 'Early Evening', 1.5, 0.4)))
weekend_multiplier = np.where(df['IsWeekend'] == 1, 1.8, 1.0)
season_multiplier = df['Season'].map({'Winter': 0.65, 'Spring': 0.95, 'Summer': 1.35, 'Autumn': 1.0})

# COVID-19 Lockdown Black Swan
pandemic_multiplier = np.where(df['BRCYear'] == 2020, 0.15, 
                      np.where(df['BRCYear'] == 2021, 0.60, 1.0))

# Macro-Decay ("Death of the High Street" - footfall slowly drops year over year)
# 2009 = 1.0 multiplier, slowly dropping to ~0.75 by 2026
macro_decay = 1.0 - ((df['BRCYear'] - 2009) * 0.015) 

raw_footfall = (base_count * time_multiplier * weekend_multiplier * season_multiplier * pandemic_multiplier * df['Weather_Multiplier'] * df['Holiday_Multiplier'] * df['Payday_Multiplier'] * macro_decay)

# Autocorrelation (Smoothing)
df['TotalCount'] = raw_footfall
df['TotalCount'] = df.groupby('LocationName')['TotalCount'].transform(lambda x: x.rolling(window=3, min_periods=1).mean())

# Physical Saturation (Hard limits per location so we don't break the laws of physics)
location_caps = {
    'Coney Street': 4500, 'Parliament Street at M&S': 5500, 'Church Street': 2800, 
    'Micklegate': 3500, 'Stonegate': 2500, 'Parliament Street': 5000, 'Parliament Street (New Camera)': 5000
}
df['MaxCapacity'] = df['LocationName'].map(location_caps)
# Clip bottom at 1, clip top at the physical street capacity
df['TotalCount'] = np.clip(df['TotalCount'], 1, df['MaxCapacity']).astype(int)

# ── STEP 5: REACTIVE ECONOMIC VARIABLES ──
print("Calculating Reactive Variables...")
df['bar_restaurant_count_nearby'] = np.random.randint(14, 25, len(df))
df['night_bus_frequency'] = np.random.randint(1, 8, len(df))

# Uber & Police react to crowds
footfall_90th = df['TotalCount'].quantile(0.90)
df['uber_surge_active'] = np.where(df['TotalCount'] > footfall_90th, 1, (np.random.rand(len(df)) < 0.1).astype(int))
df['police_visibility_score'] = np.where(df['TotalCount'] > footfall_90th, 5, np.random.randint(1, 4, len(df)))

inflation_map = {
    2009:100.0, 2010:103.1, 2011:107.4, 2012:110.2, 2013:113.0, 
    2014:115.6, 2015:116.8, 2016:118.9, 2017:122.1, 2018:125.4, 
    2019:127.6, 2020:128.8, 2021:132.1, 2022:144.1, 2023:155.2,
    2024:159.4, 2025:163.0, 2026:166.5
}
df['hospitality_inflation_index'] = (df['BRCYear'].map(inflation_map) + np.random.uniform(-1.5, 1.5, len(df))).round(1)

avg_spend = np.random.uniform(10, 25, len(df))
df['estimated_revenue_gbp'] = (df['TotalCount'] * avg_spend * (df['hospitality_inflation_index']/100)).round(2)
df['live_event_happening'] = np.where(df['Holiday_Multiplier'] > 1.0, 1, (np.random.rand(len(df)) < 0.05).astype(int))
df['hospitality_jobs_active'] = (df['TotalCount'] * 0.15 + np.random.randint(5, 20, len(df))).astype(int)
df['market_gdp_contribution_gbp'] = (df['estimated_revenue_gbp'] * 1.45 * np.random.uniform(0.95, 1.05, len(df))).round(2)

df = df.drop(columns=['DateOnly', 'Weather_Multiplier', 'Holiday_Multiplier', 'DayOfMonth', 'DayOfYear', 'Payday_Multiplier', 'MaxCapacity'])

# ── STEP 6: INTENTIONAL DATA CORRUPTION (Contiguous NAs) ──
print("Injecting Contiguous Sensor Failures (Dead Batteries)...")
num_outages = int(len(df) * 0.001)
outage_starts = np.random.choice(df.index, size=num_outages, replace=False)

for start_idx in outage_starts:
    outage_length = np.random.randint(12, 48)
    end_idx = min(start_idx + outage_length, len(df))
    df.loc[start_idx:end_idx, 'TotalCount'] = np.nan

# 4% Duplicate Rows (Network double-pings)
duplicates = df.sample(frac=0.04, random_state=42)
df = pd.concat([df, duplicates], ignore_index=True)

# Shuffle chronological order to simulate messy API Pulls
df = df.sample(frac=1, random_state=99).reset_index(drop=True)

# ── STEP 7: Export ──
print("Formatting and exporting...")
df['Date'] = pd.to_datetime(df['Date']).dt.strftime('%d/%m/%Y %H:%M:%S')
df.insert(0, 'Id', range(1, len(df) + 1))
df.to_csv("raw_footfall.csv", index=False)

print(f"Success! Generated flawless master dataset.")