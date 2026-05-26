# Disabled Codecs in ezLab FFmpeg Builds

> ezLab의 FFmpeg LGPL 빌드(`win64-lgpl-shared` 변형)에서 비활성화한 코덱·라이브러리 단일 정리본. 옵션 변경 시 이 문서도 동시에 갱신해야 함.
>
> 기준 베이스라인: BtbN ffmpeg-master-latest-win64-lgpl-shared (N-124557-g9e71ea2d60-20260520). `BASELINE_20260521.md` 참조.

## 판단 기준 (어떤 항목을 빼고, 어떤 항목을 유지하나)

**비활성화 대상**: 현재(2026 기준) *활성 특허 풀에 묶인* 코덱·라이브러리. 라이선스 풀이 운영 중이고 *make·use·sell·offer to sell·import* 다섯 행위 중 *sell* 트리거가 실제 위험인 항목.

**유지 대상** (비활성화하지 않음):
- **만료된 특허**: MPEG-4 Part 2 (`mpeg4`, 2024-01-28 만료), AAC LC (`aac`, 미국 만료), MP3, MPEG-2 등
- **Royalty-free 코덱**: Opus, Vorbis, Theora, AV1 (libaom/libdav1d/libsvtav1), VP8/9 (libvpx), FLAC, WebP, JPEG XL, ALAC 등
- **무특허 포맷**: PNG, GIF, BMP, PCM 전체 변형, WAV, MKV 등
- **OS/벤더 라이선스에 위임된 H.264 인코더는 *모두 비활성화*** — `h264_mf` 같은 OS API 위임도 회색지대라 제외 (사용 자체가 ezCapture에서 불필요)
- **자막·필터·도구 라이브러리**: libass, libfreetype, libfribidi, libharfbuzz 등 — 특허 무관, 텍스트 렌더링용

**ezCapture 실제 사용 코덱**(*반드시* 유지):
- 비디오 인코딩: `mpeg4` (만료)
- 오디오 인코딩: `aac` (LC, 미국 만료), `pcm_s16le` (무특허)
- 이미지: `png` (썸네일, 무특허), `gif` (GIF 출력, 무특허)
- 컨테이너: `mp4`, `matroska`, `gif`, `wav` muxer
- 입력: `gdigrab` (Windows GDI), `dshow` (DirectShow) — OS API 래퍼

> 향후 *새 활성 특허 코덱*이 BtbN 본가에 추가될 가능성에 대비해 BASELINE 마크다운을 보관. 회귀 감지는 새 BASELINE을 생성한 후 `diff BASELINE_<기준날짜>.md BASELINE_<새날짜>.md` 형태로 수행.

## 분류 기준

- **Type**: encoder / decoder / parser / bsf / lib (외부 라이브러리)
- **Pool**: 라이선스 풀 또는 특허 보유 단체
- **Disable 위치**: `variants/win64-lgpl-shared.sh` 또는 `scripts.d/50-*.sh`
- **상태**: 활성 / 회색 / 일관성

## 비활성화 항목

### 외부 라이브러리 — 특허 회피용 disable

활성 특허 풀에 묶여 있어 *우리가 추가로 disable*한 라이브러리들. 변형 무관하게 빌드에 포함되지 않도록 `ffbuild_enabled() { return 1 }` 처리.

| Codec | Type | Pool | Disable 위치 | 비고 |
|---|---|---|---|---|
| libopenh264 | lib (enc/dec) | Via Licensing AVC | `scripts.d/50-openh264.sh` | Cisco OpenH264. 활성 특허 |
| libopencore-amrnb/amrwb | lib (dec) | VoiceAge AMR | `scripts.d/50-opencore-amr.sh` | AMR 음성. 활성 |
| libvvenc | lib (enc) | VVC (Velos/MPEG LA) | `scripts.d/50-vvenc.sh` | VVC 인코더. 활성 |
| libuavs3d | lib (dec) | AVS3 (중국 표준) | `scripts.d/50-uavs3d.sh` | AVS3 디코더. 특허 |
| libkvazaar | lib (enc) | MPEG LA HEVC | `scripts.d/50-kvazaar.sh` | **HEVC sw 인코더**. 활성 특허 |
| liboapv | lib (dec) | Samsung APV | `scripts.d/50-openapv.sh` | 신규 표준. 특허 검토 미완 → 보수적 disable |
| liblcevc-dec | lib (dec) | V-Nova LCEVC | `scripts.d/50-lcevcdec.sh` | LCEVC 디코더. 활성 특허 |

### 외부 라이브러리 — cache step robustness용 unconditional disable

BtbN 본가 로직상 *lgpl variant에서는 자동으로 disable*되는 라이브러리들. 즉 *최종 빌드 산출물에는 어차피 들어가지 않음*. 그런데 BtbN의 `Update Cache` step은 VARIANT 환경변수 없이 호출되어 fallback `return 0`이 적용 → variant 무시하고 모든 라이브러리 소스를 다운로드. 외부 서버 장애 시 빌드 실패 위험.

