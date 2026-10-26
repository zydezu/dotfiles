import json
import urllib.request


def get_location_from_ip():
    """Try multiple IP geolocation services, return (lat, lon, city)."""
    services = [
        {
            "url": "https://ipapi.co/json/",
            "lat": "latitude",
            "lon": "longitude",
            "city": "city",
        },
        {
            "url": "https://ipwho.is/",
            "lat": "latitude",
            "lon": "longitude",
            "city": "city",
        },
        {
            "url": "https://ip-api.com/json/?fields=lat,lon,city,status",
            "lat": "lat",
            "lon": "lon",
            "city": "city",
            "check": lambda r: r.get("status") == "success",
        },
    ]
    for svc in services:
        try:
            req = urllib.request.Request(svc["url"], headers={"User-Agent": "curl/8.0"})
            resp = json.loads(urllib.request.urlopen(req, timeout=5).read())
            if "check" in svc and not svc["check"](resp):
                continue
            return str(resp[svc["lat"]]), str(resp[svc["lon"]]), resp.get(svc["city"])
        except Exception:
            continue
    raise RuntimeError("All IP geolocation services failed")


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

    match code:
        case 0:
            return icon["clear"]
        case 1 | 2:
            return icon["partly"]
        case 3:
            return icon["cloudy"]
        case 45 | 48:
            return icon["fog"]
        case c if 51 <= c <= 60:
            return icon["drizzle"]
        case c if 61 <= c <= 67:
            return icon["rain"]
        case c if 71 <= c <= 77:
            return icon["snow"]
        case c if 80 <= c <= 82:
            return icon["shower"]
        case c if c >= 95:
            return icon["storm"]
        case _:
            return "?"


def get_description(code):
    match code:
        case 0:
            return "Clear sky"
        case 1:
            return "Mainly clear"
        case 2:
            return "Partly cloudy"
        case 3:
            return "Overcast"
        case 45 | 48:
            return "Fog"
        case c if 51 <= c <= 55:
            return "Drizzle"
        case 56 | 57:
            return "Freezing drizzle"
        case c if 61 <= c <= 65:
            return "Rain"
        case 66 | 67:
            return "Freezing rain"
        case c if 71 <= c <= 75:
            return "Snow"
        case 77:
            return "Snow grains"
        case c if 80 <= c <= 82:
            return "Rain showers"
        case 85 | 86:
            return "Snow showers"
        case 95:
            return "Thunderstorm"
        case 96 | 99:
            return "Thunderstorm with hail"
        case _:
            return "Unknown"


lat, lon, city = get_location_from_ip()

url = (
    f"https://api.open-meteo.com/v1/forecast"
    f"?latitude={lat}&longitude={lon}"
    f"&current=temperature_2m,weather_code,is_day&timezone=auto"
)
data = json.loads(urllib.request.urlopen(url).read())
current = data["current"]
code = current["weather_code"]
is_day = current["is_day"] == 1
temp = round(current["temperature_2m"])
unit = data["current_units"]["temperature_2m"]
icon = get_icon(code, is_day)
desc = get_description(code)

print(f"{icon} {temp}{unit} · {desc}")
