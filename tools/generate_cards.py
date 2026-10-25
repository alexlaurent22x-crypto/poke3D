#!/usr/bin/env python3
"""Generate Casino Minuit's original vector deck and felt printing. No external artwork."""
from pathlib import Path
from html import escape
ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'table'
OUT = ROOT / 'cards'
OUT.mkdir(parents=True, exist_ok=True)
SUITS = [
    ('spade', '#172536', 'M0-37 C-10-22-34-9-34 10 C-34 30-10 35 0 18 C10 35 34 30 34 10 C34-9 10-22 0-37 Z M-5 17 Q-5 34-17 40 L17 40 Q5 34 5 17Z'),
    ('heart', '#ac2e3d', 'M0 35 C-8 27-35 9-35-11 C-35-36-10-42 0-22 C10-42 35-36 35-11 C35 9 8 27 0 35Z'),
    ('diamond', '#ac2e3d', 'M0-40 L28 0 0 40-28 0Z'),
    ('club', '#172536', 'M-8 10 C-39 25-46-13-20-17 C-29-48 28-48 20-17 C46-13 39 25 8 10 Q7 31 20 39 L-20 39 Q-7 31-8 10Z'),
]
PIPS = {
 2: [(0,-112),(0,112)],
 3: [(0,-128),(0,0),(0,128)],
 4: [(-66,-116),(66,-116),(-66,116),(66,116)],
 5: [(-66,-126),(66,-126),(0,0),(-66,126),(66,126)],
 6: [(x,y) for x in [-66,66] for y in [-130,0,130]],
 7: [(x,y) for x in [-66,66] for y in [-130,0,130]]+[(0,-65)],
 8: [(x,y) for x in [-66,66] for y in [-130,0,130]]+[(0,-66),(0,66)],
 9: [(x,y) for x in [-66,66] for y in [-145,-48,48,145]]+[(0,0)],
 10:[(x,y) for x in [-66,66] for y in [-145,-48,48,145]]+[(0,-97),(0,97)]
}
def suit(path, color, x, y, scale=1, rotation=0):
 return f'<g transform="translate({x} {y}) rotate({rotation}) scale({scale})"><path d="{path}" fill="{color}"/></g>'
def portrait(rank, color, flip=False):
 # Original heraldic portrait, repeated head-to-tail like a traditional French deck.
 crown = '<path d="M-49-63L-58-99-23-82 0-112 23-82 58-99 49-63Z" fill="#c6a459" stroke="#172536" stroke-width="3"/>' if rank!='J' else '<path d="M-55-62Q-67-112 5-105Q64-102 59-72L43-61Z" fill="#263d59"/>'
 return f'''<g transform="translate(180 {377 if flip else 143}) rotate({180 if flip else 0}) scale(.76)">
 <path d="M-95 125L-87 61Q-78 40-34 31L34 31Q78 40 87 61L95 125Z" fill="{color}" stroke="#c6a459" stroke-width="5"/>
 <path d="M-60 118L-32 40 0 84 32 40 60 118Z" fill="#c6a459"/>
 <path d="M-23 37L-20 15H20L23 37 0 67Z" fill="#e0bc92"/>
 <ellipse cx="0" cy="-24" rx="43" ry="55" fill="#e8cba5" stroke="#263d59" stroke-width="3"/>
 <path d="M-41-25Q-51-76 0-81Q48-76 42-24L29-38Q4-48-24-37L-31 1Z" fill="#263d59"/>
 <path d="M-21-18L-7-19M9-19L23-18" stroke="#263d59" stroke-width="4"/>
 <path d="M2-15L-3 1 6 2M-12 14Q0 21 13 13" fill="none" stroke="#8b5752" stroke-width="3"/>
 {crown}<path d="M-85 95L-58 79M58 79L85 95" stroke="#eee1bd" stroke-width="4"/>
 <circle cx="0" cy="95" r="11" fill="#263d59" stroke="#eee1bd" stroke-width="3"/>
 </g>'''
