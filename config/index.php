<?php

if (!bebras_is_production_runtime()) {
   return;
}

if (!function_exists('bebras_production_origin_from_env')) {
   function bebras_require_safe_production_origin($candidate, $sourceName) {
      $origin = bebras_normalize_public_origin($candidate, true, false, false);
      if ($origin === false) {
         throw new RuntimeException($sourceName . ' must be a safe https origin without localhost, path, query, or fragment.');
      }

      return $origin;
   }

   function bebras_production_origin_from_env() {
      $appPublicBaseUrl = bebras_env_value('APP_PUBLIC_BASE_URL');
      if ($appPublicBaseUrl !== '') {
         return bebras_require_safe_production_origin($appPublicBaseUrl, 'APP_PUBLIC_BASE_URL');
      }

      $renderExternalUrl = bebras_env_value('RENDER_EXTERNAL_URL');
      if ($renderExternalUrl !== '') {
         return bebras_require_safe_production_origin($renderExternalUrl, 'RENDER_EXTERNAL_URL');
      }

      $renderExternalHostname = bebras_env_value('RENDER_EXTERNAL_HOSTNAME');
      if ($renderExternalHostname !== '') {
         $renderExternalHostname = preg_replace('#^https?://#i', '', $renderExternalHostname);
         return bebras_require_safe_production_origin('https://' . $renderExternalHostname, 'RENDER_EXTERNAL_HOSTNAME');
      }

      throw new RuntimeException(
         'Production requires APP_PUBLIC_BASE_URL, RENDER_EXTERNAL_URL, or RENDER_EXTERNAL_HOSTNAME with a safe https origin.'
      );
   }
}

$publicOrigin = bebras_production_origin_from_env();
$teacherBaseUrl = $publicOrigin . '/teacherInterface/';
$contestBaseUrl = $publicOrigin . '/contestInterface/';

$config->db->use = 'mysql';
$config->db->mysql->host = '127.0.0.1';
$config->db->mysql->database = 'beaver_contest';
$config->db->mysql->user = 'bebras';
$config->db->mysql->password = 'bebras';
$config->db->mysql->logged = false;

$config->defaultLanguage = 'en';

$config->teacherInterface->sCoordinatorFolder = $teacherBaseUrl;
$config->teacherInterface->sAssetsStaticPath = $contestBaseUrl;
$config->teacherInterface->sAbsoluteStaticPath = $contestBaseUrl;
$config->teacherInterface->sAbsoluteStaticPathOldIE = $contestBaseUrl;
$config->teacherInterface->baseUrl = $teacherBaseUrl;

$config->contestInterface->sAssetsStaticPathNoS3 = $contestBaseUrl;
$config->contestInterface->sAbsoluteStaticPathNoS3 = $contestBaseUrl;
$config->contestInterface->baseUrl = $contestBaseUrl;

$config->certificates->webServiceUrl = $contestBaseUrl;
$config->contestPresentationURL = $contestBaseUrl;
$config->contestOfficialURL = $contestBaseUrl;
$config->contestBackupURL = '';
