const {encode}=require('./png.js');const fs=require('fs');
const {polySDF,ellipse,circle,U,vgrad,icon,hl}=require('./sdf.js');
const OUT=__dirname+'/../';
const only=process.argv[2];const want=(n)=>!only||only.split(',').includes(n);

// fixed paw
if(want('paw')){
 const pad=U(ellipse(0.5,0.69,0.22,0.165),ellipse(0.5,0.6,0.13,0.11));
 const toes=U(ellipse(0.22,0.43,0.075,0.1,-0.45),ellipse(0.385,0.27,0.08,0.11,-0.15),ellipse(0.615,0.27,0.08,0.11,0.15),ellipse(0.78,0.43,0.075,0.1,0.45));
 icon('paw',U(pad,toes),vgrad('#C4F4FF','#3FA9EA'),[hl(ellipse(0.42,0.63,0.06,0.028,-0.3))]);
}

// value noise
function mkNoise(seed){const P=new Uint16Array(512);let s=seed;const rnd=()=>{s=(s*1103515245+12345)&0x7fffffff;return s/0x7fffffff;};const p=[...Array(256).keys()];for(let i=255;i>0;i--){const j=Math.floor(rnd()*(i+1));[p[i],p[j]]=[p[j],p[i]];}for(let i=0;i<512;i++)P[i]=p[i&255];
 const g=new Float32Array(256);for(let i=0;i<256;i++)g[i]=rnd();
 const f=(x,y)=>{const xi=Math.floor(x),yi=Math.floor(y),xf=x-xi,yf=y-yi;const h=(a,b)=>g[P[(P[a&255]+b)&511]&255];const u=xf*xf*(3-2*xf),v=yf*yf*(3-2*yf);const a=h(xi,yi),b=h(xi+1,yi),c=h(xi,yi+1),d=h(xi+1,yi+1);return a+(b-a)*u+(c-a)*v+(a-b-c+d)*u*v;};
 return (x,y,oct=5)=>{let s=0,amp=0.5,fr=1,n=0;for(let o=0;o<oct;o++){s+=amp*f(x*fr,y*fr);n+=amp;amp*=0.5;fr*=2;}return s/n;};}
const clamp=(v,a=0,b=1)=>Math.max(a,Math.min(b,v));
const smooth=(e0,e1,x)=>{const t=clamp((x-e0)/(e1-e0));return t*t*(3-2*t);};

// FROST VIGNETTE: white-cyan crystalline frost creeping from edges, transparent center
/* superseded by frost2.js */ if(only&&want('frostvignette')){const W=1024,H=576;const a=new Float32Array(W*H*4);const n=mkNoise(7),n2=mkNoise(31);
 // crystal streaks: random line segments from edges inward
 const streaks=[];let s=99;const rnd=()=>{s=(s*1103515245+12345)&0x7fffffff;return s/0x7fffffff;};
 for(let i=0;i<260;i++){const side=Math.floor(rnd()*4);let x,y,ang;const t=rnd();
  if(side===0){x=t;y=0;ang=Math.PI/2;}else if(side===1){x=t;y=1;ang=-Math.PI/2;}else if(side===2){x=0;y=t;ang=0;}else{x=1;y=t;ang=Math.PI;}
  ang+=(rnd()-0.5)*1.3;const len=0.05+rnd()*0.16;streaks.push([x,y,x+Math.cos(ang)*len*(H/W),y+Math.sin(ang)*len,0.0012+rnd()*0.0018]);
  // branch
  const bx=x+Math.cos(ang)*len*0.5*(H/W),by=y+Math.sin(ang)*len*0.5;const b2=ang+(rnd()<0.5?-1:1)*(0.6+rnd()*0.5);const bl=len*0.4;streaks.push([bx,by,bx+Math.cos(b2)*bl*(H/W),by+Math.sin(b2)*bl,0.001]);}
 for(let py=0;py<H;py++)for(let px=0;px<W;px++){const x=px/W,y=py/H;
  // distance to nearest edge in normalized "short side" units
  const dx=Math.min(x,1-x)*(W/H),dy=Math.min(y,1-y);const e=Math.min(dx,dy);
  const warp=(n(x*6,y*6)-0.5)*0.12+(n2(x*18,y*18)-0.5)*0.05;
  const depth=0.2;const base=1-smooth(0,depth,e+warp); // 1 at edge
  let crystal=0;for(const[ax,ay,bx,by,r]of streaks){const ex=(bx-ax)*W/H,ey=by-ay,wx=(x-ax)*W/H,wy=y-ay;const tt=clamp((wx*ex+wy*ey)/(ex*ex+ey*ey));const d=Math.hypot(wx-ex*tt,wy-ey*tt);if(d<0.006){crystal=Math.max(crystal,(1-d/0.006)*(1-tt*0.6));}}
  const sparkle=Math.pow(n2(x*90,y*90),6)*3;
  const al=clamp(base*0.85+crystal*0.7*smooth(0.35,0,e)+sparkle*base);
  const i=(py*W+px)*4;const w=clamp(0.75+crystal*0.25+sparkle*0.3);a[i]=0.78+0.22*w;a[i+1]=0.92+0.08*w;a[i+2]=1;a[i+3]=al;}
 fs.writeFileSync(OUT+'frostvignette.png',encode(W,H,a));console.log('frostvignette');}

