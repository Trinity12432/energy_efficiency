FROM public.ecr.aws/lambda/python:3.11

# 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 모델 파일과 핸들러 코드 복사
COPY model.pkl ${LAMBDA_TASK_ROOT}
COPY lambda_function.py ${LAMBDA_TASK_ROOT}

# Lambda가 호출할 핸들러 지정 (파일명.함수명)
CMD ["lambda_function.lambda_handler"]