for si,(name,color,path) in enumerate(SUITS):
 for ri in range(13):
  n=ri+2; rank=str(n) if n<11 else ['J','Q','K','A'][n-11]
  body=f'''<svg xmlns="http://www.w3.org/2000/svg" width="360" height="520" viewBox="0 0 360 520">
 <rect width="360" height="520" rx="20" fill="#f7f3e8"/>
 <rect x="7" y="7" width="346" height="506" rx="15" fill="none" stroke="#e0d8c6" stroke-width="2"/>
 <g fill="{color}" font-family="DejaVu Serif,serif" font-weight="bold" text-anchor="middle">
 <text x="36" y="58" font-size="45">{rank}</text><g transform="translate(360 520) rotate(180)"><text x="36" y="58" font-size="45">{rank}</text></g></g>
 {suit(path,color,36,88,.40)}{suit(path,color,324,432,.40,180)}'''
  if n==14:
   body+=suit(path,color,180,250,1.85)
   body+='<text x="180" y="368" text-anchor="middle" fill="#b69a60" font-family="serif" font-size="14" letter-spacing="5">MINUIT</text>'
  elif n>=11:
   body+='<rect x="77" y="66" width="206" height="388" rx="3" fill="#e8dfc8" stroke="#b79b61" stroke-width="3"/>'
   body+=portrait(rank,color)+portrait(rank,color,True)
   body+='<path d="M80 260H280" stroke="#b79b61" stroke-width="5"/>'
   body+=suit(path,color,106,108,.35)+suit(path,color,254,412,.35,180)
  else:
   for x,y in PIPS[n]: body+=suit(path,color,180+x,260+y,.67,180 if y>0 else 0)
  (OUT/f'{si*13+ri:02d}.svg').write_text(body+'</svg>\n',encoding='utf-8')
back='''<svg xmlns="http://www.w3.org/2000/svg" width="360" height="520" viewBox="0 0 360 520">
<defs><pattern id="tiles" width="28" height="28" patternUnits="userSpaceOnUse"><path d="M14 0L28 14 14 28 0 14Z" fill="none" stroke="#72818c" stroke-width="1"/><circle cx="14" cy="14" r="2" fill="#ad9568"/></pattern></defs>
<rect width="360" height="520" rx="20" fill="#eee9db"/>
<rect x="14" y="14" width="332" height="492" rx="12" fill="#152c3d"/>
<rect x="22" y="22" width="316" height="476" rx="6" fill="url(#tiles)"/>
<rect x="30" y="30" width="300" height="460" rx="4" fill="none" stroke="#b99c66" stroke-width="3"/>
<path d="M180 147L269 260 180 373 91 260Z" fill="#152c3d" stroke="#c6aa73" stroke-width="4"/>
<path d="M180 168L250 260 180 352 110 260Z" fill="none" stroke="#b39b72" stroke-width="1"/>
<text x="180" y="279" text-anchor="middle" font-family="serif" font-size="69" fill="#e0c99a">M</text>
<text x="180" y="424" text-anchor="middle" font-family="serif" font-size="14" letter-spacing="5" fill="#e0c99a">MINUIT</text>
<g transform="rotate(180 180 260)"><text x="180" y="424" text-anchor="middle" font-family="serif" font-size="14" letter-spacing="5" fill="#e0c99a">MINUIT</text></g></svg>'''
(OUT/'back.svg').write_text(back,encoding='utf-8')
felt='''<svg xmlns="http://www.w3.org/2000/svg" width="2048" height="1280" viewBox="0 0 2048 1280">
<defs><pattern id="weave" width="8" height="8" patternUnits="userSpaceOnUse"><rect width="8" height="8" fill="#124a43"/><path d="M0 0H8M0 4H8" stroke="#195249" stroke-width="1"/><path d="M0 0V8M4 0V8" stroke="#10443e" stroke-width="1"/></pattern></defs>
<rect width="2048" height="1280" fill="url(#weave)"/>
<ellipse cx="1024" cy="640" rx="908" ry="521" fill="none" stroke="#b5a77a" stroke-width="3" opacity=".7"/>
<ellipse cx="1024" cy="640" rx="897" ry="511" fill="none" stroke="#b5a77a" stroke-width="1" opacity=".5"/>
<g fill="#bcb18b" text-anchor="middle" font-family="serif">
<text x="1024" y="868" font-size="60" letter-spacing="18">MINUIT</text>
<text x="1024" y="914" font-size="18" letter-spacing="6">TEXAS HOLD’EM  •  SALON PRIVÉ</text>
<path d="M845 823H947M1101 823H1203" stroke="#bcb18b" stroke-width="2"/>
<path d="M1024 786L1041 805 1024 824 1007 805Z"/>
</g></svg>'''
(ROOT/'felt.svg').write_text(felt,encoding='utf-8')
print('Generated 52 faces, one back, and table felt.')

