#!/bin/sh
# Backup harian: dump database + arsip file upload ke ./backups (di host).
# PENTING: salin folder backups/ ke luar VPS secara berkala (mis. rclone ke
# Google Drive) — backup di server yang sama tidak menolong bila VPS rusak.
set -eu

KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"

backup_once() {
	stamp="$(date +%Y%m%d-%H%M%S)"
	db_file="/backups/db-${stamp}.sql.gz"
	files_file="/backups/uploads-${stamp}.tar.gz"

	echo "[backup] ${stamp}: dump database"
	pg_dump --no-owner --no-privileges | gzip > "${db_file}.tmp"
	mv "${db_file}.tmp" "${db_file}"

	echo "[backup] ${stamp}: arsip uploads"
	tar -czf "${files_file}.tmp" -C /uploads .
	mv "${files_file}.tmp" "${files_file}"

	echo "[backup] hapus backup lebih dari ${KEEP_DAYS} hari"
	find /backups -name '*.gz' -mtime "+${KEEP_DAYS}" -delete
}

while true; do
	if ! backup_once; then
		echo "[backup] GAGAL — coba lagi dalam 1 jam" >&2
		sleep 3600
		continue
	fi
	sleep 86400
done
