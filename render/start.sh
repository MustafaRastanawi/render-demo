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
until mysqladmin ping --silent; do
  sleep 2
done

echo "Preparing database..."

# Use socket auth for root. Do NOT use -h127.0.0.1 for root on Debian/MariaDB.
mysql -uroot <<SQL
CREATE DATABASE IF NOT EXISTS beaver_contest CHARACTER SET utf8 COLLATE utf8_general_ci;

CREATE USER IF NOT EXISTS 'bebras'@'localhost' IDENTIFIED BY 'bebras';
CREATE USER IF NOT EXISTS 'bebras'@'127.0.0.1' IDENTIFIED BY 'bebras';

GRANT ALL PRIVILEGES ON beaver_contest.* TO 'bebras'@'localhost';
GRANT ALL PRIVILEGES ON beaver_contest.* TO 'bebras'@'127.0.0.1';

FLUSH PRIVILEGES;
SQL

echo "Checking database tables..."
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

echo "Ensuring demo admin users exist..."
mysql -ubebras -pbebras -h127.0.0.1 beaver_contest <<'SQL'
SET @demo_email = 'demo.teacher@example.com';
SET @demo_password = 'Demo123456';
SET @demo_salt = MD5(CONCAT('render-demo-', @demo_email));
SET @demo_password_md5 = MD5(CONCAT(@demo_password, @demo_salt));

UPDATE `user`
SET `gender` = 'M',
    `firstName` = 'Demo',
    `lastName` = 'Teacher',
    `isOwnOfficialEmail` = 1,
    `officialEmail` = @demo_email,
    `officialEmailValidated` = 1,
    `alternativeEmail` = @demo_email,
    `alternativeEmailValidated` = 1,
    `salt` = @demo_salt,
    `passwordMd5` = @demo_password_md5,
    `recoverCode` = '',
    `validated` = 1,
    `allowMultipleSchools` = 1,
    `isAdmin` = 1,
    `comment` = '',
    `saniValid` = 1,
    `orig_firstName` = 'Demo',
    `orig_lastName` = 'Teacher',
    `iVersion` = 0
WHERE `officialEmail` = @demo_email OR `alternativeEmail` = @demo_email;

SET @demo_user_id = (
  SELECT `ID`
  FROM `user`
  WHERE `officialEmail` = @demo_email OR `alternativeEmail` = @demo_email
  LIMIT 1
);
SET @new_demo_user_id = (
  SELECT GREATEST(COALESCE(MAX(`ID`), 900000000000000000) + 1, 900000000000000001)
  FROM `user`
);

INSERT INTO `user` (
  `ID`,
  `gender`,
  `firstName`,
  `lastName`,
  `isOwnOfficialEmail`,
  `officialEmail`,
  `officialEmailValidated`,
  `alternativeEmail`,
  `alternativeEmailValidated`,
  `salt`,
  `passwordMd5`,
  `recoverCode`,
  `validated`,
  `allowMultipleSchools`,
  `isAdmin`,
  `registrationDate`,
  `lastLoginDate`,
  `awardPrintingDate`,
  `comment`,
  `saniValid`,
  `orig_firstName`,
  `orig_lastName`,
  `iVersion`
)
SELECT
  @new_demo_user_id,
  'M',
  'Demo',
  'Teacher',
  1,
  @demo_email,
  1,
  @demo_email,
  1,
  @demo_salt,
  @demo_password_md5,
  '',
  1,
  1,
  1,
  NOW(),
  NOW(),
  NULL,
  '',
  1,
  'Demo',
  'Teacher',
  0
WHERE @demo_user_id IS NULL;

UPDATE `user`
SET `validated` = 1,
    `officialEmailValidated` = 1,
    `alternativeEmailValidated` = 1,
    `isAdmin` = 1
WHERE `officialEmail` = 'mularas78@gmail.com';
SQL

echo "Checking sample student group yft7zkqt..."
SAMPLE_GROUP_ROW=$(mysql -ubebras -pbebras -h127.0.0.1 beaver_contest -N -e "SELECT CONCAT_WS(' | ', ID, name, contestID, code, password, isPublic) FROM \`group\` WHERE code = 'yft7zkqt' LIMIT 1;" || true)

if [ -z "$SAMPLE_GROUP_ROW" ]; then
  echo "Sample student group yft7zkqt is missing; trying to add it for contest 56."
  mysql -ubebras -pbebras -h127.0.0.1 beaver_contest <<'SQL'
SET @sample_group_code = 'yft7zkqt';
SET @sample_group_password = 'zfvaxswk';
SET @sample_group_id = (
  SELECT `ID`
  FROM `group`
  WHERE `code` = @sample_group_code
  LIMIT 1
);
SET @sample_group_password_id = (
  SELECT `ID`
  FROM `group`
  WHERE `password` = @sample_group_password
  LIMIT 1
);
SET @new_sample_group_id = (
  SELECT CASE
    WHEN COUNT(*) = 0 THEN 796142003655934888
    WHEN SUM(`ID` = 796142003655934888) = 0 THEN 796142003655934888
    ELSE GREATEST(MAX(`ID`) + 1, 900000000000000002)
  END
  FROM `group`
);

INSERT INTO `group` (
  `ID`,
  `schoolID`,
  `grade`,
  `gradeDetail`,
  `userID`,
  `name`,
  `nbStudents`,
  `nbTeamsEffective`,
  `nbStudentsEffective`,
  `contestID`,
  `minCategory`,
  `maxCategory`,
  `language`,
  `parentGroupID`,
  `code`,
  `password`,
  `expectedStartTime`,
  `startTime`,
  `noticePrinted`,
  `isPublic`,
  `isGenerated`,
  `bRecovered`,
  `participationType`,
  `iVersion`
)
SELECT
  @new_sample_group_id,
  1358,
  12,
  '',
  1201,
  'Castor 2015 : tous les niveaux',
  100000,
  0,
  0,
  56,
  '',
  '',
  '',
  NULL,
  @sample_group_code,
  @sample_group_password,
  '2015-12-10 22:00:00',
  NOW(),
  0,
  1,
  0,
  0,
  'Unofficial',
  0
WHERE @sample_group_id IS NULL
  AND @sample_group_password_id IS NULL
  AND EXISTS (SELECT 1 FROM `contest` WHERE `ID` = 56);
SQL
  SAMPLE_GROUP_ROW=$(mysql -ubebras -pbebras -h127.0.0.1 beaver_contest -N -e "SELECT CONCAT_WS(' | ', ID, name, contestID, code, password, isPublic) FROM \`group\` WHERE code = 'yft7zkqt' LIMIT 1;" || true)
fi

if [ -n "$SAMPLE_GROUP_ROW" ]; then
  echo "Sample student group: $SAMPLE_GROUP_ROW"
else
  echo "Sample student group yft7zkqt is missing; contest 56 may not be available after import."
fi

echo "Sample student group query result:"
mysql -ubebras -pbebras -h127.0.0.1 beaver_contest -e "SELECT ID, name, contestID, code, password, isPublic FROM \`group\` WHERE code = 'yft7zkqt';" || echo "Sample student group query failed."

echo "Configuring Apache for Render PORT..."
PORT="${PORT:-10000}"

sed -i "s/^Listen .*/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:.*/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf

echo "Starting Apache on port ${PORT}..."
apache2-foreground
