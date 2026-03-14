
(function(global,pool,math,width,chunks,digits,module,define,rngname){var startdenom=math.pow(width,chunks),significance=math.pow(2,digits),overflow=significance*2,mask=width-1,nodecrypto;var impl=math['seed'+rngname]=function(seed,options,callback){var key=[];options=(options==true)?{entropy:true}:(options||{});var shortseed=mixkey(flatten(options.entropy?[seed,tostring(pool)]:(seed==null)?autoseed():seed,3),key);var arc4=new ARC4(key);mixkey(tostring(arc4.S),pool);return(options.pass||callback||function(prng,seed,is_math_call){if(is_math_call){math[rngname]=prng;return seed;}
else return prng;})(function(){var n=arc4.g(chunks),d=startdenom,x=0;while(n<significance){n=(n+x)*width;d*=width;x=arc4.g(1);}
while(n>=overflow){n/=2;d/=2;x>>>=1;}
return(n+x)/d;},shortseed,'global'in options?options.global:(this==math));};function ARC4(key){var t,keylen=key.length,me=this,i=0,j=me.i=me.j=0,s=me.S=[];if(!keylen){key=[keylen++];}
while(i<width){s[i]=i++;}
for(i=0;i<width;i++){s[i]=s[j=mask&(j+key[i%keylen]+(t=s[i]))];s[j]=t;}
(me.g=function(count){var t,r=0,i=me.i,j=me.j,s=me.S;while(count--){t=s[i=mask&(i+1)];r=r*width+s[mask&((s[i]=s[j=mask&(j+t)])+(s[j]=t))];}
me.i=i;me.j=j;return r;})(width);}
function flatten(obj,depth){var result=[],typ=(typeof obj),prop;if(depth&&typ=='object'){for(prop in obj){try{result.push(flatten(obj[prop],depth-1));}catch(e){}}}
return(result.length?result:typ=='string'?obj:obj+'\0');}
function mixkey(seed,key){var stringseed=seed+'',smear,j=0;while(j<stringseed.length){key[mask&j]=mask&((smear^=key[mask&j]*19)+stringseed.charCodeAt(j++));}
return tostring(key);}
function autoseed(seed){try{if(nodecrypto)return tostring(nodecrypto.randomBytes(width));global.crypto.getRandomValues(seed=new Uint8Array(width));return tostring(seed);}catch(e){return[+new Date,global,(seed=global.navigator)&&seed.plugins,global.screen,tostring(pool)];}}
function tostring(a){return String.fromCharCode.apply(0,a);}
mixkey(math[rngname](),pool);if(module&&module.exports){module.exports=impl;try{nodecrypto=require('crypto');}catch(ex){}}else if(define&&define.amd){define(function(){return impl;});}})(this,[],Math,256,6,52,(typeof module)=='object'&&module,(typeof define)=='function'&&define,'random');