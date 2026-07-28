import requests
import pandas as pd
from datetime import datetime
import os
import time

BASE_URL = "https://api.jolpi.ca/ergast/f1"

TABLE_KEY_MAP = {
    "circuits": ("CircuitTable", "Circuits"),
    "constructors": ("ConstructorTable", "Constructors"),
    "drivers": ("DriverTable", "Drivers"),
    "races": ("RaceTable", "Races"),
    "results": ("RaceTable", "Races"),
    "sprint": ("RaceTable", "Races"),
    "qualifying": ("RaceTable", "Races"),
    "pitstops": ("RaceTable", "Races"),
    "laps": ("RaceTable", "Races"),
}


def fetch_json(endpoint, params=None, max_retries=5):
    """Fetch JSON data from Jolpica API with pagination and retry support"""
    url = f"{BASE_URL}/{endpoint}"
    all_data = []

    offset = 0
    limit = 500

    while True:
        paginated_params = {"limit": limit, "offset": offset}
        if params:
            paginated_params.update(params)

        data = None
        for attempt in range(max_retries):
            try:
                response = requests.get(url, params=paginated_params, timeout=30)
                if response.status_code == 429:
                    wait_time = 4 * (attempt + 1)
                    print(f"  Rate limited. Waiting {wait_time}s... (attempt {attempt+1}/{max_retries})")
                    time.sleep(wait_time)
                    continue

                response.raise_for_status()
                data = response.json()
                break
            except requests.exceptions.RequestException as e:
                print(f"  Request error: {e}")
                if attempt == max_retries - 1:
                    print(f"  All retries exhausted for {url}")
                    return all_data
                time.sleep(4 * (attempt + 1))

        if data is None:
            print(f"  Failed to fetch data after {max_retries} retries")
            return all_data

        mrdata = data.get("MRData", {})
        total = int(mrdata.get("total", "0"))

        table_key_name, data_key_name = TABLE_KEY_MAP.get(endpoint.split("/")[-1], (None, None))

        if table_key_name is None:
            for key in mrdata:
                if isinstance(mrdata[key], dict) and key.endswith("Table"):
                    table_key_name = key
                    data_key_name = key.replace("Table", "")
                    if not data_key_name.endswith("s"):
                        data_key_name = data_key_name + "s"
                    break

        table_data = []
        if table_key_name and table_key_name in mrdata:
            table_data = mrdata[table_key_name].get(data_key_name, [])
        elif "CircuitTable" in mrdata:
            table_data = mrdata["CircuitTable"].get("Circuits", [])
        elif "ConstructorTable" in mrdata:
            table_data = mrdata["ConstructorTable"].get("Constructors", [])
        elif "DriverTable" in mrdata:
            table_data = mrdata["DriverTable"].get("Drivers", [])
        elif "RaceTable" in mrdata:
            table_data = mrdata["RaceTable"].get("Races", [])

        if isinstance(table_data, dict):
            table_data = [table_data]

        all_data.extend(table_data)

        if len(all_data) >= total or len(table_data) < limit:
            break

        offset += limit
        time.sleep(4)

    return all_data


def fetch_circuits():
    """Fetch all circuits data"""
    print("Fetching circuits...")
    data = fetch_json("circuits")
    rows = []
    for item in data:
        rows.append({
            "circuitid": item.get("circuitId"),
            "circuitref": item.get("circuitId"),
            "name": item.get("circuitName"),
            "location": item.get("Location", {}).get("locality", ""),
            "country": item.get("Location", {}).get("country", ""),
            "lat": float(item.get("Location", {}).get("lat", 0) or 0),
            "lng": float(item.get("Location", {}).get("long", 0) or 0),
            "alt": int(item.get("Location", {}).get("alt", 0) or 0),
            "url": item.get("url", ""),
        })
    return pd.DataFrame(rows) if rows else pd.DataFrame()


def fetch_constructors(season="2025"):
    """Fetch all constructors data"""
    print("Fetching constructors...")
    data = fetch_json(f"{season}/constructors")
    rows = []
    for item in data:
        rows.append({
            "constructorid": item.get("constructorId"),
            "constructorref": item.get("constructorId"),
            "name": item.get("name"),
            "nationality": item.get("nationality", ""),
            "url": item.get("url", ""),
        })
    return pd.DataFrame(rows) if rows else pd.DataFrame()


def fetch_drivers(season="2025"):
    """Fetch all drivers data"""
    print("Fetching drivers...")
    data = fetch_json(f"{season}/drivers")
    rows = []
    for item in data:
        rows.append({
            "driverid": item.get("driverId"),
            "driverref": item.get("driverId"),
            "number": item.get("number", ""),
            "code": item.get("code", ""),
            "forename": item.get("givenName", ""),
            "surname": item.get("familyName", ""),
            "dob": item.get("dateOfBirth", ""),
            "nationality": item.get("nationality", ""),
            "url": item.get("url", ""),
        })
    return pd.DataFrame(rows) if rows else pd.DataFrame()


