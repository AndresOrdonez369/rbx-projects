const {polySDF,circle,ellipse,rbox,seg,U,S,grow,curve,vgrad,solid,icon,hl}=require('./sdf.js');
const only=process.argv[2];
const want=(n)=>!only||only.split(',').includes(n);

// FLAME
const flamePts=(cx,cy,w,h)=>curve(t=>{const a=t*Math.PI*2;const s=Math.sin(a),c=Math.cos(a);const up=Math.max(0,-c);
 const rx=w*(1-0.8*Math.pow(up,1.5));const ry=c<0?h:h*0.45;const flick=0.25*Math.pow(up,4)*w;return [cx+s*rx+flick,cy+c*ry];});
if(want('flame'))icon('flame',polySDF(flamePts(0.5,0.6,0.31,0.48)),vgrad('#FFB13B','#FF5A1F',0.12,0.95),
 [{f:polySDF(flamePts(0.5,0.71,0.16,0.27)),col:vgrad('#FFF6B8','#FFC23B',0.45,0.95)},hl(ellipse(0.36,0.62,0.035,0.08,0.25))]);

// COIN
if(want('coin'))icon('coin',circle(0.5,0.5,0.4),vgrad('#FFE070','#F29A16'),
 [{f:S(circle(0.5,0.5,0.31),circle(0.5,0.5,0.265)),col:solid('#B86A08'),alpha:0.7},
  {f:polySDF([[0.5,0.33],[0.62,0.5],[0.5,0.67],[0.38,0.5]]),col:vgrad('#FFF8D0','#FFC53A',0.33,0.67)},hl(ellipse(0.33,0.29,0.09,0.04,-0.6))]);

// PAW
const pad=U(ellipse(0.5,0.67,0.21,0.16),polySDF([[0.31,0.7],[0.5,0.47],[0.69,0.7]]));
const toes=U(ellipse(0.22,0.43,0.075,0.1,-0.45),ellipse(0.385,0.27,0.08,0.11,-0.15),ellipse(0.615,0.27,0.08,0.11,0.15),ellipse(0.78,0.43,0.075,0.1,0.45));
if(want('paw'))icon('paw',U(pad,toes),vgrad('#C4F4FF','#3FA9EA'),[hl(ellipse(0.42,0.61,0.06,0.028,-0.3))]);

// SNOWFLAKE
const arms=[];for(let k=0;k<6;k++){const a=k*Math.PI/3-Math.PI/2;arms.push(seg(0.5,0.5,0.5+Math.cos(a)*0.38,0.5+Math.sin(a)*0.38,0.042));
 const mx=0.5+Math.cos(a)*0.23,my=0.5+Math.sin(a)*0.23;for(const sg of[-1,1]){const b=a+sg*0.95;arms.push(seg(mx,my,mx+Math.cos(b)*0.12,my+Math.sin(b)*0.12,0.034));}}
if(want('snowflake'))icon('snowflake',U(...arms,circle(0.5,0.5,0.09)),vgrad('#FFFFFF','#8FD8FF'));

// BOOK
const book=rbox(0.47,0.52,0.3,0.36,0.06),clasp=rbox(0.79,0.52,0.05,0.08,0.02);
const runeD=polySDF([[0.5,0.38],[0.61,0.54],[0.5,0.7],[0.39,0.54]]);
if(want('book'))icon('book',U(book,clasp),vgrad('#8FC0FF','#3A59D4'),[{f:rbox(0.24,0.52,0.035,0.33,0.02),col:solid('#2A3F99'),alpha:0.7},{f:runeD,col:vgrad('#F0FCFF','#8FE3FF',0.38,0.7)},{f:clasp,col:vgrad('#FFE070','#E8961A')}]);

// BOLT
if(want('bolt'))icon('bolt',polySDF([[0.6,0.07],[0.22,0.56],[0.46,0.56],[0.38,0.93],[0.8,0.4],[0.55,0.4],[0.66,0.07]]),vgrad('#FFF7A8','#FFB21F'));

// SIZE
if(want('size'))icon('size',U(seg(0.32,0.68,0.68,0.32,0.065),polySDF([[0.84,0.16],[0.84,0.52],[0.48,0.16]]),polySDF([[0.16,0.84],[0.16,0.48],[0.52,0.84]])),vgrad('#FFC0EA','#E354B0'));

// HOME
if(want('home'))icon('home',U(polySDF([[0.5,0.1],[0.92,0.5],[0.08,0.5]]),rbox(0.5,0.66,0.28,0.22,0.04),rbox(0.72,0.24,0.05,0.12,0.01)),vgrad('#FFC46B','#E8742A'),
 [{f:rbox(0.5,0.76,0.085,0.14,0.04),col:solid('#7A3412')},{f:circle(0.5,0.41,0.06),col:solid('#FFF0B0')}]);

// ICE CUBE
const cTop=polySDF([[0.5,0.1],[0.87,0.3],[0.5,0.5],[0.13,0.3]]),cL=polySDF([[0.13,0.3],[0.5,0.5],[0.5,0.92],[0.13,0.72]]),cR=polySDF([[0.87,0.3],[0.5,0.5],[0.5,0.92],[0.87,0.72]]);
if(want('ice'))icon('ice',U(cTop,cL,cR),solid('#9FE3FF'),[{f:cTop,col:vgrad('#F4FDFF','#C7F1FF',0.1,0.5)},{f:cL,col:vgrad('#8CDDFF','#4FAEE8',0.3,0.92)},{f:cR,col:vgrad('#6BC6F5','#2F86CC',0.3,0.92)},hl(seg(0.22,0.42,0.22,0.62,0.02),0.7)]);

