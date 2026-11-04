"""로컬 테스트용 Flask 서버. AWS 에 올라가는 lambda_function.lambda_handler 를 그대로 호출합니다.
(로컬 화면에서 잘 되면 Lambda 에서도 같은 동작이 나오도록)

실행 (저장소 루트에서):  python api/server.py   ->  http://127.0.0.1:8000
필요: pip install flask flask-cors
"""
import os
import sys

from flask import Flask, jsonify, request
from flask_cors import CORS

CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))   # .../api
BASE_DIR = os.path.dirname(CURRENT_DIR)                    # 저장소 루트
for p in (CURRENT_DIR, os.path.join(BASE_DIR, "scripts")):
    if p not in sys.path:
        sys.path.insert(0, p)

import lambda_function  # noqa: E402  (모델은 이 import 때 한 번만 읽힘)

app = Flask(__name__)
CORS(app)


@app.route("/", methods=["GET"])
def index():
    resp = lambda_function.lambda_handler({"httpMethod": "GET"}, None)
    return app.response_class(resp["body"], status=resp["statusCode"], mimetype="application/json")


@app.route("/predict", methods=["POST"])
def predict():
    event = {"httpMethod": "POST", "body": request.get_data(as_text=True)}
    resp = lambda_function.lambda_handler(event, None)
    return app.response_class(resp["body"], status=resp["statusCode"], mimetype="application/json")


if __name__ == "__main__":
    print("ResStock API 서버: http://127.0.0.1:8000  (종료: Ctrl+C)")
    app.run(host="127.0.0.1", port=8000, debug=False)
