#!/bin/bash
source "$(dirname "$BASH_SOURCE")"/windows-install-shared.sh
source "$(dirname "$BASH_SOURCE")"/defaults-lgpl-shared.sh

# === ezLab 커스텀: 특허 노출 코덱 비활성화 ===
# 검증 기준: BtbN ffmpeg-master-latest-win64-lgpl-shared (N-124557-g9e71ea2d60-20260520)
# 자세한 내용은 fork 레포 루트의 DISABLED_CODECS.md 참고

# ezCapture는 MP4 출력 사용 — 명시적 enable로 의존성 누락 회피
FF_CONFIGURE+=" --enable-muxer=mp4,mov,ipod"

# HEVC 전체 제거 (Access Advance HEVC + MPEG LA HEVC + Velos)
FF_CONFIGURE+=" --disable-decoder=hevc,hevc_qsv,hevc_cuvid,hevc_amf"
FF_CONFIGURE+=" --disable-encoder=hevc_amf,hevc_qsv,hevc_nvenc,hevc_mf,hevc_d3d12va,hevc_vaapi,hevc_vulkan"
FF_CONFIGURE+=" --disable-parser=hevc"
FF_CONFIGURE+=" --disable-bsf=hevc_metadata"  # hevc_mp4toannexb는 보수적으로 제외 (HEVC 코덱 자체가 disable이라 호출 안 됨)

# H.264 전체 제거 (Via Licensing AVC) — libopenh264는 scripts.d/50-openh264.sh에서 별도 disable
FF_CONFIGURE+=" --disable-decoder=h264,h264_qsv,h264_cuvid,h264_amf"
FF_CONFIGURE+=" --disable-encoder=h264_amf,h264_qsv,h264_nvenc,h264_mf,h264_d3d12va,h264_vaapi,h264_vulkan"
FF_CONFIGURE+=" --disable-parser=h264"
FF_CONFIGURE+=" --disable-bsf=h264_metadata,h264_redundant_pps"  # h264_mp4toannexb는 보수적으로 제외 (H.264 코덱 자체가 disable이라 호출 안 됨)

# VVC (H.266) 제거 — 최신 표준, 활성 특허
FF_CONFIGURE+=" --disable-decoder=vvc,vvc_qsv"
FF_CONFIGURE+=" --disable-parser=vvc"
FF_CONFIGURE+=" --disable-bsf=vvc_metadata"  # vvc_mp4toannexb는 보수적으로 제외 (VVC 코덱 자체가 disable이라 호출 안 됨)

# VC-1 + WMV9 패밀리 제거 (MPEG LA VC-1)
# WMV3 = WMV9 = VC-1 Simple/Main Profile (같은 풀)
FF_CONFIGURE+=" --disable-decoder=vc1,vc1_qsv,vc1_cuvid,vc1image,wmv3,wmv3image"
FF_CONFIGURE+=" --disable-parser=vc1"

# Dolby (AC-3, EAC-3, TrueHD, Vision) 제거
# 주의: ac3 parser는 mov_muxer select 의존성 — disable하면 mp4/mov/ipod muxer 통째로 사라짐. parser는 dormant 유지.
FF_CONFIGURE+=" --disable-encoder=ac3,ac3_fixed,ac3_mf,eac3,truehd"
FF_CONFIGURE+=" --disable-decoder=ac3,ac3_fixed,eac3,truehd,dolby_e"
FF_CONFIGURE+=" --disable-bsf=eac3_core,dovi_rpu"

# DTS (Xperi) 제거
FF_CONFIGURE+=" --disable-encoder=dca"
FF_CONFIGURE+=" --disable-decoder=dca"
FF_CONFIGURE+=" --disable-parser=dca"

# Qualcomm aptX 제거
FF_CONFIGURE+=" --disable-encoder=aptx,aptx_hd"
FF_CONFIGURE+=" --disable-decoder=aptx,aptx_hd"

# Sony ATRAC 패밀리 제거
# configure는 symbol-derived 이름(atrac3p, atrac3pal)을 받음. -decoders 출력의 long name(atrac3plus, atrac3plusal)은 unknown으로 silently 무시되니 주의.
FF_CONFIGURE+=" --disable-decoder=atrac1,atrac3,atrac3al,atrac9,atrac3p,atrac3pal"

# Microsoft WMA 패밀리 제거 (일관성)
FF_CONFIGURE+=" --disable-encoder=wmav1,wmav2"
FF_CONFIGURE+=" --disable-decoder=wmav1,wmav2,wmapro,wmalossless,wmavoice"

# Apple ProRes 제거 (Apple 비인증 구현, ezCapture 사용 안 함)
FF_CONFIGURE+=" --disable-encoder=prores,prores_aw,prores_ks,prores_ks_vulkan"
FF_CONFIGURE+=" --disable-decoder=prores,prores_raw"
