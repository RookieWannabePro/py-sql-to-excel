from configparser import ConfigParser

config = ConfigParser()

config["DATABASE"] = {
    "username": 'bosel',
    "password": "bosel1",
    "dsn": "192.168.13.32:1521/svbo"
}

with open("config.ini", "w") as f:
    config.write(f)