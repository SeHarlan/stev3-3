#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.14159265359
#define TWO_PI 6.28318530718
#define EPSILON 0.00001
#define min_param_a 0.0 + EPSILON
#define max_param_a 1.0 - EPSILON

uniform sampler2D u_texture;
uniform sampler2D u_originalImage;
uniform sampler2D u_grid;
uniform vec2 u_resolution;
uniform vec2 u_imageResolution;
uniform float u_time;
uniform float u_seed;
uniform vec2 u_mouse;
uniform bool u_clear;
uniform vec2 u_aspectRatio;
uniform int u_stage;
uniform float u_centerTime;
uniform vec4 u_activeBlock;
uniform vec4 u_activeBlock2;

varying vec2 vTexCoord;

//UTIL
float map(float value, float inputMin, float inputMax, float outputMin, float outputMax) {
    return outputMin + ((value - inputMin) / (inputMax - inputMin) * (outputMax - outputMin));
}

float random(in vec2 _st) {
  vec2 st = _st; + fract(u_seed);
  
  return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453);
}
float random(in float _x){
    float x = _x + fract(u_seed);

    return fract(sin(x)*1e4);
}

vec2 random2(vec2 _st){
    vec2 st = _st + fract(u_seed);

    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float noise(vec2 _st) {
  vec2 st = _st + fract(u_seed);

    vec2 i = floor(st);
    vec2 f = fract(st);

    // vec2 u = f*f*(3.0-2.0*f);
    vec2 u = f*f*f*(f*(f*6.-15.)+10.); //improved smoothstep

    float n = mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);

    // return n;
    return 0.5 + 0.5 * n;
}

float noiseNegNeutralPos(vec2 st) {
  float r = noise(st);
  if (r < 0.4) {
    return -1.0;
  } else if (r < 0.6) {
    return 0.0;
  } else {
    return 1.0;
  }
}

float randomNegNeutralPos(vec2 st) {
  float r = random(st);
  if (r < 0.33) {
    return -1.0;
  } else if (r < 0.66) {
    return .0;
  } else {
    return 1.0;
  }
}

float noiseNegPos(vec2 st) {
  return noise(st) < 0.5 ? -1.0 : 1.0;
}

float randomNegPos(vec2 st) {
  return floor(random(st) * 3.0) - 1.0;
}

float noiseOnOff(vec2 st) {
  return floor(noise(st) + 0.5);
}
float randomOnOff(vec2 st) {
  return floor(random(st) + 0.5);
}

mat2 rotate2d(float angle){
    return mat2(cos(angle),-sin(angle),
                sin(angle),cos(angle));
}

float tri(float x) {
  return abs(fract(x) - 0.5) * 4.0 - 1.0;
}

float mapAndEase(float value, float inMin, float inMax, float outMin, float outMax) {
    // Perform the linear mapping using mix
    float t = (value - inMin) / (inMax - inMin);
    float mappedValue = mix(outMin, outMax, t);
    
    // Use smoothstep to create a smooth transition outside the range
    if (value < inMin) {
        float easeIn = smoothstep(inMin - (inMax - inMin), inMin, value);
        return mix(value, outMin, easeIn);
    } else if (value > inMax) {
        float easeOut = smoothstep(inMax, inMax + (inMax - inMin), value);
        return mix(value, outMax, easeOut);
    } else {
        return mappedValue;
    }
}

float mapEaseAndTri(float value, float inMin, float inMax, float outMin, float outMax) {
    // Perform the linear mapping using mix
    float t = (value - inMin) / (inMax - inMin);
    float mappedValue =tri(mix(outMin, outMax, t));
    
    // Use smoothstep to create a smooth transition outside the range
    if (value < inMin) {
        float easeIn = smoothstep(inMin - (inMax - inMin), inMin, value);
        return mix(value, outMin, easeIn);
    } else if (value > inMax) {
        float easeOut = smoothstep(inMax, inMax + (inMax - inMin), value);
        return mix(value, outMax, easeOut);
    } else {
        return mappedValue;
    }
}

