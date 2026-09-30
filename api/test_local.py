import json
from Lambda_function import lambda_handler

# 1. 간편 모드 테스트 (평수만)
print("=== 간편 모드 (34평) ===")
event_simple = {"body": json.dumps({"pyeong": 34})}
print(lambda_handler(event_simple, None))

# 2. 정밀 모드 테스트 (8개 다 입력)
print("\n=== 정밀 모드 ===")
event_precise = {"body": json.dumps({
    "relative_compactness": 0.98, "surface_area": 514.5, "wall_area": 294.0,
    "roof_area": 110.25, "height": 7.0, "orientation": 2,
    "glazing_area": 0.0, "glazing_dist": 0
})}
print(lambda_handler(event_precise, None))

# 3. 에러 케이스
print("\n=== 에러 케이스 (아무것도 없이) ===")
event_bad = {"body": json.dumps({})}
print(lambda_handler(event_bad, None))