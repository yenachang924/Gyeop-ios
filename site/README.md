# site/ — 공개 웹 자산 (개인정보 처리방침 + App Clip 도메인)

이 폴더 하나가 제출 큐의 두 항목을 동시에 해결한다.

- `privacy.html` — **App Store Connect에 등록할 개인정보 처리방침 URL** (필수)
- `.well-known/apple-app-site-association` — **App Clip 경험 등록용 AASA** (App Clip 필수)
- `index.html` — 최소 랜딩 (없어도 되지만 도메인 루트가 비면 어색하다)
- `_headers` — AASA의 Content-Type을 `application/json`으로 강제 (Netlify·Cloudflare Pages)

## 배포 (택 1)

### 안 A — Cloudflare Pages / Netlify (권장, 무료·즉시)

1. 해당 서비스에서 이 레포를 연결하고 빌드 없이 `site/`를 게시 디렉터리로 지정
2. 배포 후 나오는 도메인(`<이름>.pages.dev` 등)이 곧 서비스 도메인
3. 확인: `https://<도메인>/.well-known/apple-app-site-association` 이 **JSON으로** 열리는지

`_headers`가 Content-Type을 잡아주므로 AASA가 확실히 인식된다. 실도메인을 나중에
사면 같은 프로젝트에 연결만 하면 된다.

### 안 B — GitHub Pages (개인정보 URL만)

Pages는 `_headers`를 지원하지 않아 AASA의 Content-Type을 지정할 수 없다 — 개인정보
처리방침 URL 용도로만 쓰고, App Clip 도메인은 안 A로 가는 게 안전하다.
(`.nojekyll` 파일이 있어야 `.well-known` 같은 점(.)으로 시작하는 경로가 서빙된다.)

### 안 C — 실도메인 구매

`gyeop.app` 등을 사서 안 A의 프로젝트에 커스텀 도메인으로 연결. 브랜딩상 가장 낫지만
도메인 승인·전파에 하루 정도 걸린다.

## 도메인 확정 후 해야 할 일 (코드 쪽)

`App/Support/Gyeop.entitlements` · `AppClip/App/AppClip.entitlements` 의
`PLACEHOLDER.gyeop.example` 를 실도메인으로 교체하고 재빌드한다. (docs/submission-checklist.md C 참고)

## 주의

- AASA의 `M63YMWAA5V` 는 현재 프로젝트의 DEVELOPMENT_TEAM 값이다. 팀이 바뀌면 함께 고친다.
- AASA는 **확장자 없이** `apple-app-site-association` 파일명 그대로여야 한다.
- App Clip의 정식 QR·링크 인보케이션은 App Store 공개 이후에 동작한다 (Apple 정책).
  도메인·AASA는 그 전에 **경험 등록**을 위해 필요하다.
