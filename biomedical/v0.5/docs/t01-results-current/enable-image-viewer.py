"""Restore the report's native pan/zoom lightbox for raster figures after am render."""
from pathlib import Path
import base64
import hashlib
import re
import sys

path = Path(sys.argv[1])
html = path.read_text()
if '<!-- t01-image-viewer -->' in html:
    print('Image viewer already enabled')
    raise SystemExit(0)
shell = '''<!-- t01-image-viewer -->
<div class="am-lightbox" hidden aria-modal="true" role="dialog" aria-label="Fullscreen chart" data-expand="Fullscreen">
<div class="am-lightbox-backdrop"></div>
<div class="am-lightbox-header">
<div class="am-lightbox-title"><span class="am-lightbox-title-text"></span><span style="font-size:12px;margin-left:16px">Scroll to zoom · Drag to pan · Double-click to reset · Esc to close</span></div>
<div class="am-lightbox-actions"><button class="am-lightbox-close" data-action="close" title="Close" aria-label="Close">✕</button></div>
</div>
<div class="am-lightbox-stage"><div class="am-lightbox-canvas am-diagram"></div></div>
</div>
'''
assert '<div class="am-lightbox"' not in html
html = html.replace('<textarea id="am-source"', shell + '<textarea id="am-source"', 1)
assert '<!-- t01-image-viewer -->' in html
css = '''
/* t01-image-viewer: keep raster charts compatible with the built-in viewer. */
.am-figure > img { cursor: zoom-in; }
.am-figure .am-diagram-expand { width: auto; padding: 6px 10px; gap: 6px; height: 32px; opacity: 1; }
.am-lightbox-canvas img { display: block; max-width: none !important; max-height: none !important; }
'''
html = html.replace('</style>',css+'</style>',1)
pattern = r'(<script\b[^>]*>)(.*?)(</script>)'
changed = 0
def update(match):
    global changed
    script = match.group(2)
    if '// ── Diagram Lightbox' not in script:
        return match.group(0)
    old = script
    replacements = [
        ("document.querySelectorAll('.am-diagram:not(.am-lightbox-canvas)')", "document.querySelectorAll('.am-diagram:not(.am-lightbox-canvas), .am-figure')"),
        ("const svg = [...diag.children].find((el) => el.tagName.toLowerCase() === 'svg');", "const svg = [...diag.children].find((el) => ['svg', 'img'].includes(el.tagName.toLowerCase()));"),
        ("(parseFloat(svg.getAttribute('width')) || svg.clientWidth || 800)", "(svg.naturalWidth || parseFloat(svg.getAttribute('width')) || svg.clientWidth || 800)"),
        ("(parseFloat(svg.getAttribute('height')) || svg.clientHeight || 600)", "(svg.naturalHeight || parseFloat(svg.getAttribute('height')) || svg.clientHeight || 600)"),
        ("btn.innerHTML = expandSvg;", "btn.innerHTML = expandSvg;\n      if (diag.classList.contains('am-figure')) btn.append(document.createTextNode(expandLabel));"),
        ("diag.prepend(btn);", "diag.prepend(btn);\n      const image = diag.querySelector(':scope > img');\n      if (image) image.addEventListener('click', () => open(diag, btn));")
    ]
    for before, after in replacements:
        assert script.count(before)==1,before
        script=script.replace(before,after,1)
    before_hash=base64.b64encode(hashlib.sha256(old.encode()).digest()).decode()
    after_hash=base64.b64encode(hashlib.sha256(script.encode()).digest()).decode()
    update.hashes=(before_hash,after_hash)
    changed+=1
    return match.group(1)+script+match.group(3)
html=re.sub(pattern,update,html,flags=re.S)
assert changed==1
before,after=update.hashes
assert html.count("'sha256-"+before+"'")==1
html=html.replace("'sha256-"+before+"'","'sha256-"+after+"'")
path.write_text(html)
print('Enabled native image lightbox, click-to-open and pan/zoom; updated CSP hash.')
