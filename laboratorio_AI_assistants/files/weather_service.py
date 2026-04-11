import requests


def get_weather(location):
    """Fetches weather information for a given location."""
    response = requests.get(f"https://api.weather.com/v3/weather/{location}")
    return response.json()
