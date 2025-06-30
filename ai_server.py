from fastapi import FastAPI, File, UploadFile
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware
import cv2
import numpy as np

app = FastAPI()

# Allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/process-image/")
async def process_image(file: UploadFile = File(...)):
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    # Color Shift Filter: Convert to HSV and rotate the hue channel
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    h, s, v = cv2.split(hsv)

    shift_value = 60  # You can adjust this to rotate hue more or less
    h = (h.astype(np.uint16) + shift_value) % 180
    h = h.astype(np.uint8)

    shifted_hsv = cv2.merge([h, s, v])
    color_shifted = cv2.cvtColor(shifted_hsv, cv2.COLOR_HSV2BGR)

    # Encode back to JPEG
    _, encoded_img = cv2.imencode('.jpg', color_shifted)
    return Response(content=encoded_img.tobytes(), media_type="image/jpeg")
