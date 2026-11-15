// UI-A5: actual Chromium tab chrome plus explicitly simulated iPhone icon sizing.
// Run after qa.py web. Requires tests/web's pinned Playwright, DISPLAY and Python/Pillow.
// Outputs only ignored artifacts/ui-a5/icons/. No game or browser settings persisted.
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
import {execFileSync} from 'node:child_process';
const root = fileURLToPath(new URL('../../../', import.meta.url));
const require = createRequire(path.join(root, 'tests/web/review.cjs'));
const {chromium} = require('playwright');
const out = path.join(root, 'artifacts/ui-a5/icons');
fs.mkdirSync(out, {recursive:true});
const icon = '/build/web/index.icon.png', touch = '/build/web/index.apple-touch-icon.png';
function study(mode, phone) {
  const dark = mode === 'dark';
  const bg = dark ? '#202124' : '#f4f5f7', fg = dark ? '#f4e6cd' : '#17222a';
  const caption = phone ? 'iPhone home-screen size / mask study' : 'Exported icon · actual CSS sizes';
  const tiles = Array.from({length:12}, (_,i) => `<div class="tile">${i===5 ? `<img src="${touch}" alt="Roguewood"><span>Roguewood</span>` : '<div class="placeholder"></div><span>—</span>'}</div>`).join('');
  const sizes = [180,32,16].map(n => `<figure><figcaption>${n} px</figcaption><img src="${n===180?touch:icon}" width="${n}" height="${n}"></figure>`).join('');
  return `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Roguewood icon study</title><link rel="icon" href="${icon}"><style>
  *{box-sizing:border-box}body{margin:0;background:${bg};color:${fg};font:14px system-ui}h1{font-size:18px;margin:28px 24px 8px}p{margin:0 24px;line-height:1.6;font-size:12px}main{display:flex;gap:50px;padding:26px}figure{margin:0;min-width:120px}figcaption{margin-bottom:18px}.home{display:grid;grid-template-columns:repeat(4,60px);gap:36px 22px;padding:42px;width:390px}.tile{width:60px;text-align:center;font-size:10px}.tile img,.placeholder{width:60px;height:60px;border-radius:22.4%;display:block}.tile span{display:block;margin-top:6px}.placeholder{background:${dark?'#40454e':'#d7dce3'}}footer{margin:32px 24px;font-size:12px;line-height:1.7;max-width:340px}
  </style></head><body><h1>${caption}</h1><p>${mode} background${phone?' · 60 pt at 3× density':''}</p>${phone?`<div class="home">${tiles}</div><footer>SIMULATED review, not a physical iPhone capture.<br>Actual exported 180 × 180 apple-touch-icon shown at 60 CSS px with a 22.4% rounded mask. Neutral neighbouring tiles are placeholders.</footer>`:`<main>${sizes}</main><p>Actual exported PNGs. Browser default image resampling. No image retouching.</p>`}</body></html>`;
}
const server = http.createServer((req,res) => {
  const url = new URL(req.url,'http://localhost');
  if(url.pathname==='/study') {res.setHeader('Content-Type','text/html; charset=utf-8');res.end(study(url.searchParams.get('mode'),url.searchParams.has('phone')));return;}
  const file = path.resolve(root,'.'+decodeURIComponent(url.pathname));
  if(!file.startsWith(root) || !fs.existsSync(file) || fs.statSync(file).isDirectory()){res.writeHead(404);res.end();return;}
  const types={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
  res.setHeader('Content-Type',types[path.extname(file)]||'application/octet-stream');
  fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const base=`http://127.0.0.1:${server.address().port}`;
const evidence=[];
try {
  for(const mode of ['light','dark']) {
    const browser=await chromium.launch({headless:false,args:['--window-size=1040,760','--window-position=0,0','--use-angle=swiftshader','--enable-unsafe-swiftshader',...(mode==='dark'?['--force-dark-mode']:[])]});
    try {
      const context=await browser.newContext({viewport:null,colorScheme:mode});
      const page=await context.newPage();
      let titleReady=false;
      page.on('console',msg=>{if(msg.text().startsWith('ROGUEWOOD_WEB ')){try{titleReady=JSON.parse(msg.text().slice(14)).screen==='title';}catch{}}});
      await page.goto(base+'/build/web/index.html?qa=1');
      const start=Date.now();
      while(!titleReady && Date.now()-start<90000)await page.waitForTimeout(100);
      if(!titleReady)throw Error('actual exported title did not open');
      const cdp=await context.newCDPSession(page);
      const {windowId}=await cdp.send('Browser.getWindowForTarget');
      await cdp.send('Browser.setWindowBounds',{windowId,bounds:{left:0,top:0,width:1040,height:760}});
      await page.waitForTimeout(500);
      const {bounds}=await cdp.send('Browser.getWindowBounds',{windowId});
      const box=[bounds.left,bounds.top,bounds.left+bounds.width,bounds.top+bounds.height];
      for(const [name,bbox] of [['browser_'+mode,box],['tabs_'+mode,[box[0],box[1],box[2],box[1]+125]]]) {
        execFileSync('python3',['-c','from PIL import ImageGrab; import sys,json; ImageGrab.grab(bbox=tuple(json.loads(sys.argv[2])),xdisplay=sys.argv[3]).save(sys.argv[1])',path.join(out,name+'.png'),JSON.stringify(bbox),process.env.DISPLAY]);
      }
      evidence.push({mode,actual_browser_chrome:true,bounds});
      await context.close();
      const sizes=await browser.newContext({viewport:{width:720,height:400},colorScheme:mode});
      const sizePage=await sizes.newPage();await sizePage.goto(base+'/study?mode='+mode);await sizePage.screenshot({path:path.join(out,'sizes_'+mode+'.png')});await sizes.close();
      const phone=await browser.newContext({viewport:{width:390,height:844},deviceScaleFactor:3,isMobile:true,hasTouch:true,colorScheme:mode});
      const phonePage=await phone.newPage();await phonePage.goto(base+'/study?mode='+mode+'&phone=1');await phonePage.screenshot({path:path.join(out,'iphone_simulated_'+mode+'.png')});await phone.close();
    } finally {await browser.close();}
  }
  fs.writeFileSync(path.join(out,'review.json'),JSON.stringify({evidence,iphone:'SIMULATED: no physical iPhone available',favicon_bytes:fs.statSync(path.join(root,'build/web/index.icon.png')).size},null,2));
  console.log('ROGUEWOOD_UI_A5_ICON_REVIEW_OK');
} finally {server.close();}
