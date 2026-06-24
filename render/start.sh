#!/usr/bin/env bash
set -e

PORT="${PORT:-10000}"

resolve_public_origin() {
  if [ -n "${APP_PUBLIC_BASE_URL:-}" ]; then
    printf '%s' "$APP_PUBLIC_BASE_URL"
    return 0
  fi

  if [ -n "${RENDER_EXTERNAL_URL:-}" ]; then
    printf '%s' "$RENDER_EXTERNAL_URL"
    return 0
  fi

  if [ -n "${RENDER_EXTERNAL_HOSTNAME:-}" ]; then
    local render_hostname="${RENDER_EXTERNAL_HOSTNAME#https://}"
    render_hostname="${render_hostname#http://}"
    printf 'https://%s' "$render_hostname"
    return 0
  fi

  echo "Missing APP_PUBLIC_BASE_URL, RENDER_EXTERNAL_URL, or RENDER_EXTERNAL_HOSTNAME." >&2
  return 1
}

validate_public_origin() {
  local raw_origin="$1"

  php -r '
$origin = trim($argv[1] ?? "");
$fail = function($message) {
    fwrite(STDERR, "Unsafe production public origin: " . $message . PHP_EOL);
    exit(1);
};
$parts = parse_url($origin);
if ($origin === "" || $parts === false) {
    $fail("missing or invalid URL");
}
$scheme = strtolower($parts["scheme"] ?? "");
$host = $parts["host"] ?? "";
$hostForCheck = strtolower(trim($host, "[]"));
$path = $parts["path"] ?? "";
if ($scheme !== "https") {
    $fail("URL must use https");
}
if ($host === "") {
    $fail("URL must include a host");
}
if ($path !== "" && $path !== "/") {
    $fail("URL must not include a path");
}
foreach (array("query", "fragment", "user", "pass") as $partName) {
    if (isset($parts[$partName])) {
        $fail("URL must not include " . $partName);
    }
}
$blockedHosts = array("localhost", "127.0.0.1", "0.0.0.0", "::1");
if (in_array($hostForCheck, $blockedHosts, true) || substr($hostForCheck, -10) === ".localhost") {
    $fail("URL must not point to a local host");
}
$port = isset($parts["port"]) ? ":" . $parts["port"] : "";
echo "https://" . $host . $port;
' "$raw_origin"
}

PUBLIC_ORIGIN="$(validate_public_origin "$(resolve_public_origin)")"
export APP_PUBLIC_BASE_URL="$PUBLIC_ORIGIN"
PUBLIC_HOST="$(php -r '$parts = parse_url($argv[1]); echo $parts["host"] ?? "localhost";' "$PUBLIC_ORIGIN")"

echo "Using public origin ${PUBLIC_ORIGIN}"
echo "Configuring Apache for Render PORT..."
sed -i "s/^Listen .*/Listen 0.0.0.0:${PORT}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:.*/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf
printf 'ServerName %s\nUseCanonicalName Off\nUseCanonicalPhysicalPort Off\n' "$PUBLIC_HOST" > /etc/apache2/conf-available/render-public-origin.conf
a2enconf render-public-origin >/dev/null

normalize_demo_contest_assets() {
  local demo_contest_dir="contestInterface/contests/2015_castor_ajakjtxnasj.1778420233"

  if [ ! -d "$demo_contest_dir" ]; then
    echo "Render demo contest directory is missing: $demo_contest_dir" >&2
    return 1
  fi

  echo "Normalizing Render demo contest assets..."
  ln -sfn "$(basename "$demo_contest_dir")" "contestInterface/contests/2015_castor_ajakjtxnasj"

  find "$demo_contest_dir" -type f \( -name "*.html" -o -name "*.js" \) -print0 |
    xargs -0 -r sed -i -E \
      -e 's#https://bebras-render-demo\.onrender\.com/contestInterface/#/contestInterface/#g' \
      -e 's#https?://localhost:8080/contestInterface/#/contestInterface/#g' \
      -e 's#https?://127\.0\.0\.1:8080/contestInterface/#/contestInterface/#g' \
      -e 's#https?://0\.0\.0\.0:8080/contestInterface/#/contestInterface/#g'

  if find "$demo_contest_dir" -type f \( -name "*.html" -o -name "*.js" \) -print0 |
      xargs -0 -r grep -n 'localhost:8080'; then
    echo "Unsafe localhost:8080 URLs remain in generated demo contest assets." >&2
    return 1
  fi

  chmod -R a+rX "$demo_contest_dir"
}

