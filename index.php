<?php
$baseUrl = 'https://bebras-render-demo.onrender.com';
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Bebras Platform Demo</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f5f7fb;
      --panel: #ffffff;
      --text: #1f2937;
      --muted: #5b6472;
      --line: #d9e1ec;
      --primary: #1463c2;
      --primary-dark: #0e4f9f;
    }
    * {
      box-sizing: border-box;
    }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: Arial, Helvetica, sans-serif;
      background: var(--bg);
      color: var(--text);
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 32px 16px;
    }
    main {
      width: min(720px, 100%);
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      padding: 32px;
      box-shadow: 0 18px 50px rgba(31, 41, 55, 0.08);
    }
    h1 {
      margin: 0 0 12px;
      font-size: 32px;
      line-height: 1.2;
      letter-spacing: 0;
    }
    p {
      margin: 0 0 24px;
      color: var(--muted);
      line-height: 1.6;
    }
    .actions {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 12px;
    }
    a.button {
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 52px;
      padding: 12px 16px;
      border-radius: 6px;
      background: var(--primary);
      color: #ffffff;
      text-align: center;
      text-decoration: none;
      font-weight: 700;
      line-height: 1.25;
    }
    a.button:hover,
    a.button:focus {
      background: var(--primary-dark);
    }
    @media (max-width: 640px) {
      main {
        padding: 24px;
      }
      .actions {
        grid-template-columns: 1fr;
      }
    }
  </style>
</head>
<body>
  <main>
    <h1>Bebras Platform Demo</h1>
    <p>This public Render demo lets you try the student contest area and the teacher/coordinator tools with sample data.</p>
    <div class="actions" aria-label="Demo navigation">
      <a class="button" href="/contestInterface/">Student contest</a>
      <a class="button" href="/teacherInterface/">Teacher/coordinator</a>
      <a class="button" href="/help/">Demo help guide</a>
    </div>
  </main>
</body>
</html>
