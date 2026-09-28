import processing.sound.*;

// =========================================================================
// EDIT THESE: song info shown in the title box at the top
// =========================================================================
String songTitle   = "Song Title";
String artistName  = "Artist Name";
String releaseDate = "Release Date";

// =========================================================================
// ENGINE VARIABLES
// =========================================================================
SoundFile track;
PImage cover;   // optional: put cover.png in the sketch's data folder
PImage bg;

boolean isPlaying = false;
boolean isMuted = false;
float currentVolume = 0.8f;
float storedVolume = 0.8f;

// 0 = off, 1 = Loop 1x (repeat once), 2 = Loop Track (forever), 3 = Loop: N (custom count)
int loopMode = 0;
int customLoopTarget = 1;
int loopsRemaining = 0;

float lastPos = -1;
int stuckFrames = 0;
boolean showMenu = false;

// timeline (under the album art)
float sliderX = 340, sliderY = 428, sliderW = 500;

// =========================================================================
// SETUP
// =========================================================================
void setup() {
  size(1180, 660);
  surface.setTitle("Music Player");
  buildBackground();

  File f = new File(dataPath("cover.png"));
  if (f.exists()) {
    cover = loadImage("cover.png");
  }

  try {
    track = new SoundFile(this, "music.mp3");
    if (track != null) {
      track.amp(currentVolume);
    }
  } catch (Exception e) {
    println("Audio device or file read delay registered. Continuing in safe mode...");
  }
}

// dark radial background (lighter in the middle, black at the edges)
void buildBackground() {
  bg = createImage(width, height, RGB);
  bg.loadPixels();
  float cx = width / 2.0f;
  float cy = height / 2.0f;
  float maxD = dist(0, 0, cx, cy);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      float t = dist(x, y, cx, cy) / maxD;
      float v = lerp(48, 4, pow(t, 0.8f));
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

// ---------- TOP: title box ----------
void drawTitle() {
  metalRect(390, 15, 400, 72, 6, color(195));
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(22);
  text(songTitle, 590, 40);
  textSize(14);
  text(artistName + "  |  " + releaseDate, 590, 67);
}

// ---------- TOP: rewind / fast-forward (left), exit / volume (right) ----------
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

  // Exit (X) - turns red
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

  // volume level bar (empty while muted)
  noStroke();
  fill(60);
  rect(1020, 76, 148, 5, 3);
  fill(isMuted ? color(225, 60, 60) : color(70, 200, 220));
  rect(1020, 76, 148 * (isMuted ? 0 : currentVolume), 5, 3);
}

// ---------- MIDDLE: album art ----------
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

