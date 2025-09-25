import pandas as pd

from utils.db import get_engine

engine = get_engine()


def upload_csv_to_table(csv_path, table_name):
    df = pd.read_csv(csv_path)
    df.to_sql(table_name, engine, if_exists="replace", index=False)
    print(f"✅ {table_name} uploaded")


# Example:
# upload_csv_to_table('data/sample_seed.csv', 'ingredients')
