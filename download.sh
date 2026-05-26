#!/bin/bash
set -xe
cd "$(dirname "$0")"
source util/vars.sh dl only

if docker info -f "{{println .SecurityOptions}}" | grep rootless >/dev/null 2>&1; then
    UIDARGS=()
else
    UIDARGS=( -u "$(id -u):$(id -g)" )
fi

[[ -t 1 ]] && TTY_ARG="-t" || TTY_ARG=""

DL_SCRIPT_DIR="$(mktemp -d)"
trap "rm -rf -- '$DL_SCRIPT_DIR'" EXIT

mkdir -p "${PWD}"/.cache/downloads

for STAGE in scripts.d/*.sh scripts.d/*/*.sh; do
	STAGENAME="$(basename "$STAGE" | sed 's/.sh$//')"

	cat <<-EOF >"${DL_SCRIPT_DIR}/${STAGENAME}.sh"
		set -xe -o pipefail
		shopt -s dotglob

		source /dl_functions.sh
		source "/$STAGE"

		# ezLab: respect ffbuild_enabled in cache step (otherwise download.sh ignores it)
		ffbuild_enabled || exit 0

		STG="\$(ffbuild_dockerdl)"

		if [[ -z "\$STG" ]]; then
			exit 0
		fi

		DLHASH="\$(sha256sum <<<"\$STG" | cut -d" " -f1)"
		DLNAME="$STAGENAME"

		if [[ "$1" == "hashonly" ]]; then
			echo "\$DLHASH"
			exit 0
		fi

		TGT="/dldir/\${DLNAME}_\${DLHASH}.tar.xz"
		if [[ -f "\$TGT" ]]; then
			rm -f "/dldir/\${DLNAME}.tar.xz"
			ln -s "\${DLNAME}_\${DLHASH}.tar.xz" "/dldir/\${DLNAME}.tar.xz"
			exit 0
		fi

		WORKDIR="\$(mktemp -d)"
		trap "rm -rf -- '\$WORKDIR'" EXIT
		cd "\$WORKDIR"

		eval "set -e; \$STG"

		tar cpJf "\$TGT.tmp" .
		mv "\$TGT.tmp" "\$TGT"
		rm -f "/dldir/\${DLNAME}.tar.xz"
		ln -s "\${DLNAME}_\${DLHASH}.tar.xz" "/dldir/\${DLNAME}.tar.xz"
	EOF
done

# ezLab: explicitly pass build context env vars into the cache container.
# Without these, ffbuild_enabled branches like '[[ $TARGET == win* ]] || return -1'
# or '[[ $VARIANT == lgpl* ]] && return -1' evaluate against empty values and
# skip libraries we actually need (e.g. 10-mingw, 47-vulkan). Hardcoded for our
# single target/variant combo.
docker run -i $TTY_ARG --rm "${UIDARGS[@]}" \
	-e TARGET=win64 \
	-e VARIANT=lgpl-shared \
	-e ADDINS_STR="" \
	-v "${DL_SCRIPT_DIR}":/stages -v "${PWD}/.cache/downloads":/dldir -v "${PWD}/scripts.d":/scripts.d -v "${PWD}/util/dl_functions.sh":/dl_functions.sh "${REGISTRY}/${REPO}/base:latest" \
	bash -c 'set -xe && for STAGE in /stages/*.sh; do bash $STAGE; done'
