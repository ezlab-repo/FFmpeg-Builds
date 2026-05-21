# Workflow 점검 (B-0 추가 사전 점검 산출물)

기준일: 2026-05-21
대상 워크플로우: `BtbN/FFmpeg-Builds/.github/workflows/build.yml` (master HEAD `7b5dc8c88b43`, 2026-05-18)

## Secrets 의존

**결과: 없음 (안전)**

`${{ secrets.X }}` 형태의 *사용자 정의 secret* 참조 없음. `${{ github.token }}`만 사용 — 이는 모든 fork에 자동 발급되는 토큰이라 우리 fork에서도 정상 동작.

→ Fork에서 그대로 빌드 가능.

## Docker 이미지 의존

**결과: 안전 (자체 빌드)**

워크플로우는 `container: image: ...` 형태의 *외부 사전 빌드 이미지 pull*에 의존하지 않음. 빌드 시점에 자체적으로 Docker 이미지를 만들고 GHCR에 푸시(`ghcr.io/...`). Fork에서 빌드 시에도 자체 이미지를 만들기 때문에 외부 의존 없음.

## Matrix 구조

현재:
```yaml
target: [win64, winarm64, linux64, linuxarm64]
variant: [gpl, lgpl, gpl 8.1, gpl 7.1, lgpl 8.1, lgpl 7.1,
          gpl-shared, lgpl-shared, gpl-shared 8.1, gpl-shared 7.1,
          lgpl-shared 8.1, lgpl-shared 7.1]
```
→ 4 × 12 = 48 조합 (+ 일부 win64-only 추가).

**우리 좁히기 패치** (Phase C-2 빌드 시간 단축용):
```yaml
target: [win64]
variant: [lgpl-shared]
```
→ 1조합만. 빌드 시간 1~3시간 → 30~60분.

> ⚠️ `build_targets`와 `build_ffmpeg` 두 job 모두 같은 matrix 구조이므로 *동일하게* 수정해야 함.

## 결론

R-1 (workflow secrets 의존): 안전.
R-2 (Docker 이미지 출처·접근권): 안전 (자체 빌드).
→ Phase B-1, B-2 변경 후 push로 빌드 트리거 시 기술적 장애 없음.
