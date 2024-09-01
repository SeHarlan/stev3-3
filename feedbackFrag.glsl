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
uniform float u_centerTime;
uniform float u_seed;
uniform vec2 u_mouse;
uniform vec2 u_aspectRatio;
uniform int u_stage;
uniform vec4 u_activeBlock;
uniform vec4 u_activeBlock2;

varying vec2 vTexCoord;


//UTIL
float map(float value, float inputMin, float inputMax, float outputMin, float outputMax) {
    return outputMin + ((value - inputMin) / (inputMax - inputMin) * (outputMax - outputMin));
}

float random(in vec2 _st) {
  vec2 st = _st + u_seed;
  
  return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453);
}
float random(in float _x){
    float x = _x + u_seed;

    return fract(sin(x)*1e4);
}

vec2 random2(vec2 _st){
    vec2 st = _st + u_seed;

    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float noise(vec2 _st) {
  vec2 st = _st + u_seed;

    vec2 i = floor(st);
    vec2 f = fract(st);

    // vec2 u = f*f*(3.0-2.0*f);
    vec2 u = f*f*f*(f*(f*6.-15.)+10.); //improved smoothstep

    float n = mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);

    return 0.5 + 0.5 * n;
}

float noiseNegNeutralPos(vec2 st) {
  float r = noise(st);
  if (r < 0.45) {
    return -1.0;
  } else if (r < 0.55) {
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

float noiseOnOff(vec2 st) {
  return floor(noise(st) + 0.5);
}
float randomOnOff(vec2 st) {
  return floor(random(st) + .5);
}

//MAIN =========================================================
void main() {
  vec2 st = vTexCoord;
  vec2 orgSt = st;

  vec4 orgColor = texture2D(u_originalImage, orgSt);

  if (u_time < .1) {
    gl_FragColor = orgColor;
    return;
  }
  float timeBlock = floor(u_time * .3);
  float timeFract = fract(u_time * .3);

  float centerTimeBlock = floor(u_centerTime * .05);

  //1 - 10
  float chunk = 1. + 2. * floor((0.5 + sin(PI * u_seed + u_centerTime * .075) * 0.5) * 6.);
  vec2 blockSize = vec2(chunk / u_resolution.x, chunk / u_resolution.y);

  vec2 posBlockFloor = floor(st / blockSize) ;
  vec2 posBlockOffset = fract(st / blockSize) ;

  vec2 pixelSize = vec2(1.0 / u_resolution.x, 1.0 / u_resolution.y);

  ///even border
  #define marginMin 0.1
  #define marginMax 0.9

  float leftPoint = marginMin;
  float topPoint = marginMin;
  float bottomPoint = marginMax;
  float rightPoint = marginMax;

  bool topBlock = orgSt.y <= topPoint;
  bool leftBlock = orgSt.x <= leftPoint;
  bool rightBlock = orgSt.x > rightPoint;
  bool bottomBlock = orgSt.y > bottomPoint;

  bool center = !leftBlock && !rightBlock && !bottomBlock && !topBlock;


  vec4 color = texture2D(u_texture, st);

   bool blockOn = false;
  
  if(st.x > u_activeBlock.x && st.x < u_activeBlock.z && st.y > u_activeBlock.y && st.y < u_activeBlock.w) {
    blockOn = true;
  }
  if(st.x > u_activeBlock2.x && st.x < u_activeBlock2.z && st.y > u_activeBlock2.y && st.y < u_activeBlock2.w) {
    blockOn = true;
  }



  float sections = map(random(centerTimeBlock), 0., 1., .02, .5) ; // .5- 0.02
  sections *= chunk / 10.;

  bool useStagared = u_stage != 1 || random(u_centerTime) < 0.5;
 
  if((center || blockOn) && noise(floor(posBlockFloor * sections) * 0.1 + PI * u_seed + u_centerTime*0.1) < 0.475 && useStagared) {

    vec2 belowBlock = posBlockFloor + vec2(1.0, -1.0);
    vec4 belowCheck = texture2D(u_texture, belowBlock * blockSize);
    float belowBrightness = (belowCheck.r + belowCheck.g + belowCheck.b) / 3.0;

    if(belowBrightness >= 0.2 && belowBrightness < 0.5) {
      posBlockFloor.y += 1.0;
    } else if(belowBrightness < 0.8) {
      posBlockFloor.x += 1.0;
    } else if(belowBrightness < 0.9) {
      posBlockFloor.x -= 1.0;
    } else {
      posBlockFloor.y -= 1.0;
    }


    vec2 blockSt = (posBlockFloor + posBlockOffset) * blockSize;
    color = texture2D(u_texture, blockSt);
  } else {
    if(random(posBlockFloor * 10. + u_centerTime) < 0.1) {
      color = orgColor;
    }
  }





  gl_FragColor = color;
}



