# 화면(정적 파일) + nginx. /predict 요청은 같은 주소에서 API 컨테이너로 넘겨 줌
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html app.js /usr/share/nginx/html/
