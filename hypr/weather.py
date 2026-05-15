import json
import os
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


def is_on_ethernet():
    net = "/sys/class/net"
    for iface in os.listdir(net):
        # Match common ethernet interface naming patterns
        if not any(iface.startswith(p) for p in ("eth", "en", "eno", "enp", "ens")):
            continue
        # Skip wireless interfaces (they have a 'wireless' or 'phy80211' subdir)
        iface_path = os.path.join(net, iface)
        if os.path.exists(os.path.join(iface_path, "wireless")) or os.path.exists(
            os.path.join(iface_path, "phy80211")
        ):
            continue
        # Check interface is up and has a carrier
        operstate = os.path.join(iface_path, "operstate")
        carrier = os.path.join(iface_path, "carrier")
        try:
            up = open(operstate).read().strip() == "up"
            has_carrier = open(carrier).read().strip() == "1"
            if up and has_carrier:
                return True
        except OSError:
            continue
    return False


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


config = os.path.expanduser("~/.config/hypr/location.conf")
on_ethernet = is_on_ethernet()
if os.path.exists(config):
    with open(config) as f:
        parts = [x.strip() for x in f.read().strip().split(",")]
        lat, lon = parts[0], parts[1]
        city = parts[2] if len(parts) > 2 else None
else:
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

location_str = f"{city} · " if (city and not on_ethernet) else ""
print(f"{location_str}{icon} {temp}{unit} · {desc}")
