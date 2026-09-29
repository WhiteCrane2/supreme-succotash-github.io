import processing.sound.*;

// =========================================================================
// CONFIG – edit these
// =========================================================================
String songTitle   = "Local Forecast - Elevator";
String artistName  = "Kevin MacLeod";
String releaseDate = "2024";

// =========================================================================
// GLOBAL STATE
// =========================================================================
SoundFile track;
PImage cover;
PImage bg;

boolean isPlaying     = false;
float   currentVolume = 0.8f;
int     loopMode      = 0;   // 0 = off, 1 = Loop 1x, 2 = Loop Track
float   lastPos       = -1;
int     stuckFrames   = 0;
boolean showMenu      = false;

// Timeline
float sliderX = 340;
float sliderY = 428;
float sliderW = 500;

// =========================================================================
// SETUP
// =========================================================================
void setup() {
  size(1180, 660);
  surface.setTitle("Music Player");
  buildBackground();

  // Load cover art
  try {
    cover = loadImage("cover.png");
  } catch (Exception e) {
    println("Cover image not found.");
  }

  // Load audio
  try {
    track = new SoundFile(this, "music.mp3");
    if (track != null) {
      track.amp(currentVolume);
    }
  } catch (Exception e) {
    println("Could not load music.mp3 – check the data folder.");
  }
}

void buildBackground() {
  bg = createImage(width, height, RGB);
  bg.loadPixels();
  float cx = width / 2.0;
  float cy = height / 2.0;
  float maxD = dist(0, 0, cx, cy);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      float t = dist(x, y, cx, cy) / maxD;
      float v = lerp(48, 4, pow(t, 0.8));
      bg.pixels[y * width + x] = color(v);
    }
  }
  bg.updatePixels();
}

// =========================================================================
// DRAW
// =========================================================================
void draw() {
  image(bg, 0, 0);

  drawTitle();
  drawTopButtons();
  drawArt();
  drawTimeline();
  drawBottomPanel();
  drawHoursBar();

  if (showMenu) drawMenu();
  checkLoopTracking();
}

// ---------- Title ----------
void drawTitle() {
  metalRect(390, 15, 400, 72, 6, color(195));
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(22);
  text(songTitle, 590, 40);
  textSize(14);
  text(artistName + "  |  " + releaseDate, 590, 67);
}

// ---------- Top buttons ----------
void drawTopButtons() {
  boolean h;

  // Rewind 5s
  h = hit(30, 20, 50, 50);
  polyStyle(stateColor(h, false, false));
  triangle(55, 20, 55, 70, 30, 45);
  triangle(80, 20, 80, 70, 55, 45);

  // Fast-forward 5s
  h = hit(95, 20, 50, 50);
  polyStyle(stateColor(h, false, false));
  triangle(95, 20, 95, 70, 120, 45);
  triangle(120, 20, 120, 70, 145, 45);

  // Exit
  h = hit(1020, 20, 44, 44);
  metalRect(1020, 20, 44, 44, 6, stateColor(h, true, false));
  stroke(40);
  strokeWeight(6);
  line(1032, 32, 1052, 52);
  line(1052, 32, 1032, 52);

  // Volume +
  h = hit(1072, 20, 44, 44);
  metalRect(1072, 20, 44, 44, 6, stateColor(h, false, false));
  noStroke();
  fill(40);
  rect(1082, 39, 24, 6);
  rect(1091, 30, 6, 24);

  // Volume -
  h = hit(1124, 20, 44, 44);
  metalRect(1124, 20, 44, 44, 6, stateColor(h, false, false));
  noStroke();
  fill(40);
  rect(1134, 39, 24, 6);

  // Volume bar
  noStroke();
  fill(60);
  rect(1020, 76, 148, 5, 3);
  fill(70, 200, 220);
  rect(1020, 76, 148 * currentVolume, 5, 3);
}

// ---------- Album art ----------
void drawArt() {
  metalRect(430, 95, 320, 320, 8, color(195));

  if (cover != null) {
    image(cover, 440, 105, 300, 300);
  } else {
    noStroke();
    fill(35);
    rect(440, 105, 300, 300);
    fill(200);
    textAlign(CENTER, CENTER);
    textSize(22);
    text("ALBUM ART", 590, 245);
    textSize(12);
    fill(150);
    text("put cover.png in the data folder", 590, 275);
  }
}

// ---------- Timeline ----------
void drawTimeline() {
  float d   = getDur();
  float pos = getPos();

  stroke(70);
  strokeWeight(4);
  line(sliderX, sliderY, sliderX + sliderW, sliderY);

  float thumbX = sliderX;
  if (d > 0) {
    thumbX = sliderX + constrain(pos / d, 0, 1) * sliderW;
    stroke(70, 200, 220);
    line(sliderX, sliderY, thumbX, sliderY);
  }

  noStroke();
  fill(255);
  ellipse(thumbX, sliderY, 12, 12);
}

