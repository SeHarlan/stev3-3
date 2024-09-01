let seed, img;
let fxShader, feedbackShader;
let currentBuffer, previousBuffer, fxBuffer, gridBuffer, textBuffer;
let FR = 30;
let timeCounter = 0;
let clearGlitch = false;
let font
let aspectRatio;
let stage = 0;
let centerCounter = 0;
let stageCounter = 0;
let blocks = [];


//HME - global rec stuff
let ctx, drawingGraphics;
let encoder
let canvas;
let recording = false;
let filename = "R3MIX.mp4"
let frames = [];
let frameCounter = 0

const margin = 0.1;

let activeBlock = [-1, -1, -1, -1];
let activeBlock2 = [-1, -1, -1, -1];

let imgRatio;


const EV3binary = '01000101 01010110 00110011'

const imageUrl = "e1.png"

function evenBucket(n) {
  return Math.floor(n / 2) * 2;
}
function preload() {
  try {
    document.getElementById("loadingBorder").style.display = "block";
  
    fxShader = loadShader('vertex.glsl', 'fxFrag.glsl');
    feedbackShader = loadShader('vertex.glsl', 'feedbackFrag.glsl');
    img = loadImage(imageUrl)
    font = '"Kode Mono", monospace'


  } catch (error) {
    alert(`Error: ${error.message}`)
    console.error(error)
  }
}

async function setup() {
  document.getElementById("loadingBorder").style.display = "none";

  let windowRatio = windowWidth / windowHeight;
  imgRatio = img.width / img.height;
  let canvWidth, canvHeight;

  if (windowRatio > imgRatio) {
    // Window is wider than image needs
    canvHeight = windowHeight;
    canvWidth = canvHeight * imgRatio;
  } else {
    // Window is taller than image needs
    canvWidth = windowWidth;
    canvHeight = canvWidth / imgRatio;
  }

  // const yBorder = canvHeight * margin * 2;
  // const xBorder = canvWidth * margin * 2;
  // canvWidth -= xBorder;
  // canvWidth += yBorder;

  canvWidth = Math.floor(canvWidth / 2) * 2;
  canvHeight = Math.floor(canvHeight / 2) * 2;
  
  
  // img.resize(canvWidth, canvHeight);

  createCanvas(canvWidth, canvHeight);
  // pixelDensity(1);
  frameRate(FR);
  colorMode(HSL);

  currentBuffer = createGraphics(canvWidth, canvHeight, WEBGL);
  previousBuffer = createGraphics(canvWidth, canvHeight, WEBGL);
  fxBuffer = createGraphics(canvWidth, canvHeight, WEBGL);
  gridBuffer = createGraphics(canvWidth, canvHeight);
  textBuffer = createGraphics(canvWidth, canvHeight);
  currentBuffer.noStroke();
  previousBuffer.noStroke();
  fxBuffer.noStroke();
  gridBuffer.noStroke();
  textBuffer.noStroke();

  currentBuffer.colorMode(HSL);
  previousBuffer.colorMode(HSL);
  fxBuffer.colorMode(HSL);
  // gridBuffer.colorMode(HSL);
  textBuffer.colorMode(HSL);

  textBuffer.textFont(font);

  seed = random() * 10; //new Date().getTime() / 1000000000000
  randomSeed(seed);
  noiseSeed(seed);

  if (width > height) {
    aspectRatio = [width / height, 1];
  } else {
    aspectRatio = [1, height / width];
  }

  makeGridImage();
}

