<?php

header('Content-Type: application/json');

function exitWithLogErrorJson($payload) {
   echo json_encode($payload);
   exit;
}

if (!isset($_POST['errormsg'])) {
	exitWithLogErrorJson(['success' => false, 'error' => 'missing errormsg argument']);
}

try {
   require_once("../shared/common.php");
   require_once("../vendor/autoload.php");

   initSession();

   $teamID = isset($_SESSION["teamID"]) && $_SESSION["teamID"] ? $_SESSION["teamID"] : (isset($_POST["teamID"]) && $_POST["teamID"] ? $_POST["teamID"] : null);
   $questionKey = isset($_POST["questionKey"]) ? $_POST["questionKey"] : null;
   $errormsg = $_POST['errormsg'];

   $parser = \UAParser\Parser::create();
   $userAgent = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : '';
   $browserStr = $parser->parse($userAgent)->toString();

   $stmt = $db->prepare('insert into error_log (date, teamID, message, browser, questionKey) values (UTC_TIMESTAMP(), :teamID, :errormsg, :browserStr, :questionKey);');
   $stmt->execute(['teamID' => $teamID, 'errormsg' => $errormsg, 'browserStr' => $browserStr, 'questionKey' => $questionKey]);
   exitWithLogErrorJson(['success' => true]);
} catch (Throwable $e) {
   error_log('logError.php failed: '.$e->getMessage());
   exitWithLogErrorJson(['success' => false, 'error' => 'log failed']);
}
