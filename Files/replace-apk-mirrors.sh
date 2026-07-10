#!/bin/sh

REPOSITORIES="$1"
USTC_PREFIX="https://mirrors.ustc.edu.cn/immortalwrt"
OFFICIAL_PREFIX="https://downloads.immortalwrt.org"

[ -f "$REPOSITORIES" ] || exit 0

TMP="${REPOSITORIES}.tmp"
: > "$TMP" || exit 1

while IFS= read -r repository || [ -n "$repository" ]; do
	case "$repository" in
		"$OFFICIAL_PREFIX"/*)
			candidate="$USTC_PREFIX/${repository#"$OFFICIAL_PREFIX"/}"
			if curl -fsSL --retry 1 --connect-timeout 5 --max-time 15 \
				-o /dev/null "$candidate"; then
				echo "$candidate" >> "$TMP"
				echo "APK mirror available: $candidate"
			else
				echo "$repository" >> "$TMP"
				echo "APK mirror unavailable, keep official: $repository"
			fi
			;;
		*) echo "$repository" >> "$TMP" ;;
	esac
done < "$REPOSITORIES"

mv "$TMP" "$REPOSITORIES"
