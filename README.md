# Vector Store + n8n Platform

통합 벡터 스토어와 n8n 워크플로우 자동화를 제공하는 플랫폼입니다.

## 🚀 주요 기능

- **pgvector**: PostgreSQL 기반 벡터 데이터베이스로 임베딩 저장 및 유사도 검색
- **n8n**: 워크플로우 자동화 플랫폼
- **Supabase**: 인증, 실시간 데이터베이스, 스토리지 제공
- **Redis**: 캐싱 및 큐 관리
- **Nginx**: 리버스 프록시 및 로드 밸런싱

## 📋 요구사항

- Docker & Docker Compose
- 최소 4GB RAM
- 10GB 이상의 디스크 공간

## 🛠️ 설치 및 실행

### 1. 프로젝트 클론
```bash
git clone <repository-url>
cd vector-n8n-platform
```

### 2. 환경 설정
```bash
cp .env.example .env
# .env 파일을 편집하여 필요한 설정 변경
```

### 3. 플랫폼 시작
```bash
chmod +x scripts/*.sh
./scripts/ignite.sh
```

## 🔑 기본 접속 정보

- **n8n**: http://localhost:5678
  - 계정: admin / n8n_admin_secure_2024!
- **API**: http://localhost/api/rest/v1/
- **Health Check**: http://localhost/health

## 📁 프로젝트 구조

```
vector-n8n-platform/
├── docker-compose.yml      # 도커 컴포즈 설정
├── .env                    # 환경 변수
├── init-db/               # DB 초기화 스크립트
│   ├── 00-init-roles.sql  # 역할 생성
│   ├── 01-init-extensions.sql  # Extension 설치
│   ├── 02-init-databases.sql   # DB 생성
│   ├── 03-init-schemas.sql     # 스키마 생성
│   ├── 04-init-supabase.sql    # Supabase 초기화
│   ├── 05-init-vector.sql      # Vector Store 초기화
│   └── 10-init-app-tables.sql  # 애플리케이션 테이블
├── nginx/                 # Nginx 설정
├── scripts/              # 유틸리티 스크립트
│   ├── ignite.sh        # 시작 스크립트
│   ├── check-health.sh  # 헬스 체크
│   └── reset.sh         # 리셋 스크립트
└── volumes/             # 데이터 볼륨
```

## 🔧 주요 API 엔드포인트

### Vector Store API
```bash
# 문서 추가
POST /api/rest/v1/rpc/add_document
{
  "p_content": "문서 내용",
  "p_metadata": {"key": "value"},
  "p_collection": "default"
}

# 유사 문서 검색
POST /api/rest/v1/rpc/search_documents
{
  "query_embedding": [0.1, 0.2, ...],
  "match_count": 10,
  "collection": "default"
}
```

### n8n Webhook
```bash
POST /webhook/<webhook-id>
```

## 🐛 문제 해결

### 서비스 상태 확인
```bash
./scripts/check-health.sh
```

### 로그 확인
```bash
docker-compose logs -f [service-name]
```

### 완전 리셋
```bash
./scripts/reset.sh
```

## 🔒 보안 설정

1. `.env` 파일의 모든 기본 비밀번호 변경
2. JWT_SECRET 생성: https://jwt.io/
3. SSL 인증서 설정 (프로덕션)
4. 방화벽 설정

## 📝 라이선스

MIT License