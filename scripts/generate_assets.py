"""Rebuilds repository-native pixel-art assets. Requires Pillow; generated PNGs are included."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,math,random
ROOT=Path(__file__).resolve().parents[1]
RES=ROOT/'src/main/resources'
ASSET=RES/'assets/nexus'
ABILITIES=json.loads((ROOT/'scripts/abilities.json').read_text())
EXTRAS=[{'id':'nexus_core','name':'Nexus Core','color':0xBF77FF},{'id':'dominion_codex','name':'Dominion Codex','color':0x8D7FFF},{'id':'clone_sigil','name':'Clone Sigil','color':0xFF5699},{'id':'release_charm','name':'Release Charm','color':0x72FFBB}]
def write(path,data):
 path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(data,indent=2)+'\n')
def png(path,img):
 path.parent.mkdir(parents=True,exist_ok=True);img.save(path)
def rgb(value):return ((value>>16)&255,(value>>8)&255,value&255)
for index,item in enumerate(EXTRAS+ABILITIES):
 img=Image.new('RGBA',(32,32));d=ImageDraw.Draw(img);c=rgb(item['color']);dark=tuple(v//4 for v in c)
 d.polygon([(16,1),(27,7),(30,17),(23,28),(12,31),(3,24),(1,13),(7,5)],fill=(19,13,37,255),outline=dark)
 d.ellipse((5,5,26,26),fill=(35,24,53,255),outline=c,width=2)
 if item['id']=='dominion_codex':
  d.rounded_rectangle((8,6,24,27),radius=2,fill=(47,31,81),outline=c,width=2);d.line((11,7,11,25),fill=(205,197,222),width=2);d.rectangle((15,12,21,18),outline=(241,225,255),width=2)
 elif item['id']=='release_charm':
  d.line([(8,16),(14,22),(24,11)],fill=c,width=3)
 elif item['id']=='nexus_core':
  d.polygon([(16,6),(23,15),(16,25),(9,15)],fill=c,outline=(239,212,255));d.polygon([(16,6),(16,25),(9,15)],fill=(112,50,198))
 else:
  sides=3+index%5
  pts=[(round(16+8*math.cos(i*math.tau/sides-math.pi/2)),round(16+8*math.sin(i*math.tau/sides-math.pi/2))) for i in range(sides)]
  d.line(pts+[pts[0]],fill=c,width=2)
  if index%3==0:d.line((12,10,19,14,13,18,20,22),fill=(242,236,255),width=2)
  elif index%3==1:d.ellipse((13,13,19,19),fill=(245,240,255));d.line((16,6,16,11),fill=c,width=2)
  else:d.line((9,23,23,9),fill=(244,238,255),width=2);d.rectangle((14,14,18,18),fill=c)
 d.point((8,8),fill=(255,255,255));d.line((11,4,17,4),fill=tuple(min(255,v+40) for v in c))
 png(ASSET/'textures/item'/f"{item['id']}.png",img)
 write(ASSET/'models/item'/f"{item['id']}.json",{'parent':'minecraft:item/generated','textures':{'layer0':f"nexus:item/{item['id']}"}})
 write(ASSET/'items'/f"{item['id']}.json",{'model':{'type':'minecraft:model','model':f"nexus:item/{item['id']}"}})
img=Image.new('RGBA',(32,32));d=ImageDraw.Draw(img);rng=random.Random(941)
for y in range(32):
 for x in range(32):
  v=rng.randrange(12);img.putpixel((x,y),(25+v,15+v//2,44+v*2,255))
d.rectangle((2,2,29,29),outline=(113,56,165),width=2);d.polygon([(16,6),(25,16),(16,26),(7,16)],fill=(50,22,82),outline=(182,88,239));d.line((16,8,16,24),fill=(237,174,255),width=2);d.line((10,16,22,16),fill=(237,174,255),width=2)
png(ASSET/'textures/block/nexus_conduit.png',img)
write(ASSET/'models/block/nexus_conduit.json',{'parent':'minecraft:block/cube_all','textures':{'all':'nexus:block/nexus_conduit'}})
write(ASSET/'blockstates/nexus_conduit.json',{'variants':{'':{'model':'nexus:block/nexus_conduit'}}})
write(ASSET/'items/nexus_conduit.json',{'model':{'type':'minecraft:model','model':'nexus:block/nexus_conduit'}})
write(ASSET/'models/item/nexus_conduit.json',{'parent':'nexus:block/nexus_conduit'})
for name,color in [('stun',0xFFFF55),('freeze',0x99DDFF),('vulnerable',0xCC0066)]:
 img=Image.new('RGBA',(18,18));d=ImageDraw.Draw(img);c=rgb(color)
 if name=='stun':d.polygon([(11,1),(3,10),(8,10),(6,17),(15,7),(10,7)],fill=c)
 elif name=='freeze':
  for a in range(0,180,60):
   rad=math.radians(a);d.line((9+7*math.cos(rad),9+7*math.sin(rad),9-7*math.cos(rad),9-7*math.sin(rad)),fill=c,width=2)
 else:d.polygon([(9,1),(16,5),(14,13),(9,17),(3,13),(1,5)],outline=c,width=2);d.line((11,3,7,8,11,10,7,15),fill=c,width=2)
 png(ASSET/'textures/mob_effect'/f'{name}.png',img)
icon=Image.open(ASSET/'textures/item/nexus_core.png').resize((128,128),Image.Resampling.NEAREST)
png(ASSET/'icon.png',icon)
lang={'itemGroup.nexus':'Nexus · Cosmic Dominion','block.nexus.nexus_conduit':'Nexus Conduit','effect.nexus.stun':'Nexus Stun','effect.nexus.freeze':'Nexus Freeze','effect.nexus.vulnerable':'Nexus Vulnerability'}
for item in EXTRAS+ABILITIES:lang[f"item.nexus.{item['id']}"]=item['name']
write(ASSET/'lang/en_us.json',lang)
DATA=RES/'data'
write(DATA/'nexus/recipe/nexus_core.json',{'type':'minecraft:crafting_shaped','category':'equipment','pattern':['AEA','SNS','AEA'],'key':{'A':'minecraft:amethyst_shard','E':'minecraft:ender_pearl','S':'minecraft:echo_shard','N':'minecraft:nether_star'},'result':{'id':'nexus:nexus_core','count':1}})
write(DATA/'nexus/recipe/nexus_conduit.json',{'type':'minecraft:crafting_shaped','category':'building','pattern':['OAO','ACA','OAO'],'key':{'O':'minecraft:obsidian','A':'minecraft:amethyst_shard','C':'nexus:nexus_core'},'result':{'id':'nexus:nexus_conduit','count':1}})
write(DATA/'nexus/recipe/dominion_codex.json',{'type':'minecraft:crafting_shapeless','category':'equipment','ingredients':['minecraft:book','minecraft:amethyst_shard','minecraft:ender_pearl'],'result':{'id':'nexus:dominion_codex','count':1}})
write(DATA/'nexus/recipe/release_charm.json',{'type':'minecraft:crafting_shapeless','category':'equipment','ingredients':['minecraft:amethyst_shard','minecraft:milk_bucket'],'result':{'id':'nexus:release_charm','count':1}})
write(DATA/'nexus/loot_table/blocks/nexus_conduit.json',{'type':'minecraft:block','pools':[{'rolls':1,'entries':[{'type':'minecraft:item','name':'nexus:nexus_conduit'}],'condition':{'type':'minecraft:survives_explosion'}}]})
for path in ['mineable/pickaxe','needs_diamond_tool']:
 write(DATA/'minecraft/tags/block'/f'{path}.json',{'replace':False,'values':['nexus:nexus_conduit']})
print('Generated 25 item/block assets, 3 status icons, recipes and loot.')
