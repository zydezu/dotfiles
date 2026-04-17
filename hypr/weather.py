import json
import os
import sys

config = os.path.expanduser("~/.config/hypr/location.conf")
with open(config) as f:
    lat, lon = f.read().strip().split(",")

codes = {
    0: "☀️",
    1: "🌤️",
    2: "⛅",
    3: "☁️",
    45: "🌫️",
    48: "🌫️",
    51: "🌦️",
    53: "🌦️",
    55: "🌧️",
    61: "🌧️",
    63: "🌧️",
    65: "🌧️",
    71: "🌨️",
    73: "🌨️",
    75: "❄️",
    80: "🌦️",
    81: "🌧️",
    82: "⛈️",
    95: "⛈️",
    96: "⛈️",
    99: "⛈️",
}

d = json.load(sys.stdin)["current"]
icon = codes.get(d["weather_code"], "?")
print(f"{icon} {d['temperature_2m']}°C")