function draw() {

  const switchChance = stage == 0 ? 0.01 : 0.05;

  if (stage == 1) {
    const abIndex = floor(timeCounter * 3) % blocks.length;
    const abIndex2 = (abIndex + blocks.length / 2) % blocks.length;

    activeBlock = blocks[abIndex];
    activeBlock2 = blocks[abIndex2];

  } else if (random() < switchChance) {
    if (random() < 0.9) {
      activeBlock = blocks[floor(random() * blocks.length)];
    } else {
      activeBlock = [-1, -1, -1, -1];
    }

    if (random() < 0.9) {
      activeBlock2 = blocks[floor(random() * blocks.length)];
    } else {
      activeBlock2 = [-1, -1, -1, -1];
    }
  }



  [fxShader, feedbackShader].forEach((shdr) => {
    shdr.setUniform("u_texture", currentBuffer);
    shdr.setUniform("u_originalImage", gridBuffer);
    shdr.setUniform("u_resolution", [width, height]);
    shdr.setUniform("u_imageResolution", [img.width, img.height]);
    shdr.setUniform("u_time", timeCounter);
    shdr.setUniform("u_centerTime", centerCounter);
    shdr.setUniform("u_seed", seed);
    shdr.setUniform("u_mouse", [mouseX, mouseY]);
    shdr.setUniform("u_clear", clearGlitch);
    shdr.setUniform("u_aspectRatio", aspectRatio);
    shdr.setUniform("u_stage", stage);
    shdr.setUniform("u_activeBlock", activeBlock);
    shdr.setUniform("u_activeBlock2", activeBlock2);
  });

  previousBuffer.shader(feedbackShader);
  previousBuffer.rect(-width / 2, -height / 2, width, height);

  // Display the result on the main canvas
  fxBuffer.shader(fxShader);
  fxBuffer.rect(-width / 2, -height / 2, width, height);


  image(fxBuffer, 0, 0, width, height);

  // Swap buffers
  currentBuffer.image(previousBuffer, -width / 2, -height / 2, width, height);
  previousBuffer.clear();

  timeCounter += 1 / FR;
  stageCounter += 1;

  if (stage != 1 || random() < 0.25) {
    centerCounter += 1 / FR;
  }

  const switchStage = random() < (stageCounter * 0.00005) % 1;
  if (switchStage) {
    switch (stage) {
      case 2:
        stage = 0;
        break;
      case 0:
        const ran = random();
        if (ran < 0.5) stage = 2;
        else stage = 1;
        stageCounter *= 0.8
        break;
      case 1:
        if (random() < 0.45) {
          stage = 3;
          stageCounter = 0;
          break
        }
      //else go to default 
      default:
        stage = 0;
        stageCounter = 0;
        break;
    }
  }

  if (timeCounter < 1.5) {
    stage = 1;
  } else if (timeCounter < 4) {
    stage = 3;
  } else if (timeCounter < 6) {
    stage = 0;
    stageCounter = 0;
  }

  // stage = 0;
}

function keyPressed() {

  if (key == "c") {
    clearGlitch = !clearGlitch;
    return false
  }
}

// LOTS;
function makeGridImageLots() {
  gridBuffer.noStroke();

  const lilH = height * margin;
  const lilW = width * margin;


  gridBuffer.image(img, lilW, lilH, width - lilW * 2, height - lilH * 2);

  for (let x = 0; x < width; x += lilW) {
    const y = 0
    gridBuffer.image(img, x, y, lilW, lilH);
  }

  for (let y = lilH; y < height; y += lilH) {
    const x = 0
    gridBuffer.image(img, x, y, lilW, lilH);
  }

  for (let x = width - lilW; x > 0; x -= lilW) {
    const y = height - lilH
    gridBuffer.image(img, x, y, lilW, lilH);
  }

  for (let y = height - lilH; y > 0; y -= lilH) {
    const x = width - lilW
    gridBuffer.image(img, x, y, lilW, lilH);
  }



  gridBuffer.stroke("black");
  gridBuffer.strokeWeight(width * 0.01);
  gridBuffer.strokeCap(SQUARE);

  gridBuffer.line(lilW, lilH, lilW, height - lilH);
  gridBuffer.line(lilW, lilH, width - lilW, lilH);
  gridBuffer.line(width - lilW, lilH, width - lilW, height - lilH);
  gridBuffer.line(lilW, height - lilH, width - lilW, height - lilH);
  
  for (let x = lilW; x < width; x += lilW) {
    gridBuffer.line(x, 0, x, lilH);
    gridBuffer.line(x, height - lilH, x, height);
  }

  for (let y = lilH; y < height; y += lilH) {
    gridBuffer.line(0, y, lilW, y);
    gridBuffer.line(width - lilW, y, width, y);
  }


  blocks = [];
  for( let y = 0; y < height - lilH; y += lilH){
    blocks.push([
      0,
      y / height,
      lilW / width,
      (y + lilH) / height
    ])
  }
  for (let x = lilW; x < width - lilW * 2; x += lilW){
    blocks.push([
      x / width,
      (height - lilH) / height,
      (x + lilW) / width,
      1
    ])
  }
  for (let y = height - lilH; y > lilH; y -= lilH){
    blocks.push([
      (width - lilW) / width,
      y / height,
      1,
      (y + lilH) / height
    ])
  }
  for (let x = width - lilW; x > lilW; x -= lilW){
    blocks.push([
      x / width,
      0,
      (x + lilW) / width,
      lilH / height
    ])
  }
}

