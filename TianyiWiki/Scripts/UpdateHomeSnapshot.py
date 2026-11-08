from html.parser import HTMLParser
import re,json,pathlib,urllib.parse,urllib.request
class N:
 def __init__(self,t='',a=()):self.tag=t;self.a=dict(a);self.children=[]
 def text(self):return ''.join(c.text() if isinstance(c,N) else c for c in self.children)
 def all(self):
  yield self
  for c in self.children:
   if isinstance(c,N):yield from c.all()
class P(HTMLParser):
 def __init__(self):super().__init__();self.root=N();self.stack=[self.root]
 def handle_starttag(self,t,a):
  n=N(t,a);self.stack[-1].children.append(n)
  if t not in ['img','br','hr','meta','link','input','source','wbr']:self.stack.append(n)
 def handle_endtag(self,t):
  for i in range(len(self.stack)-1,0,-1):
   if self.stack[i].tag==t:self.stack=self.stack[:i];break
 def handle_data(self,d):
  if self.stack[-1].tag not in ['style','script']:self.stack[-1].children.append(d)
request=urllib.request.Request('https://zh-wiki.tyzx.org/api.php?action=parse&page=%E9%A6%96%E9%A1%B5&prop=text&format=json&formatversion=2',headers={'User-Agent':'TianyiWiki-iOS/0.3'})
p=P();p.feed(json.load(urllib.request.urlopen(request,timeout=25))['parse']['text']);sections=[]
root=pathlib.Path(__file__).resolve().parents[2]
for n in p.root.all():
 classes=n.a.get('class','').split()
 if not any(x in classes for x in ['th-hero','th-panel','th-notice','th-footnote']):continue
 descendants=list(n.all());head=next((x.text().strip() for x in descendants if x.tag in ['h1','h2']), '天一维基')
 links=[]
 for a in descendants:
  href=a.a.get('href','')
  if a.tag!='a' or not href or href.startswith('#') or a.a.get('class')=='image':continue
  url=urllib.parse.urljoin('https://zh-wiki.tyzx.org',href)
  if a.text().strip():links.append({'label':a.text().strip(),'url':url})
 images=[]
 for img in descendants:
  if img.tag!='img' or 'th-hero' in classes:continue
  url=urllib.parse.urljoin('https://zh-wiki.tyzx.org',img.a.get('src',''))
  try:
   data=urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'TianyiWiki-iOS/0.3','Referer':'https://zh-wiki.tyzx.org/'}),timeout=20).read();name='home-image-'+str(sum(len(s['images']) for s in sections)+len(images));d=root/'TianyiWiki/Assets.xcassets'/(name+'.imageset');d.mkdir(exist_ok=True);(d/'image.png').write_bytes(data);(d/'Contents.json').write_text(json.dumps({'images':[{'filename':'image.png','idiom':'universal'}],'info':{'author':'xcode','version':1}}));images.append(name)
  except Exception:pass
 text=re.sub(r'\s+',' ',n.text()).strip()
 if text.startswith(head):text=text[len(head):].strip()
 if head=='欢迎来到天一维基':text=text.split('注册与参与')[0].strip()
 if head=='快速导航':text=''
 sections.append({'title':head,'text':text,'links':links,'images':images})
sections=[s for s in sections if s['text'] or s['links'] or s['images']]
for index,section in enumerate(sections):section['id']='home-section-'+str(index)
(root/'TianyiWiki/Resources/HomeSnapshot.json').write_text(json.dumps(sections,ensure_ascii=False,indent=2))
print([(s['title'],len(s['images'])) for s in sections])