vec2 zag(vec2 st, float timeBlock, float range) {
 

  vec2 t = vec2(fract(timeBlock * 0.001));
  // float range = .05;
  float amp = 0.75;
  float direction = randomNegPos(t + 100.);

  float freq = 0.25 + floor(random(t + 150.) * 4.) / 4.;
  float minC = map(random(t), 0.,1., 0., 1.0-range);
  float maxC = minC + map(random(t + 200.), 0., 1., 0., range);
  float coord = map(st.y, minC, maxC, 0., 1.);
  float triAmount = tri(PI * .0795 + coord * freq ) * amp * random(t + 300.) * direction;

  float freq2 = 0.25 + floor(random(t + 350.) * 4.) / 4.;
  float minC2 = maxC;
  float maxC2 = minC2 + map(random(t + 400.), 0., 1., 0., range);
  float coord2 = map(st.y, minC2, maxC2, 0., 1.);
  float triAmount2 = tri(PI * .0795 + coord2 * freq2) * amp * random(t + 500.) * -direction;

  if(st.y >= minC && st.y <= maxC2) {
    if(st.y < minC2) {
      st.x += triAmount;
    } else {
      st.x += triAmount2;
    }

    float sideMarg = 0.001;
    if(st.x < sideMarg) st.x = sideMarg;
    if(st.x > 1. - sideMarg) st.x = 1. - sideMarg;
  }

  return st;
}




vec4 edgeDetection(vec4 _col, vec2 _st, float intensity) {
   vec2 onePixel = vec2(1.0) / u_resolution * intensity; //intensity is just to scale the line width down

  float kernel[9];
  vec3 sampleTex[9];

  for (int i = 0; i < 3; ++i) {
    for (int j = 0; j < 3; ++j) {
      sampleTex[i * 3 + j] = texture2D(u_texture, _st + onePixel * vec2(i-1, j-1)).rgb;
    }
  }

  // Sobel filter kernels for horizontal and vertical edge detection
  float Gx[9];
  Gx[0] = -1.0; Gx[1] = 0.0; Gx[2] = 1.0;
  Gx[3] = -2.0; Gx[4] = 0.0; Gx[5] = 2.0;
  Gx[6] = -1.0; Gx[7] = 0.0; Gx[8] = 1.0;

  float Gy[9];
  Gy[0] = -1.0; Gy[1] = -2.0; Gy[2] = -1.0;
  Gy[3] = 0.0; Gy[4] = 0.0; Gy[5] = 0.0;
  Gy[6] = 1.0; Gy[7] = 2.0; Gy[8] = 1.0;


  vec3 edge = vec3(0.0);
  for (int k = 0; k < 9; k++) {
    edge.x += dot(sampleTex[k], vec3(0.299, 0.587, 0.114)) * Gx[k];
    edge.y += dot(sampleTex[k], vec3(0.299, 0.587, 0.114)) * Gy[k];
  }

  float edgeStrength = length(edge);

  vec4 edgeColor = vec4(vec3(edgeStrength), 1.0);

  return edgeColor;
}


float lines(in vec2 pos, float b){
    float scale = 10.0;
    pos *= scale;
    return smoothstep(0.0,
                    .5+b*.5,
                    abs((sin(pos.x*3.1415)+b*2.0))*.5);
}


float whirls(vec2 _st) {
  vec2 st = 1000. - _st ;
  st.x *= u_resolution.x/u_resolution.y;

  float noiseMod = 2. + (sin(u_centerTime*.2)*.5);

  float moveMult = u_centerTime * 0.05;

  st.x -= sin(moveMult * 2.) * 0.08;
  st.y -= cos(moveMult) * 0.04;
  st += vec2(-moveMult * .05, moveMult * .05);

  st += noise(st*3.) * noiseMod;
  st.x -= u_centerTime * 0.02;//axtra/morph

  float splat = noise(st * 4. + 50.); 


  return splat;
}