function makeGridImage4() {
  gridBuffer.noStroke();

  const lilH = height * margin;
  const lilW = width * margin;

  gridBuffer.image(img, lilW, lilH, width - lilW * 2, height - lilH * 2);

  //top right
  gridBuffer.image(img, width - lilW, 0, lilW, lilH);

  //bottom left
  gridBuffer.image(img, 0, height - lilH, lilW, lilH);

  // top left
  gridBuffer.image(img, 0, 0, lilW, lilH);

  //br
  gridBuffer.image(img, width - lilW, height - lilH, lilW, lilH);

  //top
  gridBuffer.push();
  gridBuffer.translate(lilW, lilH);
  gridBuffer.rotate(radians(-90));
  gridBuffer.image(img, 0, 0, lilH, width - lilW * 2);
  gridBuffer.pop();

  //bottom
  gridBuffer.push();
  gridBuffer.translate(width - lilW, height - lilH);
  gridBuffer.rotate(radians(90));
  gridBuffer.image(img, 0, 0, lilH, width - lilW * 2);
  gridBuffer.pop();

  //left
  gridBuffer.push();
  gridBuffer.translate(lilW, height - lilH);
  gridBuffer.rotate(radians(180));
  gridBuffer.image(img, 0, 0, lilW, height - lilH * 2);
  gridBuffer.pop();


  //right
  gridBuffer.push();
  gridBuffer.translate(width - lilW, lilH);
  gridBuffer.image(img, 0, 0, lilW, height - lilH * 2);
  gridBuffer.pop();

  gridBuffer.stroke("black");
  gridBuffer.strokeWeight(width * 0.01);
  gridBuffer.strokeCap(SQUARE);

  //main borders
  gridBuffer.line(lilW, 0, lilW, height);
  gridBuffer.line(0, lilH, width, lilH);
  gridBuffer.line(width - lilW, 0, width - lilW, height); //right
  gridBuffer.line(0, height - lilH, width, height - lilH); //bottom


  blocks = [
    [0, 0, lilW, lilH],
    [lilW, 0, width - lilW, lilH],
    [width - lilW, 0, width, lilH],
    [width - lilW, lilH, width, height - lilH],
    [width - lilW, height - lilH, width, height],
    [lilW, height - lilH, width - lilW, height],
    [0, height - lilH, lilW, height],
    [0, lilH, lilW, height - lilH],
  ];

  blocks = blocks.map((block) => {
    return block.map((val, i) => {
      if (i % 2 == 0) {
        return val / width;
      } else {
        return val / height;
      }
    });
  })
  blocks.reverse()
}

