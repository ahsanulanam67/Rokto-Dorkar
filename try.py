import requests

def get_lat_lon(address):
    url = f"https://nominatim.openstreetmap.org/search?q={address}&format=json"
    headers = {"User-Agent": "MyGeocodingApp/1.0 (contact@example.com)"}

    try:
        response = requests.get(url, headers=headers, timeout=10)  # Timeout added
        print(f"Status Code: {response.status_code}")  # Debugging
        # print(f"Response Text: {response.text}")  # Debugging
        
        if response.status_code == 200 and response.text.strip():
            data = response.json()
            if data:
                return data[0]["lat"], data[0]["lon"]
            else:
                return "No results found"
        else:
            return f"Error: {response.status_code} - {response.text}"

    except requests.exceptions.Timeout:
        return "Error: Request timed out"
    except requests.exceptions.RequestException as e:
        return f"Error: {e}"

address = "Cumilla Shadar Dakkhin,Cumilla,Chattogram"
print(get_lat_lon(address))
