1. 요건 정의
  - * https
  - * 업데이트 일시 중지
  - * 서버 인증서 검증
  - * 로그 
  - * 업데이트 확인 요청
  - * 업데이트 파일 요청
  - * 결과 보고

  - cross platform
  - p2p
  - 전처리, 후처리 기능
  - 기관별, 부서별 분기 기능
  - 롤백 기능
  - 중앙 집중 로그
  - ACME 
  - CDN
  - 압축

2. 기능 명세
  a. 공통
  - 로그 기능
  b. 서버
  - DB 처리 기능
  - 일시 중지 기능
  - Admin 기능
  - https 서버 기능
  - 업데이트 확인 응답
  - 업데이트 파일 요청 응답
  - 결과 확인
  - 서버 설정: listen port, 인증서, server_base, 로그 경로, db 계정
  
  c. 클라이언트 
  - https 클라이언트 기능
  - 업데이트 확인 요청
  - 업데이트 파일 요청
  - 업데이트 파일 실행 기능
  - 결과 보고
  - 클라이언트 설정: server_addr list, 인증서, client_base, timeout, report option, 로그 경로
  - 연결 실패, 지연, 중단, 처리

3. 필요 기술
  a. 서버
  - mariadb, golang
  b. admin
  - mariadb, python, django
  b. 클라이언트
  - flutter(fluent_ui)

* django, go 디버깅 방법 확인
* flutter 공부해보자 
  (관리자 권한 실행, progress bar, 텍스트 출력)

nexess_admin / admin12#$