def fetch_races(season="2025"):
    """Fetch all races data for a season"""
    print("Fetching races...")
    data = fetch_json(f"{season}/races")
    rows = []
    for item in data:
        rows.append({
            "raceid": item.get("round"),
            "year": item.get("season"),
            "round": item.get("round"),
            "circuitid": item.get("Circuit", {}).get("circuitId"),
            "name": item.get("raceName"),
            "date": item.get("date", ""),
            "time": item.get("time", "").replace("Z", "") if item.get("time") else "",
            "url": item.get("url", ""),
            "fp1_date": item.get("FirstPractice", {}).get("date", ""),
            "fp1_time": item.get("FirstPractice", {}).get("time", "").replace("Z", "") if item.get("FirstPractice", {}).get("time") else "",
            "fp2_date": item.get("SecondPractice", {}).get("date", ""),
            "fp2_time": item.get("SecondPractice", {}).get("time", "").replace("Z", "") if item.get("SecondPractice", {}).get("time") else "",
            "fp3_date": item.get("ThirdPractice", {}).get("date", ""),
            "fp3_time": item.get("ThirdPractice", {}).get("time", "").replace("Z", "") if item.get("ThirdPractice", {}).get("time") else "",
            "quali_date": item.get("Qualifying", {}).get("date", ""),
            "quali_time": item.get("Qualifying", {}).get("time", "").replace("Z", "") if item.get("Qualifying", {}).get("time") else "",
            "sprint_date": item.get("Sprint", {}).get("date", ""),
            "sprint_time": item.get("Sprint", {}).get("time", "").replace("Z", "") if item.get("Sprint", {}).get("time") else "",
        })
    return pd.DataFrame(rows) if rows else pd.DataFrame()


def fetch_results(season="2025"):
    """Fetch all race results for a season"""
    print("Fetching results...")
    rows = []
    for round_num in range(1, 25):
        races = fetch_json(f"{season}/{round_num}/results")
        for race in races:
            results = race.get("Results", [])
            for item in results:
                time_or_result = item.get("Time", {})
                fastest_lap = item.get("FastestLap", {})
                rows.append({
                    "resultid": item.get("resultId"),
                    "raceid": round_num,
                    "driverid": item.get("Driver", {}).get("driverId"),
                    "constructorid": item.get("Constructor", {}).get("constructorId"),
                    "number": item.get("number", ""),
                    "grid": item.get("grid"),
                    "position": item.get("position", ""),
                    "positiontext": item.get("positionText", ""),
                    "positionorder": item.get("position"),
                    "points": item.get("points"),
                    "laps": item.get("laps"),
                    "time": item.get("time", time_or_result.get("time", "")),
                    "milliseconds": time_or_result.get("millis", ""),
                    "fastestlap": fastest_lap.get("lap", ""),
                    "rank": fastest_lap.get("rank", ""),
                    "fastestlaptime": fastest_lap.get("Time", {}).get("time", ""),
                    "fastestlapspeed": fastest_lap.get("AverageSpeed", {}).get("speed", ""),
                    "statusid": item.get("statusId"),
                })
        if races:
            time.sleep(4)
    return pd.DataFrame(rows) if rows else pd.DataFrame()


def fetch_sprint_results(season="2025"):
    """Fetch all sprint results for a season"""
    print("Fetching sprint results...")
    rows = []
    for round_num in range(1, 25):
        races = fetch_json(f"{season}/{round_num}/sprint")
        if not races:
            continue
        for race in races:
            results = race.get("SprintResults", race.get("Results", []))
            for item in results:
                time_or_result = item.get("Time", {})
                fastest_lap = item.get("FastestLap", {})
                rows.append({
                    "resultid": item.get("resultId"),
                    "raceid": round_num,
                    "driverid": item.get("Driver", {}).get("driverId"),
                    "constructorid": item.get("Constructor", {}).get("constructorId"),
                    "number": item.get("number", ""),
                    "grid": item.get("grid"),
                    "position": item.get("position", ""),
                    "positiontext": item.get("positionText", ""),
                    "positionorder": item.get("position"),
                    "points": item.get("points"),
                    "laps": item.get("laps"),
                    "time": item.get("time", time_or_result.get("time", "")),
                    "milliseconds": time_or_result.get("millis", ""),
                    "fastestlap": fastest_lap.get("lap", ""),
                    "rank": fastest_lap.get("rank", ""),
                    "fastestlaptime": fastest_lap.get("Time", {}).get("time", ""),
                    "fastestlapspeed": fastest_lap.get("AverageSpeed", {}).get("speed", ""),
                    "statusid": item.get("statusId"),
                })
        time.sleep(4)
    return pd.DataFrame(rows) if rows else pd.DataFrame()


