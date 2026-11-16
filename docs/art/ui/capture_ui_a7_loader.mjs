// Capture the exported loader at controlled progress, without downloading a second game.
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
const {chromium} = createRequire(import.meta.url)('playwright');
const out = 'artifacts/ui-a7/loader'; fs.mkdirSync(out,{recursive:true});
let html = fs.readFileSync('build/web/index.html','utf8');
html = html.replace(/<script\b([^>]*)>[\s\S]*?<\/script>/g,(all,attrs)=>attrs.includes('rw-loader-js')?all:'');
const splash = 'data:image/png;base64,'+fs.readFileSync('assets/brand/splash.png').toString('base64');
html = html.replace(/src="[^"]*index\.png"/g,`src="${splash}"`);
const browser = await chromium.launch({headless:true,args:['--no-sandbox']});
const page = await browser.newPage({viewport:{width:540,height:960}});
await page.setContent(html);
await page.evaluate(()=>{document.querySelector('#status').style.display='block';document.querySelector('#status').style.visibility='visible';});
for (const value of [0.5,1]) {
 await page.evaluate(v=>{const p=document.querySelector('#status-progress');p.style.display='block';p.max=1;p.value=v;},value);
 await page.waitForTimeout(500);
 await page.screenshot({path:path.join(out,value===1?'complete.png':'half.png')});
 if (!(await page.locator('#rw-loader').isVisible())) throw new Error('Loader not visible');
 const state=await page.locator('#rw-loader').getAttribute('data-progress');
 if (Number(state)!==value) throw new Error('Unexpected loader progress '+state);
}
await browser.close();
console.log('ROGUEWOOD_UI_A7_LOADER_OK');