// ---------- Bottom panel ----------
void drawBottomPanel() {
  boolean h;

  fill(24);
  stroke(90);
  strokeWeight(2);
  rect(30, 445, 1120, 160, 14);

  // Loop 1x
  h = hitCircle(110, 525, 100);
  metalCircle(110, 525, 100, stateColor(h, false, loopMode == 1));
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(16);
  text("Loop 1x", 110, 525);

  // Loop Track
  h = hitCircle(225, 525, 100);
  metalCircle(225, 525, 100, stateColor(h, false, loopMode == 2));
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(16);
  text("Loop\nTrack", 225, 525);

  // Previous
  h = hit(390, 493, 120, 64);
  polyStyle(stateColor(h, false, false));
  leftArrow(390, 493, 120, 64);

  // Play / Pause
  h = hitCircle(590, 525, 110);
  metalCircle(590, 525, 110, stateColor(h, false, false));
  noStroke();
  fill(30);
  if (isPlaying) {
    rect(570, 501, 14, 48, 2);
    rect(596, 501, 14, 48, 2);
  } else {
    triangle(574, 497, 574, 553, 616, 525);
  }

  // Next
  h = hit(670, 493, 120, 64);
  polyStyle(stateColor(h, false, false));
  rightArrow(670, 493, 120, 64);

  // Time display
  float d   = getDur();
  float pos = getPos();
  metalRect(830, 485, 190, 80, 6, color(195));
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(17);
  text(formatTime(pos) + " / " + formatTime(d), 925, 512);
  textSize(14);
  text("-" + formatTime(max(d - pos, 0)) + " remaining", 925, 540);

  // Menu
  h = hit(1040, 485, 100, 80);
  metalRect(1040, 485, 100, 80, 6, stateColor(h, false, showMenu));
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(22);
  text("Menu", 1090, 525);
}

// ---------- Hours bar ----------
void drawHoursBar() {
  metalRect(390, 620, 400, 28, 3, color(195));
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(15);
  text("Hours on app: " + formatHMS(millis() / 1000), 590, 634);
}

// ---------- Menu ----------
void drawMenu() {
  fill(15, 15, 15, 240);
  stroke(70, 200, 220);
  strokeWeight(2);
  rect(340, 110, 500, 300, 12);

  fill(255);
  textAlign(CENTER, CENTER);
  textSize(24);
  text("MENU", 590, 145);

  fill(210);
  textAlign(LEFT, CENTER);
  textSize(15);
  float tx = 375;
  text("Hover = cyan      Click = green      Exit = red", tx, 190);
  text("<<  /  >>   jump back / forward 5 seconds", tx, 225);
  text("Left / right arrows   restart the track", tx, 255);
  text("+  /  -   volume up / down", tx, 285);
  text("Loop 1x   repeat once more", tx, 315);
  text("Loop Track   repeat forever", tx, 345);
  text("Click the bar under the art to seek", tx, 375);

  fill(140);
  textSize(12);
  textAlign(CENTER, CENTER);
  text("click anywhere to close", 590, 398);
}

// =========================================================================
// INTERACTION
// =========================================================================
void mousePressed() {
  if (showMenu) {
    showMenu = false;
    return;
  }

  if (hit(1020, 20, 44, 44)) {
    exit();
    return;
  }

  if (hit(1040, 485, 100, 80)) {
    showMenu = true;
    return;
  }

  if (track == null) return;

  try {
    // Seek
    if (hit(sliderX, sliderY - 12, sliderW, 24)) {
      float d = getDur();
      if (d > 0) {
        float ratio = constrain((mouseX - sliderX) / sliderW, 0, 1);
        track.jump(min(ratio * d, d - 0.1));
      }
    }
    // Rewind
    else if (hit(30, 20, 50, 50)) {
      track.jump(max(getPos() - 5, 0));
    }
    // Fast-forward
    else if (hit(95, 20, 50, 50)) {
      float d = getDur();
      if (d > 0) track.jump(min(getPos() + 5, d - 0.5));
    }
    // Volume +
    else if (hit(1072, 20, 44, 44)) {
      currentVolume = min(currentVolume + 0.1, 1.0);
      track.amp(currentVolume);
    }
    // Volume -
    else if (hit(1124, 20, 44, 44)) {
      currentVolume = max(currentVolume - 0.1, 0.0);
      track.amp(currentVolume);
    }
    // Previous / Next (restart)
    else if (hit(390, 493, 120, 64) || hit(670, 493, 120, 64)) {
      track.jump(0);
    }
    // Play / Pause
    else if (hitCircle(590, 525, 110)) {
      if (isPlaying) {
        track.pause();
        isPlaying = false;
      } else {
        float d = getDur();
        if (d > 0 && getPos() >= d - 0.1) track.jump(0);
        track.play();
        isPlaying = true;
        stuckFrames = 0;
      }
    }
    // Loop 1x
    else if (hitCircle(110, 525, 100)) {
      loopMode = (loopMode == 1) ? 0 : 1;
    }
    // Loop Track
    else if (hitCircle(225, 525, 100)) {
      loopMode = (loopMode == 2) ? 0 : 2;
    }
  } catch (Exception e) {
    println("Audio action skipped: " + e.getMessage());
  }
}

void 
