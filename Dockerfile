# Node.js 22.16 버전의 Alpine Linux 기반 이미지를 사용하여 빌드 단계를 정의
# Alpine은 경량화된 Linux 배포판으로 Docker 이미지 크기를 줄이는 데 효과적
FROM node:22.16-alpine AS build

# 컨테이너 내부의 작업 디렉토리를 /app으로 설정
# 이후 모든 명령어는 이 디렉토리에서 실행됨
WORKDIR /app

# Node.js 바이너리들을 PATH에 추가하여 npm, npx 등의 명령어를 쉽게 사용할 수 있도록 설정
# /app/node_modules/.bin 경로를 시스템 PATH 앞부분에 추가
ENV PATH=/app/node_modules/.bin:$PATH

# package.json과 package-lock.json을 먼저 복사 (Docker 레이어 캐싱 최적화)
# package-lock.json이 있다면 정확한 버전의 의존성을 보장
COPY package*.json /app/

# package.json에 정의된 모든 의존성 패키지들을 설치
# --frozen-lockfile 플래그로 package-lock.json 기준으로 정확한 버전 설치
RUN npm ci --only=production

# 개발 의존성도 설치 (빌드에 필요한 도구들)
RUN npm install

# 현재 디렉토리의 모든 파일들(소스 코드)을 컨테이너의 /app 디렉토리로 복사
# .dockerignore 파일이 있다면 해당 파일에 명시된 파일들은 제외됨
COPY . /app

# React 애플리케이션을 프로덕션용으로 빌드
# Vite는 기본적으로 dist 폴더에 빌드 결과물을 생성
RUN npm run build

# 두 번째 단계: Nginx 웹서버 단계
# 안정성을 위해 특정 버전의 Nginx Alpine 이미지 사용
FROM nginx:1.27-alpine

# 보안과 성능을 위해 비-루트 사용자로 실행할 수 있도록 설정
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Nginx의 기본 설정 파일을 제거
# default.conf는 Nginx가 기본으로 제공하는 설정으로, 커스텀 설정을 사용하기 위해 삭제
RUN rm /etc/nginx/conf.d/default.conf

# 호스트의 nginx/nginx.conf 파일을 컨테이너의 Nginx 설정 디렉토리로 복사
# 이 파일에는 React SPA(Single Page Application)를 위한 커스텀 Nginx 설정이 포함됨
COPY nginx/nginx.conf /etc/nginx/conf.d/

# 첫 번째 빌드 단계에서 생성된 React 앱의 빌드 결과물을 Nginx의 정적 파일 서빙 디렉토리로 복사
# --from=build 플래그로 이전 단계의 결과물을 참조
# /app/dist는 Vite 빌드된 파일들이 위치한 경로, /usr/share/nginx/html은 Nginx의 기본 웹 루트 디렉토리
COPY --from=build /app/dist /usr/share/nginx/html

# 빌드된 파일들의 소유권을 nginx 사용자로 변경
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# 컨테이너의 80번 포트를 외부에 노출
EXPOSE 80

# 헬스체크 추가 (선택사항)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# nginx를 포그라운드 모드(-g "daemon off;")로 실행하여 컨테이너가 종료되지 않도록 함
# Docker 컨테이너는 메인 프로세스가 종료되면 컨테이너도 함께 종료되므로 daemon off 옵션이 필요
CMD ["nginx", "-g", "daemon off;"]