// WARM VIGNETTE: soft amber glow at edges
if(want('warmvignette')){const W=512,H=288;const a=new Float32Array(W*H*4);const n=mkNoise(3);
 for(let py=0;py<H;py++)for(let px=0;px<W;px++){const x=px/W,y=py/H;const dx=Math.min(x,1-x)*(W/H),dy=Math.min(y,1-y);const e=Math.min(dx,dy)+(n(x*5,y*5)-0.5)*0.06;
  const al=Math.pow(1-smooth(0,0.28,e),1.6);const i=(py*W+px)*4;a[i]=1;a[i+1]=0.62+0.2*(1-al);a[i+2]=0.25;a[i+3]=al;}
 fs.writeFileSync(OUT+'warmvignette.png',encode(W,H,a));console.log('warmvignette');}

// GLOW: radial soft white
if(want('glow')){const W=256;const a=new Float32Array(W*W*4);for(let py=0;py<W;py++)for(let px=0;px<W;px++){const d=Math.hypot(px/W-0.5,py/W-0.5)*2;const al=Math.pow(clamp(1-d),2.2);const i=(py*W+px)*4;a[i]=a[i+1]=a[i+2]=1;a[i+3]=al;}
 fs.writeFileSync(OUT+'glow.png',encode(W,W,a));console.log('glow');}

// RAYS: sunburst
if(want('rays')){const W=512;const a=new Float32Array(W*W*4);const R=16;for(let py=0;py<W;py++)for(let px=0;px<W;px++){const x=px/W-0.5,y=py/W-0.5;const d=Math.hypot(x,y)*2;const ang=Math.atan2(y,x);const ray=Math.pow(Math.abs(Math.cos(ang*R/2)),6);const fall=Math.pow(clamp(1-d),1.3)*smooth(0,0.15,d);const al=clamp(ray*fall*1.2+Math.pow(clamp(1-d),3)*0.35);const i=(py*W+px)*4;a[i]=a[i+1]=a[i+2]=1;a[i+3]=al;}
 fs.writeFileSync(OUT+'rays.png',encode(W,W,a));console.log('rays');}

// SPARKLE: 4-point star
if(want('sparkle')){const W=128;const a=new Float32Array(W*W*4);for(let py=0;py<W;py++)for(let px=0;px<W;px++){const x=Math.abs(px/W-0.5)*2,y=Math.abs(py/W-0.5)*2;const star=clamp(1-(Math.pow(x,0.5)+Math.pow(y,0.5))/1.0);const core=Math.pow(clamp(1-Math.hypot(x,y)),3);const al=clamp(star*1.6+core);const i=(py*W+px)*4;a[i]=a[i+1]=a[i+2]=1;a[i+3]=al;}
 fs.writeFileSync(OUT+'sparkle.png',encode(W,W,a));console.log('sparkle');}

// SNOW PATTERN: subtle tileable speckle for panels (white, low alpha)
if(want('snowtile')){const W=256;const a=new Float32Array(W*W*4);let s=5;const rnd=()=>{s=(s*1103515245+12345)&0x7fffffff;return s/0x7fffffff;};const flakes=[];for(let i=0;i<70;i++)flakes.push([rnd(),rnd(),0.004+rnd()*0.01,0.15+rnd()*0.4]);
 for(let py=0;py<W;py++)for(let px=0;px<W;px++){const x=px/W,y=py/W;let al=0;for(const[fx,fy,r,o]of flakes){for(const ox of[-1,0,1])for(const oy of[-1,0,1]){const d=Math.hypot(x-fx-ox,y-fy-oy);if(d<r*2)al=Math.max(al,o*clamp(1-d/(r*2))*clamp((r*2-d)/r));}}const i=(py*W+px)*4;a[i]=a[i+1]=a[i+2]=1;a[i+3]=al;}
 fs.writeFileSync(OUT+'snowtile.png',encode(W,W,a));console.log('snowtile');}
