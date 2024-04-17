from datetime import datetime, timedelta


date = datetime.now().strftime("%Y%m")

text = "AND a.udate BETWEEN ':startMonth26' AND ':endMonth25'"

text = text.replace(':startMonth26', date)
text = text.replace(':endMonth25', date)

print(text)

print(date)