# Godot's SVG rasterizer deliberately does not render <text>. Bake the type
# outlines into the SVGs. This is a generation-time tool; the game has no Python
# dependency. Install fonttools and the DejaVu fonts to regenerate the deck.
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
import xml.etree.ElementTree as ET
FONT_DIR = Path('/usr/share/fonts/truetype/dejavu')
FONTS = {}
for bold in [False,True]:
 font = TTFont(FONT_DIR / ('DejaVuSerif-Bold.ttf' if bold else 'DejaVuSerif.ttf'))
 FONTS[bold] = (font,font.getGlyphSet(),font.getBestCmap(),font['head'].unitsPerEm)
SVG='{http://www.w3.org/2000/svg}'
ET.register_namespace('', 'http://www.w3.org/2000/svg')
def outline_text(parent, inherited=None):
 inherited = dict(inherited or {})
 inherited.update(parent.attrib)
 for index,node in enumerate(list(parent)):
  if node.tag == SVG+'text':
   attrs=dict(inherited);attrs.update(node.attrib)
   font,glyphs,cmap,units=FONTS[attrs.get('font-weight')=='bold']
   size=float(attrs.get('font-size',16)); scale=size/units
   spacing=float(attrs.get('letter-spacing',0))
   text=''.join(node.itertext())
   width=sum(font['hmtx'][cmap[ord(c)]][0]*scale for c in text) + max(0,len(text)-1)*spacing
   x=float(attrs.get('x',0));y=float(attrs.get('y',0))
   if attrs.get('text-anchor')=='middle':x-=width*.5
   elif attrs.get('text-anchor')=='end':x-=width
   group=ET.Element(SVG+'g')
   if 'fill' in attrs: group.set('fill',attrs['fill'])
   if 'transform' in node.attrib:group.set('transform',node.attrib['transform'])
   for char in text:
    name=cmap[ord(char)]
    pen=SVGPathPen(glyphs);glyphs[name].draw(pen)
    path=ET.SubElement(group, SVG+'path', {'d':pen.getCommands(),'transform':f'translate({x:.3f} {y:.3f}) scale({scale:.6f} {-scale:.6f})'})
    x+=font['hmtx'][name][0]*scale+spacing
   parent.remove(node);parent.insert(index,group)
  else:outline_text(node,inherited)
for file in [*OUT.glob('*.svg'), ROOT/'felt.svg']:
 root=ET.fromstring(file.read_text(encoding='utf-8'))
 outline_text(root)
 file.write_text(ET.tostring(root,encoding='unicode')+'\n',encoding='utf-8')
print('Converted all typography to font outlines for Godot SVG support.')

# Ship raster textures as well: ThorVG's support for SVG patterns and compound
# transformed outlines varies between Godot renderers. librsvg bakes the exact
# source artwork so every platform displays the same deck and fabric.
import os, subprocess
renderer = os.environ.get('RSVG_CONVERT','rsvg-convert')
for file in [*OUT.glob('*.svg'), ROOT/'felt.svg']:
 subprocess.run([renderer,str(file),'-o',str(file.with_suffix('.png'))],check=True)
print('Baked PNG textures with librsvg. SVG files remain the editable sources.')
