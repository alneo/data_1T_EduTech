import uvicorn
from fastapi import FastAPI
import os
from typing import Optional
import sys
import subprocess

app = FastAPI()
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=21004, log_level="info")

@app.get("/")
def home_page():
    return {"err": 0, "message": "Success!"}
@app.get("/m2_progress/{model}/{week}/{id_user}")
def m2_progress(model: str, week: int, id_user: int):
    """Получение значения m2_progress по студенту id_user для недели week"""
    command = f"python3 route.py {model} {id_user} {week}"
    return_value = os.popen(command).read()
    return {"err": 0, "message": "m2_progress!", "json": return_value}