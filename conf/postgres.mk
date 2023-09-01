
# Conda environment should be set

# Main codebase directory
SRC = ~/app/biostar-central

# The django settings module
SETTINGS = biostar.forum.settings

# Postgres specific variables
PGDUMP_FILE ?= biostardb-daily-2023-08-31.gz
PGDUMP_URL ?= www@test.biostars.org:/home/www/data/biostars/${PGDUMP_FILE}
PGDATA_PATH ?= ${SRC}/export/backup/${PGDUMP_FILE}
DATABASE_NAME ?= biostardb

# Customize at command line.
PG_USER ?= test
PG_PASSWD ?= test

# Print usage information
usage:
	@echo "#"
	@echo "# Use the source, Luke!"
	@echo "#"

# Pull latest changes from github.
pull:
	cd ${SRC} && git pull

# Install requirements.
install:
	cd ${SRC} && pip install -r conf/requirements.txt

# Download the latest postgres data dump.
pg_data:
	mkdir -p $(dir ${PGDATA_PATH})
	rsync -avz ${PGDUMP_URL} ${PGDATA_PATH}

# Drops the postgres database.
pg_drop:
	dropdb ${DATABASE_NAME} || true
	dropuser ${PG_USER} || true

# Initialize the postgres database.
pg_init:
	createdb ${DATABASE_NAME} -E utf8 --template template0 -O ${PG_USER}

# Create a postgres user.
pg_role:
	echo "CREATE ROLE ${PG_USER} WITH LOGIN PASSWORD '${PG_PASSWD}';" | psql

# Import the postgres data dump.
pg_import:
	gunzip -c ${PGDATA_PATH} | psql ${DATABASE_NAME} -U ${PG_USER}

pg_reset: pg_drop pg_role pg_init pg_import

# Various make related variables
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -c -u
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables --no-builtin-rules

# Targets that do not correspond to a file.
.PHONY:  usage pg_data pg_drop pg_init pg_role pg_import pg_reset