bootstrap_database() {
  run_sql_file() {
    local sql_file="$1"

    {
      echo "SET SESSION sql_mode='NO_ENGINE_SUBSTITUTION';"
      echo "SET NAMES utf8;"
      cat "$sql_file"
    } | mysql -ubebras -pbebras -h127.0.0.1 beaver_contest
  }

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

    run_sql_file dbv_data/revisions/423/database_structure.sql

    for file in $(find dbv_data/revisions -type f -name "*.sql" | sort -V); do
      rev=$(echo "$file" | cut -d/ -f3)
      if [ "$rev" -gt 423 ]; then
        echo "Applying $file"
        run_sql_file "$file" || true
      fi
    done

    sed -i 's/(796142003655934888, 1358, 12,.*261357)$/&;/' sampleDatabase/database_content.sql || true
    sed -i "s/WHERE ID = 796142003655934888$/WHERE ID = 796142003655934888;/" sampleDatabase/database_content.sql || true

    echo "Importing sample database..."
    run_sql_file sampleDatabase/database_content.sql || true
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

  echo "Checking required Render demo assets..."
  REQUIRED_DEMO_FILES=(
    "contestInterface/contests/2015_castor_ajakjtxnasj.1778420233/contest_56.js"
    "contestInterface/contests/2015_castor_ajakjtxnasj.1778420233/contest_56.html"
    "teacherInterface/bebras-tasks/_common/modules/img/castor.png"
    "teacherInterface/bebras-tasks/_common/modules/bundles/bebras-interface.js"
  )

  for required_file in "${REQUIRED_DEMO_FILES[@]}"; do
    if [ ! -f "$required_file" ]; then
      echo "Missing required Render demo asset: $required_file" >&2
      return 1
    fi
  done

  echo "Normalizing Render demo contest data..."
  mysql -ubebras -pbebras -h127.0.0.1 beaver_contest <<'SQL'
SET @demo_contest_id = 56;
SET @demo_contest_folder = '2015_castor_ajakjtxnasj.1778420233';
SET @demo_group_code = 'yft7zkqt';
SET @demo_group_password = 'zfvaxswk';

UPDATE `contest`
SET `folder` = @demo_contest_folder,
    `name` = 'Training 2015, all levels',
    `open` = 'Open',
    `visibility` = 'Visible',
    `newInterface` = 1,
    `fullFeedback` = 1,
    `showTotalScore` = 1,
    `nbUnlockedTasksInitial` = 4,
    `groupsExpirationMinutes` = 0
WHERE `ID` = @demo_contest_id;

SET @demo_group_id = (
  SELECT `ID`
  FROM `group`
  WHERE `code` = @demo_group_code
  LIMIT 1
);
SET @fallback_demo_group_id = (
  SELECT `ID`
  FROM `group`
  WHERE `code` = CONCAT('#', @demo_group_code)
  LIMIT 1
);
SET @demo_group_id = COALESCE(@demo_group_id, @fallback_demo_group_id);

SET @new_demo_group_id = (
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
  @new_demo_group_id,
  1358,
  12,
  '',
  1201,
  'Castor 2015: all levels',
  100000,
  0,
  0,
  56,
  '',
  '',
  '',
  NULL,
  @demo_group_code,
  @demo_group_password,
  NOW(),
  NOW(),
  0,
  1,
  0,
  0,
  'Unofficial',
  0
WHERE @demo_group_id IS NULL
  AND EXISTS (SELECT 1 FROM `contest` WHERE `ID` = @demo_contest_id);

UPDATE `group`
SET `code` = @demo_group_code,
    `password` = @demo_group_password,
    `contestID` = @demo_contest_id,
    `name` = 'Castor 2015: all levels',
    `nbStudents` = 100000,
    `expectedStartTime` = NOW(),
    `startTime` = NOW(),
    `isPublic` = 1,
    `isGenerated` = 0,
    `bRecovered` = 0,
    `participationType` = 'Unofficial',
    `minCategory` = '',
    `maxCategory` = '',
    `language` = ''
WHERE (`ID` = @demo_group_id AND @demo_group_id IS NOT NULL)
   OR `code` = @demo_group_code;

UPDATE `group`
SET `isPublic` = 0
WHERE `code` <> @demo_group_code;
SQL

  echo "Render demo student group query result:"
  mysql -ubebras -pbebras -h127.0.0.1 beaver_contest -e "SELECT ID, name, contestID, code, password, isPublic FROM \`group\` WHERE code = 'yft7zkqt';" || echo "Sample student group query failed."
}

normalize_demo_contest_assets
echo "Starting database bootstrap in background..."
(bootstrap_database || echo "Database bootstrap failed." >&2) &
echo "Starting Apache on port ${PORT}..."
exec apache2-foreground
