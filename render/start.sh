#!/usr/bin/env bash
set -e

echo "Starting MariaDB..."

mkdir -p /var/run/mysqld /var/lib/mysql
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initializing MariaDB data directory..."
  mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

mysqld_safe --datadir=/var/lib/mysql --bind-address=127.0.0.1 &

echo "Waiting for MariaDB..."
until mysqladmin ping -h127.0.0.1 --silent; do
  sleep 2
done

echo "Preparing database..."
mysql -uroot -h127.0.0.1 <<SQL
CREATE DATABASE IF NOT EXISTS beaver_contest CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER IF NOT EXISTS 'bebras'@'localhost' IDENTIFIED BY 'bebras';
GRANT ALL PRIVILEGES ON beaver_contest.* TO 'bebras'@'localhost';
FLUSH PRIVILEGES;
SQL

TABLE_COUNT=$(mysql -ubebras -pbebras -h127.0.0.1 beaver_contest -N -e "SHOW TABLES;" | wc -l)

if [ "$TABLE_COUNT" -eq "0" ]; then
  echo "Fresh DB detected. Importing Bebras schema..."

  sed -i '/KEY `awarded` (`awarded`)/d' dbv_data/revisions/423/database_structure.sql || true
  sed -i 's/KEY `nbOfficialContestants` (`nbOfficialContestants`),/KEY `nbOfficialContestants` (`nbOfficialContestants`)/' dbv_data/revisions/423/database_structure.sql || true

  mysql -ubebras -pbebras -h127.0.0.1 beaver_contest < dbv_data/revisions/423/database_structure.sql

  for file in $(find dbv_data/revisions -type f -name "*.sql" | sort -V); do
    rev=$(echo "$file" | cut -d/ -f3)
    if [ "$rev" -gt 423 ]; then
      echo "Applying $file"
      mysql -ubebras -pbebras -h127.0.0.1 beaver_contest < "$file" || true
    fi
  done

  sed -i 's/(796142003655934888, 1358, 12,.*261357)$/&;/' sampleDatabase/database_content.sql || true
  sed -i "s/WHERE ID = 796142003655934888$/WHERE ID = 796142003655934888;/" sampleDatabase/database_content.sql || true

  echo "Importing sample database..."
  ( echo "SET SESSION sql_mode='NO_ENGINE_SUBSTITUTION';"; cat sampleDatabase/database_content.sql ) | \
    mysql -ubebras -pbebras -h127.0.0.1 beaver_contest || true
fi

echo "Configuring Apache for Render PORT..."
PORT="${PORT:-10000}"

sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf

echo "Starting Apache..."
apache2-foreground
