from configparser import ConfigParser

config = ConfigParser()

config["DATABASE"] = {
    "username": 'bosel',
    "password": "bosel1",
    "dsn": "192.168.13.32:1521/svbo"
}

config["POSTGRES"] = {
    "host": "152.42.233.116",
    "database":"kbbank",
    "user":"kbbank",
    "password":"123qwe"
}

with open("config.ini", "w") as f:
    config.write(f)