function makeGridImage() {
  gridBuffer.noStroke();

  const lilH = height * margin;
  const lilW = width * margin;

  gridBuffer.image(img, lilW, lilH, width - lilW * 2, height - lilH * 2);

  //top right
  gridBuffer.image(img, width - lilW, 0, lilW, lilH);

  //bottom left
  gridBuffer.image(img, 0, height - lilH, lilW, lilH);

  // top left
  gridBuffer.image(img, 0, 0, lilW, lilH);

  //br
  gridBuffer.image(img, width - lilW, height - lilH, lilW, lilH);

  //top
  gridBuffer.push();
  gridBuffer.translate(lilW, lilH);
  gridBuffer.rotate(radians(-90));
  gridBuffer.image(img, 0, 0, lilH, width - lilW * 2);
  gridBuffer.pop();

  //bottom
  gridBuffer.push();
  gridBuffer.translate(lilW, height - lilH);
  gridBuffer.scale(-1, 1);
  gridBuffer.rotate(radians(90));
  gridBuffer.image(img, 0, 0, lilH, width - lilW * 2);
  gridBuffer.pop();

  //left //top
  gridBuffer.push();
  gridBuffer.translate(lilW, height / 2 - lilH * .5);
  gridBuffer.rotate(radians(180));
  gridBuffer.image(img, 0, 0, lilW, height / 2 - lilH * 1.5);
  gridBuffer.pop();

  //left //bottom
  gridBuffer.push();
  gridBuffer.translate(lilW, height / 2 + lilH * .5);
  // gridBuffer.rotate(radians(180));
  gridBuffer.scale(-1, 1);
  gridBuffer.image(img, 0, 0, lilW, height / 2 - lilH * 1.5);
  gridBuffer.pop();

  //right //top
  gridBuffer.push();
  gridBuffer.translate(width - lilW, lilH);
  gridBuffer.image(img, 0, 0, lilW, height / 2 - lilH * 1.5);
  gridBuffer.pop();

  //right bottom
  gridBuffer.push();
  gridBuffer.translate(width - lilW, height - lilH);
  gridBuffer.scale(1, -1);
  gridBuffer.image(img, 0, 0, lilW, height / 2 - lilH * 1.5);
  gridBuffer.pop();

  //center right
  gridBuffer.image(img, width - lilW, height / 2 - lilH / 2, lilW, lilH);

  //center left
  gridBuffer.image(img, 0, height / 2 - lilH / 2, lilW, lilH);

  // top center
  // gridBuffer.image(img, width / 2 - lilW / 2, 0, lilW, lilH);
  // gridBuffer.image(img, width / 2 - lilW / 2, height - lilH, lilW, lilH);

  gridBuffer.stroke("black");
  gridBuffer.strokeWeight(width * 0.01);
  gridBuffer.strokeCap(SQUARE);

  //main borders
  gridBuffer.line(lilW, 0, lilW, height);
  gridBuffer.line(0, lilH, width, lilH);
  gridBuffer.line(width - lilW, 0, width - lilW, height); //right
  gridBuffer.line(0, height - lilH, width, height - lilH); //bottom

  // topCenter
  // gridBuffer.line(width / 2 - lilW / 2, 0, width / 2 - lilW / 2, lilH);
  // gridBuffer.line(width / 2 + lilW / 2, 0, width / 2 + lilW / 2, lilH);

  // bottomCenter
  // gridBuffer.line(
  //   width / 2 - lilW / 2,
  //   height - lilH,
  //   width / 2 - lilW / 2,
  //   height
  // );
  // gridBuffer.line(
  //   width / 2 + lilW / 2,
  //   height - lilH,
  //   width / 2 + lilW / 2,
  //   height
  // );

  // centerRight
  gridBuffer.line(
    width - lilW,
    height / 2 - lilH / 2,
    width,
    height / 2 - lilH / 2
  );
  gridBuffer.line(
    width - lilW,
    height / 2 + lilH / 2,
    width,
    height / 2 + lilH / 2
  );

  //centerLEft
  gridBuffer.line(lilW, height / 2 - lilH / 2, 0, height / 2 - lilH / 2);
  gridBuffer.line(lilW, height / 2 + lilH / 2, 0, height / 2 + lilH / 2);


  blocks = [
    [0, 0, lilW, lilH],
    [lilW, 0, width - lilW, lilH],
    [width - lilW, 0, width, lilH],
    [width - lilW, lilH, width, height / 2 - lilH / 2],
    [width - lilW, height / 2 - lilH / 2, width, height / 2 + lilH / 2],
    [width - lilW, height / 2 + lilH / 2, width, height - lilH],
    [width - lilW, height - lilH, width, height],
    [lilW, height - lilH, width - lilW, height],
    [0, height - lilH, lilW, height],
    [0, height / 2 + lilH / 2, lilW, height - lilH],
    [0, height / 2 - lilH / 2, lilW, height / 2 + lilH / 2],
    [0, lilH, lilW, height / 2 - lilH / 2],
  ];

  blocks = blocks.map((block) => {
    return block.map((val, i) => {
      if (i % 2 == 0) {
        return val / width;
      } else {
        return val / height;
      }
    });
  });

  blocks.reverse();
}
