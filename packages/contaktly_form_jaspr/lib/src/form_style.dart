/// The stylesheet of the form pages, inlined in their head: system fonts,
/// light and dark, the look of the form (accent, corners, brightness,
/// density).
library;

/// The colours of the dark scheme, on [root].
String _darkColors(String root) =>
    '''
  $root {
    --cf-ink: #eceef3;
    --cf-ink2: #b4b8c4;
    --cf-paper: #1d1f25;
    --cf-page: #121317;
    --cf-line: #3a3d47;
    --cf-bad: #ff6b6b;
  }''';

/// The css of a form page: [accent] (`#RRGGBB`) the accent colour, [radius]
/// the corners of the fields and the button in pixels, [brightness]
/// `light`, `dark` or `system` (the default, the device's), [compact] less
/// space.
///
/// [root] `:root` is a whole page, [pageCss] then styling its body (its
/// font, its width); another selector (`.cf-root`) scopes the variables to
/// a form in a page of another site, whose font it keeps.
String contaktlyFormCss({
  String? accent,
  int? radius,
  String? brightness,
  bool compact = false,
  String root = ':root',
  String pageCss = '',
}) {
  var light = brightness == 'light';
  var dark = brightness == 'dark';
  var page = root == ':root';
  var darkColors = _darkColors(root);
  return '''
$root {
  --cf-accent: ${accent ?? '#2f55d4'};
  --cf-ink: #1c1d22;
  --cf-ink2: #4b4f5c;
  --cf-paper: #ffffff;
  --cf-page: #f3f4f6;
  --cf-line: #d4d7de;
  --cf-bad: #c62828;
  --cf-radius: ${radius ?? 12}px;
  color-scheme: ${light ? 'light' : (dark ? 'dark' : 'light dark')};
}
${dark ? darkColors : (light ? '' : '@media (prefers-color-scheme: dark) {\n$darkColors\n}')}
${page ? pageCss : _scopedCss(root)}
.cf-card {
  background: var(--cf-paper);
  border: 1px solid var(--cf-line);
  border-radius: calc(var(--cf-radius) + 4px);
  padding: 24px;
}
.cf-title { font-size: 1.6rem; line-height: 1.2; margin: 0 0 8px; }
.cf-intro { color: var(--cf-ink2); margin: 0 0 20px; }
.cf-field { display: flex; flex-direction: column; margin-bottom: 16px; }
.cf-field label { font-size: 0.9rem; color: var(--cf-ink2); margin-bottom: 6px; }
.cf-field input, .cf-field textarea, .cf-field select {
  font: inherit;
  color: inherit;
  background: transparent;
  border: 1px solid var(--cf-line);
  border-radius: var(--cf-radius);
  padding: 12px 14px;
  width: 100%;
}
.cf-field textarea { resize: vertical; min-height: 140px; }
.cf-field input:focus, .cf-field textarea:focus, .cf-field select:focus {
  outline: 2px solid var(--cf-accent);
  outline-offset: 1px;
  border-color: transparent;
}
.cf-invalid input, .cf-invalid textarea, .cf-invalid select {
  border-color: var(--cf-bad);
}
.cf-field select option { color: var(--cf-ink); background: var(--cf-paper); }
.cf-field-error, .cf-error { color: var(--cf-bad); font-size: 0.9rem; margin: 6px 0 0; }
.cf-error { margin: 0 0 16px; }
.cf-consent { color: var(--cf-ink2); font-size: 0.85rem; margin: 0 0 16px; }
.cf-consent a { color: var(--cf-accent); }
.cf-hp { position: absolute; left: -10000px; width: 1px; height: 1px; overflow: hidden; }
.cf-actions { margin-top: 8px; }
.cf-button {
  font: inherit;
  font-weight: 600;
  color: #fff;
  background: var(--cf-accent);
  border: 1px solid var(--cf-accent);
  border-radius: var(--cf-radius);
  padding: 10px 22px;
  cursor: pointer;
}
.cf-button:disabled { opacity: 0.6; cursor: default; }
.cf-button-quiet { color: var(--cf-accent); background: transparent; }
.cf-noscript { color: var(--cf-ink2); }
/* The owner of a personal page: photo and name, nothing else. */
.cf-profile { display: flex; align-items: center; gap: 14px; margin: 0 0 16px; }
.cf-profile img {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  object-fit: cover;
  background: var(--cf-line);
}
.cf-profile-name { font-weight: 600; font-size: 1.1rem; }
/* The image on top of a user form (a plan). */
.cf-cover {
  display: block;
  width: 100%;
  aspect-ratio: 3 / 1;
  object-fit: cover;
  border-radius: 8px;
  margin: 0 0 16px;
  background: var(--cf-line);
}
.cf-links { text-align: center; margin: 16px 0 0; font-size: 0.85rem; }
.cf-links a { color: var(--cf-ink2); }
.cf-notice { text-align: center; padding: 48px 24px; }
${compact ? '.cf-card { padding: 16px; }\n.cf-field { margin-bottom: 10px; }\n.cf-intro { margin-bottom: 12px; }' : ''}
/* The preview of a draft. */
.cf-banner {
  margin: 0 0 12px;
  padding: 10px 14px;
  border-radius: var(--cf-radius);
  border: 1px dashed var(--cf-accent);
  color: var(--cf-ink2);
  font-size: 0.9rem;
}
.cf-notice p { color: var(--cf-ink2); margin: 0; }
''';
}

/// A form in a page of another site: its own box model and colours, the
/// font of the site.
String _scopedCss(String root) =>
    '''
$root, $root * { box-sizing: border-box; }
$root { color: var(--cf-ink); line-height: 1.5; }''';
