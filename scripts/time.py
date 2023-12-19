#! /usr/bin/env python3

import argparse
from datetime import datetime, timezone

DATE_FORMAT="%Y-%m-%d %H:%M:%S";

# Parse positional arguments
parser=argparse.ArgumentParser()
parser.add_argument("date", help="Converts date to UTC timestamp")
parser.add_argument("stamp", help="Converts timestamp to UTC date")
parsed=parser.parse_args()

# Cleanup positional arguments
date = parsed.date.replace("date=", "").upper().replace(" UTC", "")
stamp = parsed.stamp.replace("stamp=", "")

# Convert provided input in UTC format into desired output in UTC as well
if date:
    utc_date = datetime.fromisoformat(date).replace(tzinfo=timezone.utc)
    print(utc_date)
    print(int(utc_date.timestamp()))
if stamp:
    utc_date = datetime.fromtimestamp(int(stamp), timezone.utc)
    print(utc_date)
    print(utc_date.strftime(DATE_FORMAT))