→ 의미상 *우리 빌드에 안 들어가는* 라이브러리들이므로 `ffbuild_enabled() { return 1 }`로 unconditional disable. 외부 서버 의존성을 줄여 빌드 환경 robustness 확보.

| Codec | Type | BtbN 본가 lgpl 동작 | Disable 위치 | 비고 |
|---|---|---|---|---|
| libx264 | lib (enc) | 자동 disable (GPL) | `scripts.d/50-x264.sh` | code.videolan.org git |
| libx265 | lib (enc) | 자동 disable (GPL) | `scripts.d/50-x265.sh` | bitbucket.org git |
| libxvid | lib (enc) | 자동 disable | `scripts.d/50-xvid.sh` | svn.xvid.org SVN — *서버 불안정 확인됨 (502)* |
| libdavs2 | lib (dec) | 자동 disable | `scripts.d/50-davs2.sh` | github.com/pkuvcl/davs2 |
| libxavs2 | lib (enc) | 자동 disable | `scripts.d/50-xavs2.sh` | github.com/pkuvcl/xavs2 |
| libfdk-aac | lib (enc) | 자동 disable (nonfree 전용) | `scripts.d/50-fdk-aac.sh` | github.com/mstorsjo/fdk-aac |

### HEVC / H.265 패밀리 (Access Advance + MPEG LA HEVC + Velos)

| Codec | Type | Disable 위치 |
|---|---|---|
| hevc | decoder | `variants/win64-lgpl-shared.sh` |
| hevc_qsv | decoder/encoder | `variants/win64-lgpl-shared.sh` |
| hevc_cuvid | decoder | `variants/win64-lgpl-shared.sh` |
| hevc_amf | encoder/decoder | `variants/win64-lgpl-shared.sh` |
| hevc_nvenc | encoder | `variants/win64-lgpl-shared.sh` |
| hevc_mf | encoder | `variants/win64-lgpl-shared.sh` |
| hevc_d3d12va | encoder | `variants/win64-lgpl-shared.sh` |
| hevc_vaapi | encoder | `variants/win64-lgpl-shared.sh` |
| hevc_vulkan | encoder | `variants/win64-lgpl-shared.sh` |
| hevc (parser) | parser | `variants/win64-lgpl-shared.sh` |
| hevc_metadata | bsf | `variants/win64-lgpl-shared.sh` |

> `hevc_mp4toannexb` bsf는 disable 제외 (보수적 — 의존성 명확치 않음). HEVC 디코더·인코더 자체가 disable되어 있어 *실제로는 호출되지 않음*.

### H.264 / AVC 패밀리 (Via Licensing AVC)

| Codec | Type | Disable 위치 |
|---|---|---|
| h264 | decoder | `variants/win64-lgpl-shared.sh` |
| h264_qsv | decoder/encoder | `variants/win64-lgpl-shared.sh` |
| h264_cuvid | decoder | `variants/win64-lgpl-shared.sh` |
| h264_amf | encoder/decoder | `variants/win64-lgpl-shared.sh` |
| h264_nvenc | encoder | `variants/win64-lgpl-shared.sh` |
| h264_mf | encoder | `variants/win64-lgpl-shared.sh` |
| h264_d3d12va | encoder | `variants/win64-lgpl-shared.sh` |
| h264_vaapi | encoder | `variants/win64-lgpl-shared.sh` |
| h264_vulkan | encoder | `variants/win64-lgpl-shared.sh` |
| h264 (parser) | parser | `variants/win64-lgpl-shared.sh` |
| h264_metadata | bsf | `variants/win64-lgpl-shared.sh` |
| h264_redundant_pps | bsf | `variants/win64-lgpl-shared.sh` |

> `h264_mp4toannexb` bsf는 disable 제외 (위와 같은 이유).

### VVC / H.266 패밀리 (최신 표준, 활성 특허)

| Codec | Type | Disable 위치 |
|---|---|---|
| vvc | decoder | `variants/win64-lgpl-shared.sh` |
| vvc_qsv | decoder | `variants/win64-lgpl-shared.sh` |
| vvc (parser) | parser | `variants/win64-lgpl-shared.sh` |
| vvc_metadata | bsf | `variants/win64-lgpl-shared.sh` |

> `vvc_mp4toannexb` bsf는 disable 제외 (보수적).

### VC-1 + WMV9 패밀리 (MPEG LA VC-1)

