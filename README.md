# Allocate Workshop Script

This script is used to allocate workshop choices to students based on their preferences. First come first serve basis is used to allocate the workshops for days.

1. Create `input.csv` file with the following format:

```csv
Submission ID,Respondent ID,Submitted at,Your Full Name (Teen's Name),Your Email,Rank/Order Your Choices
PgYbzQ,l0WyWk,2024-08-11 23:25:40,Testing,test@me.com,"Eucharistic Miracles, Science & Religion, Catholic Femininity, Catholic Masculinity, How to Pray, Salvation History"
```

2. Run the following command:

```bash
ruby main.py
```

3. The output will be in printed in the console and saved in `output` folder.
