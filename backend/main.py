from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def home():
    return {"message": "Welcome to DevFlow"}

@app.get("/health")
def health():
    return {"status": "UP"}