// ---------- timeline under the art ----------
void drawTimeline() {
  float d = getDur();
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

// ---------- BOTTOM: control panel ----------
// Row A (centre y = 515): loops, prev, play, next, duration, menu
// Row B (y = 572):        Reset, Stop, Mute, Loop: N
void drawBottomPanel() {
  boolean h;

  // panel background
  fill(24);
  stroke(90);
  strokeWeight(2);
  rect(30, 445, 1120, 160, 14);

  // Loop 1x
  h = hitCircle(105, 515, 90);
  metalCircle(105, 515, 90, stateColor(h, false, loopMode == 1));
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(15);
  text("Loop 1x", 105, 515);

  // Loop Track
  h = hitCircle(210, 515, 90);
  metalCircle(210, 515, 90, stateColor(h, false, loopMode == 2));
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(15);
  text("Loop\nTrack", 210, 515);

  // Previous (left arrow)
  h = hit(390, 483, 120, 64);
  polyStyle(stateColor(h, false, false));
  leftArrow(390, 483, 120, 64);

  // Play / Pause
  h = hitCircle(590, 515, 100);
  metalCircle(590, 515, 100, stateColor(h, false, false));
  noStroke();
  fill(30);
  if (isPlaying) {
    rect(572, 491, 14, 48, 2);
    rect(596, 491, 14, 48, 2);
  } else {
    triangle(576, 489, 576, 541, 614, 515);
  }

  // Next (right arrow)
  h = hit(670, 483, 120, 64);
  polyStyle(stateColor(h, false, false));
  rightArrow(670, 483, 120, 64);

  // Duration + remaining
  float d = getDur();
  float pos = getPos();
  metalRect(830, 475, 190, 80, 6, color(195));
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(17);
  text(formatTime(pos) + " / " + formatTime(d), 925, 502);
  textSize(14);
  text("-" + formatTime(max(d - pos, 0)) + " remaining", 925, 530);

  // Menu
  h = hit(1040, 475, 100, 80);
  metalRect(1040, 475, 100, 80, 6, stateColor(h, false, showMenu));
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(22);
  text("Menu", 1090, 515);

  // ---- Row B: the buttons from the original player ----
  smallBtn(409, 572, 80, 24, "Reset", stateColor(hit(409, 572, 80, 24), false, false));
  smallBtn(503, 572, 80, 24, "Stop", stateColor(hit(503, 572, 80, 24), true, false));

  color muteCol = isMuted ? color(225, 60, 60) : stateColor(hit(597, 572, 80, 24), false, false);
  smallBtn(597, 572, 80, 24, isMuted ? "Unmute" : "Mute", muteCol);

  smallBtn(691, 572, 80, 24, "Loop: " + customLoopTarget,
           stateColor(hit(691, 572, 80, 24), false, loopMode == 3));
}

void smallBtn(float x, float y, float w, float h, String label, color c) {
  metalRect(x, y, w, h, 6, c);
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(13);
  text(label, x + w / 2, y + h / 2 - 1);
}

// ---------- very bottom: time on app ----------
void drawHoursBar() {
  metalRect(390, 620, 400, 28, 3, color(195));
  fill(30);
  textAlign(CENTER, CENTER);
  textSize(15);
  text("Hours on app: " + formatHMS(millis() / 1000), 590, 634);
}

// ---------- menu overlay ----------
void drawMenu() {
  fill(15, 15, 15, 240);
  stroke(70, 200, 220);
  strokeWeight(2);
  rect(340, 100, 500, 330, 12);

  fill(255);
  textAlign(CENTER, CENTER);
  textSize(24);
  text("MENU", 590, 130);

  fill(210);
  textAlign(LEFT, CENTER);
  textSize(14);
  float tx = 365;
  text("Hover = cyan      Click = green      Exit / Stop = red", tx, 172);
  text("<<  /  >>   jump back / forward 5 seconds", tx, 196);
  text("Left / right arrows and Reset   restart the track", tx, 220);
  text("Stop   stop playback and go back to the start", tx, 244);
  text("Mute   silence / restore the volume", tx, 268);
  text("+  /  -   volume up / down", tx, 292);
  text("Loop 1x   repeat the track one more time", tx, 316);
  text("Loop Track   repeat the track forever", tx, 340);
  text("Loop: N   play the track N times (click to change 1-5)", tx, 364);
  text("Click the bar under the art to seek", tx, 388);
  fill(140);
  textSize(12);
  textAlign(CENTER, CENTER);
  text("click anywhere to close", 590, 415);
}

// =========================================================================
// INTERACTIONS
// =========================================================================
void mousePressed() {
  // menu open: any click closes it
  if (showMenu) {
    showMenu = false;
    return;
  }

  // exit + menu don't need audio
  if (hit(1020, 20, 44, 44)) {
    exit();
    return;
  }
  if (hit(1040, 475, 100, 80)) {
    showMenu = true;
    return;
  }

  if (track == null) return;

  try {
    // seek bar
    if (hit(sliderX, sliderY - 12, sliderW, 24)) {
      float d = getDur();
      if (d > 0) {
        float ratio = constrain((mouseX - sliderX) / sliderW, 0, 1);
        track.jump(min(ratio * d, d - 0.1f));
      }
    }
    // rewind 5s
    else if (hit(30, 20, 50, 50)) {
      track.jump(max(getPos() - 5.0f, 0));
    }
    // fast-forward 5s
    else if (hit(95, 20, 50, 50)) {
      float d = getDur();
      if (d > 0) {
        track.jump(min(getPos() + 5.0f, d - 0.5f));
      }
    }
    // volume +
    else if (hit(1072, 20, 44, 44)) {
      isMuted = false;
      currentVolume = min(currentVolume + 0.1f, 1.0f);
      track.amp(currentVolume);
    }
    // volume -
    else if (hit(1124, 20, 44, 44)) {
      isMuted = false;
      currentVolume = max(currentVolume - 0.1f, 0.0f);
      track.amp(currentVolume);
    }
    // previous
    else if (hit(390, 483, 120, 64)) {
      track.jump(0);
    }
    // next
    else if (hit(670, 483, 120, 64)) {
      track.jump(0);
    }
    // play / pause
    else if (hitCircle(590, 515, 100)) {
      if (isPlaying) {
        track.pause();
        isPlaying = false;
      } else {
        float d = getDur();
        if (d > 0 && getPos() >= d - 0.1f) track.jump(0);
        track.play();
        isPlaying = true;
        stuckFrames = 0;
      }
    }
    // loop 1x
    else if (hitCircle(105, 515, 90)) {
      loopMode = (loopMode == 1) ? 0 : 1;
    }
    // loop track
    else if (hitCircle(210, 515, 90)) {
      loopMode = (loopMode == 2) ? 0 : 2;
    }
    // Reset (FR)
    else if (hit(409, 572, 80, 24)) {
      track.jump(0);
    }
    // Stop (ST)
    else if (hit(503, 572, 80, 24)) {
      track.stop();
      isPlaying = false;
    }
    // Mute (MT)
    else if (hit(597, 572, 80, 24)) {
      isMuted = !isMuted;
      if (isMuted) {
        storedVolume = currentVolume;
        track.amp(0);
      } else {
        currentVolume = storedVolume;
        track.amp(currentVolume);
      }
    }
    // Loop: N (custom count, cycles 1-5)
    else if (hit(691, 572, 80, 24)) {
      if (loopMode == 3) {
        customLoopTarget = (customLoopTarget % 5) + 1;
        loopsRemaining = customLoopTarget;
      } else {
        loopMode = 3;
        loopsRemaining = customLoopTarget;
      }
    }
  } catch (Exception e) {
    println("Audio action skipped: " + e.getMessage());
  }
}

// SoundFile has no isPlaying(), so end-of-track is detected by comparing
// position() to duration() (plus a "position stopped moving near the end" fallback).
void checkLoopTracking() {
  if (track == null || !isPlaying) {
    stuckFrames = 0;
    return;
  }
  try {
    float d = getDur();
    float pos = getPos();

    if (abs(pos - lastPos) < 0.0001f) stuckFrames++;
    else stuckFrames = 0;
    lastPos = pos;

    boolean ended = d > 0 && (pos >= d - 0.1f || (stuckFrames > 20 && pos > d - 1.5f));
    if (!ended) return;

    stuckFrames = 0;
    if (loopMode == 1) {
      track.jump(0);
      track.play();
      loopMode = 0;
    } else if (loopMode == 2) {
      track.jump(0);
      track.play();
    } else if (loopMode == 3) {
      loopsRemaining--;
      if (loopsRemaining > 0) {
        track.jump(0);
        track.play();
      } else {
        isPlaying = false;
        loopMode = 0;
      }
    } else {
      isPlaying = false;
    }
  } catch (Exception e) {}
}

// =========================================================================
// HELPERS
// =========================================================================
float getDur() {
  try {
    if (track != null) return max(track.duration(), 0);
  } catch (Exception e) {}
  return 0;
}

float getPos() {
  try {
    if (track != null) return max(track.position(), 0);
  } catch (Exception e) {}
  return 0;
}

boolean hit(float x, float y, float w, float h) {
  return mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h;
}

boolean hitCircle(float cx, float cy, float d) {
  return dist(mouseX, mouseY, cx, cy) <= d / 2;
}

// idle = silver, hover = cyan, pressed/active = green, exit/stop hover = red
color stateColor(boolean hover, boolean isExit, boolean active) {
  if (isExit && hover) return color(225, 60, 60);
  if (hover && mousePressed) return color(60, 200, 100);
  if (active) return color(60, 200, 100);
  if (hover) return color(70, 200, 220);
  return color(195);
}

void polyStyle(color base) {
  fill(base);
  stroke(100);
  strokeWeight(1);
}

// silver "metal" rectangle: darker edge, lighter center
void metalRect(float x, float y, float w, float h, float r, color base) {
  color edge = lerpColor(base, color(0), 0.3f);
  color mid = lerpColor(base, color(255), 0.4f);
  stroke(90);
  strokeWeight(1);
  fill(edge);
  rect(x, y, w, h, r);
  noStroke();
  int steps = 6;
  for (int i = 1; i <= steps; i++) {
    float t = i / (float) steps;
    float ix = w * 0.3f * t;
    float iy = h * 0.3f * t;
    fill(lerpColor(edge, mid, t));
    rect(x + ix, y + iy, w - 2 * ix, h - 2 * iy, r * (1 - t));
  }
}

// silver "metal" circle: darker edge, lighter center
void metalCircle(float cx, float cy, float d, color base) {
  color edge = lerpColor(base, color(0), 0.3f);
  color mid = lerpColor(base, color(255), 0.4f);
  stroke(90);
  strokeWeight(1);
  fill(edge);
  ellipse(cx, cy, d, d);
  noStroke();
  int steps = 8;
  for (int i = 1; i <= steps; i++) {
    float t = i / (float) steps;
    fill(lerpColor(edge, mid, t));
    float dd = d * (1 - 0.7f * t);
    ellipse(cx, cy, dd, dd);
  }
}

void leftArrow(float x, float y, float w, float h) {
  float hw = w * 0.4f;
  beginShape();
  vertex(x, y + h / 2);
  vertex(x + hw, y);
  vertex(x + hw, y + h * 0.25f);
  vertex(x + w, y + h * 0.25f);
  vertex(x + w, y + h * 0.75f);
  vertex(x + hw, y + h * 0.75f);
  vertex(x + hw, y + h);
  endShape(CLOSE);
}

void rightArrow(float x, float y, float w, float h) {
  float hw = w * 0.4f;
  beginShape();
  vertex(x + w, y + h / 2);
  vertex(x + w - hw, y + h);
  vertex(x + w - hw, y + h * 0.75f);
  vertex(x, y + h * 0.75f);
  vertex(x, y + h * 0.25f);
  vertex(x + w - hw, y + h * 0.25f);
  vertex(x + w - hw, y);
  endShape(CLOSE);
}

String formatTime(float seconds) {
  int m = floor(seconds / 60);
  int s = floor(seconds % 60);
  return m + ":" + (s < 10 ? "0" : "") + s;
}

String formatHMS(int totalSeconds) {
  int hrs = totalSeconds / 3600;
  int mins = (totalSeconds % 3600) / 60;
  int secs = totalSeconds % 60;
  return nf(hrs, 2) + ":" + nf(mins, 2) + ":" + nf(secs, 2);
}