//MAIN =========================================================
void main() {
  vec2 st = vTexCoord;
  vec2 orgSt = st;

  float chunk = 3.0;
  vec2 blockSize = vec2(chunk / u_resolution.x, chunk / u_resolution.y);

  vec2 posBlockFloor = floor(st / blockSize) ;
  vec2 posBlockOffset = fract(st / blockSize) ;

  vec2 norm_mouse = u_mouse / u_resolution;
  vec2 correctedMousePos = vec2(norm_mouse.x, norm_mouse.y ) * u_aspectRatio;
  vec2 correctedUV = vec2(st.x, st.y ) * u_aspectRatio;


  float timeMult = 2.;
  float timeBlock = floor(u_time * timeMult);
  float timeBlockOffset = floor(u_time * 10.);
 
  vec4 originalColor = texture2D(u_originalImage, st);

  if(u_clear) {
    gl_FragColor = originalColor;
    return;
  }




  //even border
  #define marginMin 0.1
  #define marginMax 0.9

  float leftPoint = marginMin;
  float topPoint = marginMin;
  float bottomPoint = marginMax;
  float rightPoint = marginMax;

  bool blockOn = false;
  
  if(st.x > u_activeBlock.x && st.x < u_activeBlock.z && st.y > u_activeBlock.y && st.y < u_activeBlock.w) {
    blockOn = true;
  }
  if(st.x > u_activeBlock2.x && st.x < u_activeBlock2.z && st.y > u_activeBlock2.y && st.y < u_activeBlock2.w) {
    blockOn = true;
  }


  bool use3dGlitch = u_stage == 3 || (blockOn && u_stage == 2);

    
  //ZAGGIN
  if(use3dGlitch || (u_stage == 1 && blockOn)) {
    st = zag(st, timeBlock, 0.05);
    st = zag(st, timeBlock + 1., 0.05);
    st = zag(st, timeBlock + 3., 0.05);
    st = zag(st, timeBlock + 2., .3);

    if(random(st + 100.) < 0.5) {
      st.y += random(st * .00001 + fract(u_time * 0.001)) * 0.01;
    }
  }



  bool topBlock = st.y <= topPoint;
  bool leftBlock = st.x <= leftPoint;
  bool rightBlock = st.x > rightPoint;
  bool bottomBlock = st.y > bottomPoint;

  bool center = !leftBlock && !rightBlock && !bottomBlock && !topBlock;

  vec4 color = texture2D(u_texture, st);



  bool isDark = color.r < 0.1 && color.g < 0.1 && color.b < 0.1;

  bool useStage1Glitch = u_stage == 1 && random(u_time) < 0.8;


  if (!center && !useStage1Glitch) {
    float edgeInsensity = 0.5;
    color = edgeDetection(color, st, edgeInsensity);
  }

    //flicker
  if(center && u_stage == 1 && random(u_time) < 0.5) {
    vec4 edg = edgeDetection(color, st, 0.5) * .5;
    color = max(edg, color);
  }

  if(!center && useStage1Glitch) {
    float clipT = map(sin((st.x-st.y) * 10. + u_time * 40.), -1., 1., 0.4, 0.9);

    if(blockOn) {
      clipT = random(posBlockFloor + u_time);
    }

    color.r = step(clipT, color.r);
    color.g = step(clipT, color.g);
    color.b = step(clipT, color.b);
  }



  if(use3dGlitch) {
    vec2 offset = vec2(0.01) - sin(u_time * 4.) * 0.005 * random(u_time);
    color.r = texture2D(u_texture, st + offset).r;
    color.g = texture2D(u_texture, st).g;
    color.b = texture2D(u_texture, st - offset).b;
  }

  if(use3dGlitch) {
    color.rgb *= 1.15;
  }


 
  vec3 bgTint = vec3(80./255., 30./255., 70./255.); //ourple
  // vec3 bgTint = vec3(60./255., 70./255., 60./255.); 
  

  if((!center || isDark) ) {
     vec2 stMult = vec2(0.0005, 0.05);

    float range = 0.3;
    color.rgb += map(random(stMult * (st + fract(u_time))), 0.0, 1.0, -range, range);

    // tint
    float tintAmount = .5 + (st.y + sin(u_centerTime * 0.5) * 0.5) * 0.15; 

    if(u_stage == 3 || (blockOn && u_stage == 2) || u_stage == 1) tintAmount*=.35;

    color.rgb = mix(color.rgb, bgTint, tintAmount);
  } 


  if(center) {

    vec2 stMult = vec2(-0.00015, 0.0001);
    float range = 0.05;

    color.r += map(random(stMult * (st + fract(u_time * 1.) + 0.)), 0.0, 1.0, -range, range);
    color.g += map(random(stMult * (st + fract(u_time * 1.) + 100.)), 0.0, 1.0, -range, range);
    color.b += map(random(stMult * (st + fract(u_time * 1.) + 200.)), 0.0, 1.0, -range, range);


    color.rgb *= 1.05;
  } 

  //vignette effect
  if(center && !isDark) {  
    float distFromCenter = distance(orgSt, vec2(0.5, 0.5));
    color.rgb *= 1.0-smoothstep(0.35, .7, distFromCenter);
  } 

  gl_FragColor = color;
}