def fetch_qualifying(season="2025"):
    """Fetch all qualifying data for a season"""
    print("Fetching qualifying...")
    rows = []
    for round_num in range(1, 25):
        races = fetch_json(f"{season}/{round_num}/qualifying")
        if not races:
            continue
        for race in races:
            qualifiers = race.get("QualifyingResults", [])
            for item in qualifiers:
                rows.append({
                    "qualifyid": item.get("qualifyingId"),
                    "raceid": round_num,
                    "driverid": item.get("Driver", {}).get("driverId"),
                    "constructorid": item.get("Constructor", {}).get("constructorId"),
                    "number": item.get("number"),
                    "position": item.get("position"),
                    "q1": item.get("Q1", ""),
                    "q2": item.get("Q2", ""),
                    "q3": item.get("Q3", ""),
                })
        time.sleep(4)
    return pd.DataFrame(rows) if rows else pd.DataFrame()


def fetch_pit_stops(season="2025"):
    """Fetch all pit stops data for a season"""
    print("Fetching pit stops...")
    rows = []
    for round_num in range(1, 25):
        races = fetch_json(f"{season}/{round_num}/pitstops")
        if not races:
            continue
        for race in races:
            pitstops = race.get("PitStops", [])
            for item in pitstops:
                rows.append({
                    "raceid": round_num,
                    "driverid": item.get("driverId"),
                    "stop": item.get("stop"),
                    "lap": item.get("lap"),
                    "time": item.get("time", ""),
                    "duration": item.get("duration", ""),
                    "milliseconds": item.get("milliseconds"),
                })
        time.sleep(4)
    return pd.DataFrame(rows) if rows else pd.DataFrame()


def fetch_lap_times(season="2025"):
    """Fetch all lap times data for a season"""
    print("Fetching lap times...")
    rows = []
    for round_num in range(1, 25):
        races = fetch_json(f"{season}/{round_num}/laps")
        if not races:
            continue
        for race in races:
            laps = race.get("Laps", [])
            for lap in laps:
                timings = lap.get("Timings", [])
                for timing in timings:
                    rows.append({
                        "raceid": round_num,
                        "driverid": timing.get("driverId"),
                        "lap": timing.get("lap"),
                        "position": timing.get("position"),
                        "time": timing.get("time", ""),
                        "milliseconds": None,
                    })
        time.sleep(4)
    return pd.DataFrame(rows) if rows else pd.DataFrame()


def write_to_local(df, output_dir, dataset_type, season):
    """Write DataFrame to local folder"""
    if df is None or df.empty:
        print(f"Warning: {dataset_type} data is empty, skipping.")
        return

    try:
        df = df.copy()
        df.columns = [col.lower() for col in df.columns]
        df['_loaded_at'] = datetime.now().isoformat()
        df['source_system'] = 'jolpica'

        local_path = os.path.join(output_dir, dataset_type, f"season_{season}")
        os.makedirs(local_path, exist_ok=True)
        file_path = os.path.join(local_path, f"{dataset_type}.csv")

        df.to_csv(file_path, index=False)
        print(f"✓ Wrote {dataset_type} to {file_path} ({len(df)} rows)")

    except Exception as e:
        print(f"✗ Error writing {dataset_type}: {e}")
        raise


def main():
    """Main execution: fetch all tables from Jolpica API"""
    season = "2025"
    output_dir = "output/jolpica"

    print(f"\n{'='*80}")
    print(f"Jolpica API Ingestion: Season {season}")
    print(f"Output Dir: {output_dir}")
    print(f"{'='*80}\n")

    fetchers = {
        "bronze_circuits": fetch_circuits,
        "bronze_constructors": lambda: fetch_constructors(season),
        "bronze_driver": lambda: fetch_drivers(season),
        "bronze_races": lambda: fetch_races(season),
        "bronze_results": lambda: fetch_results(season),
        "bronze_sprint_results": lambda: fetch_sprint_results(season),
        "bronze_qualifyings": lambda: fetch_qualifying(season),
        "bronze_pit_stops": lambda: fetch_pit_stops(season),
        "bronze_lap_times": lambda: fetch_lap_times(season),
    }

    for table_name, fetch_func in fetchers.items():
        try:
            print(f"\n{'-'*40}")
            df = fetch_func()
            write_to_local(df, output_dir, table_name, season)
            time.sleep(2)
        except Exception as e:
            print(f"✗ Error fetching {table_name}: {e}")

    print(f"\n{'='*80}")
    print(f"Season {season} ingestion completed")
    print(f"{'='*80}\n")


if __name__ == "__main__":
    main()
