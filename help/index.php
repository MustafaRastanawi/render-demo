<?php
$baseUrl = 'https://bebras-render-demo.onrender.com';
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Bebras Platform Demo Guide</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f5f7fb;
      --panel: #ffffff;
      --text: #1f2937;
      --muted: #5b6472;
      --line: #d9e1ec;
      --primary: #1463c2;
      --warning-bg: #fff7df;
      --warning-border: #e6b84f;
      --warning-text: #5f4300;
      --code-bg: #eef2f7;
    }
    * {
      box-sizing: border-box;
    }
    body {
      margin: 0;
      font-family: Arial, Helvetica, sans-serif;
      background: var(--bg);
      color: var(--text);
      line-height: 1.6;
    }
    main {
      width: min(980px, 100%);
      margin: 0 auto;
      padding: 36px 18px 56px;
    }
    header,
    section {
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 24px;
      margin-bottom: 18px;
    }
    h1,
    h2 {
      margin: 0 0 12px;
      letter-spacing: 0;
      line-height: 1.25;
    }
    h1 {
      font-size: 34px;
    }
    h2 {
      font-size: 22px;
    }
    p {
      margin: 0 0 12px;
      color: var(--muted);
    }
    ol,
    ul {
      margin: 0;
      padding-left: 22px;
    }
    li {
      margin: 6px 0;
    }
    a {
      color: var(--primary);
      font-weight: 700;
    }
    .links {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 10px;
      margin-top: 14px;
    }
    .links a,
    .button {
      display: block;
      border: 1px solid var(--line);
      border-radius: 6px;
      padding: 12px 14px;
      background: #fbfcff;
      text-decoration: none;
      overflow-wrap: anywhere;
    }
    .credentials {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 12px;
      margin-top: 10px;
    }
    .value {
      background: var(--code-bg);
      border-radius: 6px;
      padding: 12px;
      overflow-wrap: anywhere;
    }
    .value strong {
      display: block;
      color: var(--text);
      margin-bottom: 4px;
    }
    code {
      font-family: Consolas, Monaco, monospace;
      font-size: 0.95em;
    }
    .warning {
      border-color: var(--warning-border);
      background: var(--warning-bg);
      color: var(--warning-text);
    }
    .warning p,
    .warning li {
      color: var(--warning-text);
    }
    @media (max-width: 720px) {
      header,
      section {
        padding: 20px;
      }
      .links,
      .credentials {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <main>
    <header>
      <h1>Bebras Platform Demo Guide</h1>
      <p>This is a public demo of the Bebras contest management platform. It is set up for exploration and testing on Render.</p>
      <p>The platform has two main areas: the teacher/coordinator interface for managing contests and groups, and the student/contest interface where participants enter group codes and solve tasks.</p>
    </header>

    <section>
      <h2>Demo Links</h2>
      <div class="links">
        <a href="<?php echo $baseUrl; ?>/">Home / root<br><code><?php echo $baseUrl; ?></code></a>
        <a href="<?php echo $baseUrl; ?>/teacherInterface/">Teacher / coordinator<br><code><?php echo $baseUrl; ?>/teacherInterface/</code></a>
        <a href="<?php echo $baseUrl; ?>/contestInterface/">Student / contest<br><code><?php echo $baseUrl; ?>/contestInterface/</code></a>
        <a href="<?php echo $baseUrl; ?>/help/">Help<br><code><?php echo $baseUrl; ?>/help/</code></a>
      </div>
    </section>

    <section>
      <h2>Demo Teacher/Coordinator Account</h2>
      <div class="credentials">
        <div class="value"><strong>Email</strong><code>demo.teacher@example.com</code></div>
        <div class="value"><strong>Password</strong><code>Demo123456</code></div>
      </div>
      <p>Backup email currently used during testing: <code>mularas78@gmail.com</code></p>
    </section>

    <section>
      <h2>Demo Student Contest</h2>
      <div class="credentials">
        <div class="value"><strong>Group code</strong><code>yft7zkqt</code></div>
        <div class="value"><strong>Password</strong><code>zfvaxswk</code></div>
      </div>
      <ol>
        <li>Open the student/contest page.</li>
        <li>Enter the group code.</li>
        <li>If asked, enter the password.</li>
        <li>Start the contest.</li>
        <li>Try answering and navigating tasks.</li>
      </ol>
    </section>

    <section>
      <h2>Teacher/Coordinator Flow</h2>
      <ol>
        <li>Login to the teacher interface.</li>
        <li>Manage contests.</li>
        <li>Manage schools, classes, and groups.</li>
        <li>Generate group codes for students.</li>
        <li>Assign contests and tasks.</li>
        <li>Review student progress and results.</li>
      </ol>
    </section>

    <section>
      <h2>Student Flow</h2>
      <ol>
        <li>Open the contest interface.</li>
        <li>Enter the group code.</li>
        <li>Start the contest.</li>
        <li>Solve Bebras tasks.</li>
        <li>Submit or finish.</li>
        <li>Results can be reviewed by the coordinator.</li>
      </ol>
    </section>

    <section class="warning">
      <h2>Demo Limitations</h2>
      <ul>
        <li>This is a free Render demo.</li>
        <li>Data can reset after redeploy or restart.</li>
        <li>Do not enter real student data.</li>
        <li>Do not use this deployment for real contests.</li>
        <li>It is for exploration and testing only.</li>
      </ul>
    </section>

    <section>
      <h2>Known Useful Test Values</h2>
      <div class="credentials">
        <div class="value"><strong>Contest ID</strong><code>56</code></div>
        <div class="value"><strong>Group code</strong><code>yft7zkqt</code></div>
        <div class="value"><strong>Group password</strong><code>zfvaxswk</code></div>
        <div class="value"><strong>Teacher demo email</strong><code>demo.teacher@example.com</code></div>
        <div class="value"><strong>Teacher demo password</strong><code>Demo123456</code></div>
      </div>
    </section>
  </main>
</body>
</html>
