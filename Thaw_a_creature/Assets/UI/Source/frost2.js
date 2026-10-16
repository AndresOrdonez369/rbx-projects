const {encode}=require('./png.js');const fs=require('fs');
const W=1024,H=576,AR=W/H;
let s=1234;const rnd=()=>{s=(s*1103515245+12345)&0x7fffffff;return s/0x7fffffff;};
const clamp=(v,a=0,b=1)=>Math.max(a,Math.min(b,v));const smooth=(e0,e1,x)=>{const t=clamp((x-e0)/(e1-e0));return t*t*(3-2*t);};
// raster buffers
const acc=new Float32Array(W*H);
function line(x0,y0,x1,y1,w,o){// in px
 const minx=Math.max(0,Math.floor(Math.min(x0,x1)-w-1)),maxx=Math.min(W-1,Math.ceil(Math.max(x0,x1)+w+1)),miny=Math.max(0,Math.floor(Math.min(y0,y1)-w-1)),maxy=Math.min(H-1,Math.ceil(Math.max(y0,y1)+w+1));
 const ex=x1-x0,ey=y1-y0,L2=ex*ex+ey*ey||1;
 for(let y=miny;y<=maxy;y++)for(let x=minx;x<=maxx;x++){const t=clamp(((x-x0)*ex+(y-y0)*ey)/L2);const d=Math.hypot(x-x0-ex*t,y-y0-ey*t);const c=clamp(w-d+0.5)*o;const i=y*W+x;acc[i]=Math.max(acc[i],c);}}
function dendrite(x,y,ang,len,w,depth,o){const steps=6;const sl=len/steps;let cx=x,cy=y;
 for(let k=0;k<steps;k++){const nx=cx+Math.cos(ang)*sl,ny=cy+Math.sin(ang)*sl;line(cx,cy,nx,ny,w*(1-k/steps*0.6),o);
  if(depth>0&&k>0){for(const sg of[-1,1]){if(rnd()<0.85)dendrite(nx,ny,ang+sg*Math.PI/3,len*(0.42-0.04*k)*(0.7+rnd()*0.5),w*0.6,depth-1,o*0.9);}}
  cx=nx;cy=ny;ang+=(rnd()-0.5)*0.12;}}
const seeds=[];
for(let i=0;i<70;i++){const side=Math.floor(rnd()*4);const t=rnd();let x,y,a;
 if(side===0){x=t*W;y=0;a=Math.PI/2;}else if(side===1){x=t*W;y=H;a=-Math.PI/2;}else if(side===2){x=0;y=t*H;a=0;}else{x=W;y=t*H;a=Math.PI;}
 a+=(rnd()-0.5)*1.4;dendrite(x,y,a,36+rnd()*90,1.6+rnd()*1.2,2,0.95);}
// fine extra crystals near corners
for(const[cx,cy,a0] of[[0,0,Math.PI/4],[W,0,3*Math.PI/4],[0,H,-Math.PI/4],[W,H,-3*Math.PI/4]])for(let i=0;i<6;i++)dendrite(cx,cy,a0+(rnd()-0.5)*1.2,100+rnd()*90,2.2,2,1);
const out=new Float32Array(W*H*4);
for(let py=0;py<H;py++)for(let px=0;px<W;px++){const x=px/W,y=py/H;const e=Math.min(Math.min(x,1-x)*AR,Math.min(y,1-y));
 const haze=Math.pow(1-smooth(0,0.16,e),1.4)*0.75;const c=acc[py*W+px]*(1-smooth(0.1,0.26,e));const al=clamp(haze+c*0.85);
 const i=(py*W+px)*4;const w=clamp(c*1.2);out[i]=0.72+0.28*w;out[i+1]=0.9+0.1*w;out[i+2]=1;out[i+3]=al;}
fs.writeFileSync(__dirname+'/../frostvignette.png',encode(W,H,out));
const o=new Float32Array(W*H*4);for(let k=0;k<W*H;k++){const a=out[k*4+3];o[k*4]=0.35*(1-a)+out[k*4]*a;o[k*4+1]=0.45*(1-a)+out[k*4+1]*a;o[k*4+2]=0.3*(1-a)+out[k*4+2]*a;o[k*4+3]=1;}
