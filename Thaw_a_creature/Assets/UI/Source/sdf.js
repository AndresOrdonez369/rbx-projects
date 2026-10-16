const {encode}=require('./png.js');const fs=require('fs');
const OUT=__dirname+'/../';
const hex=(h)=>[parseInt(h.slice(1,3),16)/255,parseInt(h.slice(3,5),16)/255,parseInt(h.slice(5,7),16)/255];
function polySDF(pts){return (x,y)=>{let d=1e9,inside=false;for(let i=0,j=pts.length-1;i<pts.length;j=i++){const[ax,ay]=pts[j],[bx,by]=pts[i];const ex=bx-ax,ey=by-ay,wx=x-ax,wy=y-ay;const t=Math.max(0,Math.min(1,(wx*ex+wy*ey)/(ex*ex+ey*ey)));const dx=wx-ex*t,dy=wy-ey*t;d=Math.min(d,dx*dx+dy*dy);if(((ay>y)!==(by>y))&&(x<(bx-ax)*(y-ay)/(by-ay)+ax))inside=!inside;}d=Math.sqrt(d);return inside?-d:d;};}
const circle=(cx,cy,r)=>(x,y)=>Math.hypot(x-cx,y-cy)-r;
const ellipse=(cx,cy,rx,ry,rot=0)=>(x,y)=>{const c=Math.cos(-rot),s=Math.sin(-rot);const px=(x-cx)*c-(y-cy)*s,py=(x-cx)*s+(y-cy)*c;const k=Math.hypot(px/rx,py/ry);return (k-1)*Math.min(rx,ry);};
const rbox=(cx,cy,hw,hh,r,rot=0)=>(x,y)=>{const c=Math.cos(-rot),s=Math.sin(-rot);const px=(x-cx)*c-(y-cy)*s,py=(x-cx)*s+(y-cy)*c;const qx=Math.abs(px)-hw+r,qy=Math.abs(py)-hh+r;return Math.hypot(Math.max(qx,0),Math.max(qy,0))+Math.min(Math.max(qx,qy),0)-r;};
const seg=(ax,ay,bx,by,r)=>(x,y)=>{const ex=bx-ax,ey=by-ay,wx=x-ax,wy=y-ay;const t=Math.max(0,Math.min(1,(wx*ex+wy*ey)/(ex*ex+ey*ey)));return Math.hypot(wx-ex*t,wy-ey*t)-r;};
const U=(...f)=>(x,y)=>{let m=1e9;for(const g of f){const v=g(x,y);if(v<m)m=v;}return m;};
const S=(a,b)=>(x,y)=>Math.max(a(x,y),-b(x,y));
const grow=(f,r)=>(x,y)=>f(x,y)-r;
const curve=(fn,n=180)=>{const p=[];for(let i=0;i<n;i++)p.push(fn(i/n));return p;};
const vgrad=(top,bot,y0=0.1,y1=0.9)=>{const a=hex(top),b=hex(bot);return(x,y)=>{const t=Math.max(0,Math.min(1,(y-y0)/(y1-y0)));return a.map((v,i)=>v+(b[i]-v)*t);};};
const solid=(h)=>{const c=hex(h);return()=>c;};
const OUTLINE='#0B1726';
function render(name,layers,w=256,h=w){const a=new Float32Array(w*h*4);const ss=[0.25,0.75];const sz=Math.max(w,h);
for(let py=0;py<h;py++)for(let px=0;px<w;px++){let r=0,g=0,b=0,al=0;
for(const L of layers){let cov=0,cr=0,cg=0,cb=0;
 for(const sy of ss)for(const sx of ss){const x=(px+sx)/w,y=(py+sy)/h;const d=L.f(x,y)*sz;const c=Math.max(0,Math.min(1,0.5-d));if(c>0){const col=L.col(x,y);cr+=col[0]*c;cg+=col[1]*c;cb+=col[2]*c;cov+=c;}}
 if(cov<=0)continue;cr/=cov;cg/=cov;cb/=cov;const la=(cov/4)*(L.alpha??1);
 const na=la+al*(1-la);if(na>0){r=(cr*la+r*al*(1-la))/na;g=(cg*la+g*al*(1-la))/na;b=(cb*la+b*al*(1-la))/na;}al=na;}
 const i=(py*w+px)*4;a[i]=r;a[i+1]=g;a[i+2]=b;a[i+3]=al;}
fs.writeFileSync(OUT+name+'.png',encode(w,h,a));console.log('wrote',name);}
const OW=0.045;
function icon(name,shape,fill,details=[]){render(name,[{f:grow(shape,OW),col:solid(OUTLINE)},{f:shape,col:fill},...details]);}
const hl=(f,a=0.55)=>({f,col:solid('#FFFFFF'),alpha:a});
module.exports={polySDF,circle,ellipse,rbox,seg,U,S,grow,curve,vgrad,solid,hex,render,icon,hl,OUTLINE};
