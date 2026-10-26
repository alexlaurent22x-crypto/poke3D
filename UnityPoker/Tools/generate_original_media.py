"""Original illustrated cards and synthesized temporary audio, not recordings."""
from PIL import Image,ImageDraw,ImageFont
import pathlib,math,wave,random,struct,shutil
ROOT=pathlib.Path(__file__).resolve().parents[1]/'Assets/POKS/Resources'
p=ROOT/'Cards';p.mkdir(exist_ok=True)
font='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
for i in range(53):
 im=Image.new('RGB',(384,576),(240,233,216));d=ImageDraw.Draw(im)
 d.rounded_rectangle((6,6,377,569),radius=19,outline=(168,124,47),width=4)
 if i==52:
  d.rounded_rectangle((15,15,368,560),radius=14,fill=(30,10,22),outline=(184,145,63),width=3)
  for a in range(28,368,22):
   for b in range(28,552,22):d.polygon([(a,b-7),(a+7,b),(a,b+7),(a-7,b)],outline=(104,74,40))
  d.rounded_rectangle((58,208,326,370),radius=18,fill=(17,15,19),outline=(195,157,75),width=3)
  d.text((192,253),'POKS',font=ImageFont.truetype(font,51),fill=(216,182,104),anchor='mm')
  d.text((192,319),'CASINO • 3D',font=ImageFont.truetype(font,23),fill=(216,182,104),anchor='mm')
  name='back'
 else:
  suit=i//13;rank=i%13;label=['2','3','4','5','6','7','8','9','10','V','D','R','A'][rank];symbol=['♣','♦','♥','♠'][suit]
  color=(155,20,44) if suit in [1,2] else (20,24,30)
  d.text((39,49),label,font=ImageFont.truetype(font,39),fill=color,anchor='mm');d.text((39,98),symbol,font=ImageFont.truetype(font,38),fill=color,anchor='mm')
  d.text((192,245),symbol,font=ImageFont.truetype(font,144),fill=color,anchor='mm')
  d.text((192,372),label,font=ImageFont.truetype(font,65),fill=color,anchor='mm')
  corner=im.crop((15,18,90,135)).rotate(180);im.paste(corner,(294,441));name=f'{i:02}'
 im.save(p/(name+'.png'))
a=ROOT/'Audio';a.mkdir(exist_ok=True);rng=random.Random(80);rate=22050

def save(name,duration,fn):
 with wave.open(str(a/(name+'.wav')),'wb') as w:
  w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate)
  w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(j/rate)))*26000)) for j in range(int(duration*rate))))
save('card',.23,lambda t:(rng.random()*2-1)*.3*math.exp(-t*18)*(math.sin(t*4800)*.4+.6))
save('chips',.52,lambda t:sum(math.sin(2*math.pi*f*t)*math.exp(-t*d) for f,d in [(2800,20),(4300,27),(6300,40)])*.16)
save('bar',1.1,lambda t:(math.sin(t*math.tau*1820)+math.sin(t*math.tau*2410))*.05*math.exp(-t*9))
# Quiet original 32-second suspended jazz progression, additive synthesis.
notes=[[130.813,164.814,195.998,246.942],[110,130.813,164.814,195.998],[146.832,174.614,220,261.626],[97.999,123.471,146.832,184.997]]
def music(t):
 chord=notes[int(t/8)%4];x=0
 for beat in range(8):
  dt=(t%8)-beat
  if dt>=0:
   f=chord[beat%4]*2;x+=(math.sin(math.tau*f*dt)+.22*math.sin(math.tau*f*2*dt))*math.exp(-dt*1.8)*min(1,dt*60)*.065
 x+=sum(math.sin(math.tau*f*t) for f in chord)*.009
 return x*min(1,t/1.5,(32-t)/1.5)
save('lounge_original',32,music)
print('Generated 53 card textures and 4 explicitly synthetic audio clips')
