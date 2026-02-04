#!/bin/bash
set -u

ftpminidump="$(dirname $0)/ftpminidump"
dotenv="$(dirname $0)/.env"
[ -f "$dotenv" ] || { 
    cat <<EOF > .env
shadps4="" # the shadPS4 (CLI) executable
ps4_mount="" # path to mount the PS4 FTP server to
ftpminidump_root="" # path to dump game metadata to
merged_mount="" # working directory for overlayfs
ps4_ip="" # "ip:port" format
EOF
    echo "Please set your enviroment variables.";
    exit 1;
}
. $dotenv

: "${shadps4:?shadps4 not set}"
: "${ps4_mount:?ps4_mount not set}"
: "${merged_mount:?merged_mount not set}"
: "${ps4_ip:?ps4_ip not set}"

unmount_if_needed() {
    mount | grep -q "on $1 " && echo "Unmounting $1" && umount "$1"
}

if [ "${1:-}" == "-c" ]; then
    unmount_if_needed $merged_mount
    unmount_if_needed $ps4_mount
    exit 0
fi

command -v fuse-overlayfs >/dev/null || {
    echo "fuse-overlayfs not found"
    exit 1
}

[ -x "$shadps4" ] || { echo "shadPS4 not found"; exit 1; }
[ -f "$ftpminidump" ] || { echo "ftpminidump not found"; exit 1; }
[ -d "$ps4_mount/mnt/sandbox" ] || {
    echo "PS4 mount not found or not mounted, attempting to mount...";
    command -v curlftpfs >/dev/null 2>&1 || {
        echo "curlftpfs not found in PATH"
        exit 1
    };
    unmount_if_needed $merged_mount;
    unmount_if_needed $ps4_mount; # free stuck mounts after a PS4 crash
    curlftpfs $ps4_ip $ps4_mount || {
        echo "curlftpfs failed";
        exit 1;
    }
}
if ! find "$ps4_mount/mnt/sandbox/pfsmnt" -mindepth 1 -maxdepth 1 -type d | grep -q .; then
    echo "No game running"
    exit 1
fi

gameid=$(
    find "$ps4_mount/mnt/sandbox/pfsmnt" \
        -mindepth 1 -maxdepth 1 -type d \
        -printf '%f\n' | head -n1 | cut -d- -f1
)

[ -n "$gameid" ] || {
    echo "Failed to detect game ID"
    exit 1
}

app_dir="$ftpminidump_root/${gameid}"
ps4_app_dir="$ps4_mount/mnt/sandbox/pfsmnt/${gameid}-app0"
ps4_patch_dir="$ps4_mount/mnt/sandbox/pfsmnt/${gameid}-patch0"

mounted_sfo="$merged_mount/sce_sys/param.sfo"
dump_sfo="$app_dir/sce_sys/param.sfo"
if [ "${1:-}" != "-b" ] && [ -d "$app_dir-patch" ]; then
    dump_sfo="$app_dir-patch/sce_sys/param.sfo"
else
    dump_sfo="$app_dir/sce_sys/param.sfo"
fi

mounted_hash=""
expected_hash=""
[ -f "$mounted_sfo" ] && 
    mounted_hash=$(sha1sum "$mounted_sfo" | cut -d' ' -f1)
[ -f "$dump_sfo" ] && 
    expected_hash=$(sha1sum "$dump_sfo" | cut -d' ' -f1)

if [ ! -d "$app_dir" ]; then
    echo "Dumping metadata for $gameid"
    bash "$ftpminidump" "$ps4_ip" -o "$ftpminidump_root"
fi

[ -d "$ps4_app_dir" ] || {
    echo "PS4 app directory not found: $ps4_app_dir"
    exit 1
}

need_remount=0
if ! mount | grep -q "on $merged_mount "; then
    echo "Overlay not mounted"
    need_remount=1
elif [ "$mounted_hash" != "$expected_hash" ]; then
    echo "Overlay contains a different game, remounting"
    need_remount=1
fi

if [ "$need_remount" -eq 1 ]; then
    unmount_if_needed $merged_mount

    echo "Mounting overlay for $gameid"
    if [ "${1:-}" != "-b" ] && [ -d "$app_dir-patch" ]; then
        fuse-overlayfs \
            -o lowerdir="$app_dir-patch:$app_dir:$ps4_patch_dir:$ps4_app_dir" \
            "$merged_mount"
    else
        fuse-overlayfs \
            -o lowerdir="$app_dir:$ps4_app_dir" \
            "$merged_mount"
    fi
fi

exec "$shadps4" "$merged_mount"