| Codec | Type | Disable 위치 | 비고 |
|---|---|---|---|
| vc1 | decoder | `variants/win64-lgpl-shared.sh` | |
| vc1_qsv | decoder | `variants/win64-lgpl-shared.sh` | |
| vc1_cuvid | decoder | `variants/win64-lgpl-shared.sh` | |
| vc1image | decoder | `variants/win64-lgpl-shared.sh` | |
| wmv3 | decoder | `variants/win64-lgpl-shared.sh` | WMV3 = WMV9 = VC-1 Simple/Main |
| wmv3image | decoder | `variants/win64-lgpl-shared.sh` | |
| vc1 (parser) | parser | `variants/win64-lgpl-shared.sh` | |

### Dolby 패밀리 (AC-3, EAC-3, TrueHD, Vision)

| Codec | Type | Disable 위치 |
|---|---|---|
| ac3, ac3_fixed, ac3_mf | encoder | `variants/win64-lgpl-shared.sh` |
| eac3 | encoder | `variants/win64-lgpl-shared.sh` |
| truehd | encoder | `variants/win64-lgpl-shared.sh` |
| ac3, ac3_fixed | decoder | `variants/win64-lgpl-shared.sh` |
| eac3 | decoder | `variants/win64-lgpl-shared.sh` |
| truehd | decoder | `variants/win64-lgpl-shared.sh` |
| dolby_e | decoder | `variants/win64-lgpl-shared.sh` |
| eac3_core | bsf | `variants/win64-lgpl-shared.sh` |
| dovi_rpu | bsf | `variants/win64-lgpl-shared.sh` |

> `ac3` parser는 disable 제외. mov_muxer가 select 의존성으로 `ac3_parser`를 요구 — disable하면 mp4/mov/ipod muxer 통째로 자동 disable됨. AC-3 encoder/decoder 자체는 disable이라 *실제 호출 안 됨*.

### DTS 패밀리 (Xperi)

| Codec | Type | Disable 위치 |
|---|---|---|
| dca | encoder/decoder | `variants/win64-lgpl-shared.sh` |
| dca (parser) | parser | `variants/win64-lgpl-shared.sh` |

### Qualcomm aptX (일관성)

| Codec | Type | Disable 위치 |
|---|---|---|
| aptx, aptx_hd | encoder/decoder | `variants/win64-lgpl-shared.sh` |

### Sony ATRAC (일관성)

| Codec | Type | Disable 위치 |
|---|---|---|
| atrac1, atrac3, atrac3al, atrac9 | decoder | `variants/win64-lgpl-shared.sh` |
| atrac3p, atrac3pal | decoder | `variants/win64-lgpl-shared.sh` |

> ATRAC3+ / ATRAC3+ AL의 disable 옵션엔 *symbol-derived 이름* (`atrac3p`, `atrac3pal`)을 사용. `ffmpeg -decoders` 출력에 보이는 long name(`atrac3plus`, `atrac3plusal`)을 그대로 쓰면 configure가 *unknown name으로 silently 무시*하므로 주의.

### Microsoft WMA (일관성)

| Codec | Type | Disable 위치 |
|---|---|---|
| wmav1, wmav2 | encoder | `variants/win64-lgpl-shared.sh` |
| wmav1, wmav2, wmapro, wmalossless, wmavoice | decoder | `variants/win64-lgpl-shared.sh` |

### Apple ProRes (회색지대 — 비인증 구현)

Apple은 ProRes 사용에 *공식 인증 프로그램* (`ProRes@apple.com`) 운영. FFmpeg의 ProRes 구현은 *비인증*이라 Apple이 *법적 회색지대*로 분류. ezCapture 사용 안 함 + 우리 정책(잠재 위험 + 사용 안 함 = disable)에 따라 제외.

| Codec | Type | Disable 위치 |
|---|---|---|
| prores | encoder | `variants/win64-lgpl-shared.sh` |
| prores_aw | encoder | `variants/win64-lgpl-shared.sh` |
| prores_ks | encoder | `variants/win64-lgpl-shared.sh` |
| prores_ks_vulkan | encoder | `variants/win64-lgpl-shared.sh` |
| prores | decoder | `variants/win64-lgpl-shared.sh` |
| prores_raw | decoder | `variants/win64-lgpl-shared.sh` |

## BtbN buildconf에서 disable 표시되는 것 (우리 빌드 산출물 불포함)

`libdavs2`, `libxavs2`, `libx264`, `libx265`, `libxvid`, `libfdk-aac` — BtbN 본가 로직으로 lgpl variant에선 자동 disable. 우리도 *cache step robustness*용으로 추가 unconditional disable 처리 완료 (위 표 참조).

## 회귀 감지

`BASELINE_<날짜>.md`(통합 단일 파일)가 fork 레포 루트에 보관됨. 향후 BtbN 업스트림 변경 시 새 BASELINE을 생성하여 기존 BASELINE과 `diff`로 비교 — 신규 활성 특허 코덱·라이브러리 발견 시 본 문서에 추가.