// DROP
if(want('drop'))icon('drop',polySDF(curve(t=>{const a=t*Math.PI*2;const s=Math.sin(a),c=Math.cos(a);const up=Math.max(0,-c);return[0.5+s*0.27*(1-Math.pow(up,1.25)),0.63+(c<0?c*0.45:c*0.27)];})),vgrad('#D2F6FF','#3FA6F0'),[hl(ellipse(0.4,0.66,0.04,0.08,0.3))]);

// STAR
if(want('star'))icon('star',grow(polySDF(curve(t=>{const k=Math.round(t*10)%10;const a=k*Math.PI/5-Math.PI/2;const r=k%2?0.19:0.42;return[0.5+Math.cos(a)*r,0.54+Math.sin(a)*r];},10)),0.02),vgrad('#FFF39A','#FFB21F'));

// CLOSE
if(want('close'))icon('close',U(seg(0.27,0.27,0.73,0.73,0.085),seg(0.73,0.27,0.27,0.73,0.085)),solid('#FFFFFF'));

// UP ARROW
if(want('up'))icon('up',polySDF([[0.5,0.1],[0.87,0.48],[0.65,0.48],[0.65,0.9],[0.35,0.9],[0.35,0.48],[0.13,0.48]]),vgrad('#D0FFA6','#3FCB52'));

// TAG
if(want('tag'))icon('tag',S(polySDF([[0.1,0.5],[0.37,0.2],[0.88,0.2],[0.88,0.8],[0.37,0.8]]),circle(0.33,0.5,0.06)),vgrad('#FFD18A','#F07A3A'));

// CHEVRON
if(want('chevron'))icon('chevron',polySDF([[0.12,0.28],[0.5,0.6],[0.88,0.28],[0.88,0.5],[0.5,0.86],[0.12,0.5]]),vgrad('#E0FFF2','#5EE0A8'));

// LOCK
if(want('lock'))icon('lock',U(rbox(0.5,0.65,0.28,0.22,0.05),S(circle(0.5,0.42,0.2),circle(0.5,0.42,0.11))),vgrad('#E2ECF7','#7F95AE'),[{f:rbox(0.5,0.67,0.04,0.08,0.03),col:solid('#2B3A4D')}]);

// PEN (fence)
const posts=U(rbox(0.2,0.55,0.07,0.32,0.03),rbox(0.5,0.55,0.07,0.32,0.03),rbox(0.8,0.55,0.07,0.32,0.03),polySDF([[0.13,0.25],[0.2,0.14],[0.27,0.25]]),polySDF([[0.43,0.25],[0.5,0.14],[0.57,0.25]]),polySDF([[0.73,0.25],[0.8,0.14],[0.87,0.25]]));
const rails=U(rbox(0.5,0.42,0.38,0.045,0.02),rbox(0.5,0.68,0.38,0.045,0.02));
if(want('pen'))icon('pen',U(posts,rails),vgrad('#E3B27A','#9A5A2A'));

// HOURGLASS (timer)
if(want('timer'))icon('timer',U(rbox(0.5,0.13,0.3,0.05,0.03),rbox(0.5,0.87,0.3,0.05,0.03),polySDF([[0.25,0.17],[0.75,0.17],[0.55,0.5],[0.75,0.83],[0.25,0.83],[0.45,0.5]])),vgrad('#CDEFFF','#5DB6F0'),
 [{f:polySDF([[0.36,0.83],[0.64,0.83],[0.5,0.62]]),col:solid('#FFC23B')},{f:polySDF([[0.38,0.3],[0.62,0.3],[0.5,0.45]]),col:solid('#FFC23B')}]);

// ICE PICK (survival tool)
const pickShaft=seg(0.62,0.26,0.26,0.88,0.055);
const pickW=(t)=>0.075*Math.pow(Math.sin(t*Math.PI),0.7)+0.004;
const pickHead=polySDF(curve(t=>[0.1+t*0.82,0.36-0.15*Math.sin(t*Math.PI)-pickW(t)],60).concat(curve(t=>{const s=1-t;return[0.1+s*0.82,0.36-0.15*Math.sin(s*Math.PI)+pickW(s)*0.6];},60)));
if(want('pick'))icon('pick',U(pickShaft,pickHead),solid('#B9DDF0'),[{f:pickShaft,col:vgrad('#E3B27A','#9A5A2A',0.3,0.9)},{f:pickHead,col:vgrad('#F2FBFF','#7FB6D6',0.15,0.42)},hl(seg(0.36,0.24,0.6,0.2,0.012),0.7)]);

// HOME ARROW (carry-mode compass; points up, rotated at runtime)
const arrowHead=polySDF([[0.5,0.08],[0.88,0.52],[0.64,0.52],[0.64,0.9],[0.36,0.9],[0.36,0.52],[0.12,0.52]]);
if(want('homearrow'))icon('homearrow',grow(arrowHead,0.01),vgrad('#FFE9A8','#FF8A2B',0.08,0.9),[hl(seg(0.5,0.18,0.3,0.44,0.025),0.6)]);
