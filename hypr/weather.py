import json
import os
import sys

config = os.path.expanduser("~/.config/hypr/location.conf")
with open(config) as f:
    lat, lon = [x.strip() for x in f.read().strip().split(",")]


def get_icon(code, is_day):
    day = {
        "clear": "☀️",
        "partly": "🌤️",
        "cloudy": "☁️",
        "fog": "🌫️",
        "drizzle": "🌦️",
        "rain": "🌧️",
        "snow": "❄️",
        "shower": "🌦️",
        "storm": "⛈️",
    }
    night = {
        "clear": "🌙",
        "partly": "☁️",
        "cloudy": "☁️",
        "fog": "🌫️",
        "drizzle": "🌧️",
        "rain": "🌧️",
        "snow": "❄️",
        "shower": "🌧️",
        "storm": "⛈️",
    }
    icon = day if is_day else night

    if code == 0:
        return icon["clear"]
    if code in [1, 2]:
        return icon["partly"]
    if code == 3:
        return icon["cloudy"]
    if code in [45, 48]:
        return icon["fog"]
    if 51 <= code <= 60:
        return icon["drizzle"]
    if 61 <= code <= 67:
        return icon["rain"]
    if 71 <= code <= 77:
        return icon["snow"]
    if 80 <= code <= 82:
        return icon["shower"]
    if code >= 95:
        return icon["storm"]
    return "?"


def get_description(code):
    if code == 0:
        return "Clear sky"
    if code == 1:
        return "Mainly clear"
    if code == 2:
        return "Partly cloudy"
    if code == 3:
        return "Overcast"
    if code in [45, 48]:
        return "Fog"
    if 51 <= code <= 55:
        return "Drizzle"
    if code in [56, 57]:
        return "Freezing drizzle"
    if 61 <= code <= 65:
        return "Rain"
    if code in [66, 67]:
        return "Freezing rain"
    if 71 <= code <= 75:
        return "Snow"
    if code == 77:
        return "Snow grains"
    if 80 <= code <= 82:
        return "Rain showers"
    if code in [85, 86]:
        return "Snow showers"
    if code == 95:
        return "Thunderstorm"
    if code in [96, 99]:
        return "Thunderstorm with hail"
    return "Unknown"


data = json.load(sys.stdin)
current = data["current"]
code = current["weather_code"]
is_day = current["is_day"] == 1
temp = round(current["temperature_2m"])
unit = data["current_units"]["temperature_2m"]

icon = get_icon(code, is_day)
desc = get_description(code)

print(f"{icon} {temp}{unit} - {desc}")
