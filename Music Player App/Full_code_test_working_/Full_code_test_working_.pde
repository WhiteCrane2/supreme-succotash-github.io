import processing.core.PApplet;
import processing.sound.*;

// =========================================================================
// Advanced Spotify-ish Engine — plain Java class (extends PApplet)
// =========================================================================
public class Full_code_test_working extends PApplet {

  SoundFile track;
  boolean isPlaying = false;
  boolean isMuted = false;
  float currentVolume = 0.8f;
  float storedVolume = 0.8f;

  int loopMode = 0;
  int customLoopTarget = 1;
  int loopsRemaining = 0;

  float sliderX = 35, sliderY = 490, sliderW = 290;

  public static void main(String[] args) {
    PApplet.main("Full_code_test_working");
  }

  public void settings() {
    size(360, 680);
  }

  public void setup() {
    surface.setTitle("Advanced Spotify-ish Engine");

    try {
      track = new SoundFile(this, "music.mp3");
      if (track != null) {
        track.amp(currentVolume);
      }
    } catch (Exception e) {
      println("Audio device or file read delay registered. Continuing in safe mode...");
    }
  }

  // =========================================================================
  // THE DESIGN CANVAS LAYOUT
  // =========================================================================
  public void draw() {
    background(18, 18, 18);

    // -- A. TOP ELEMENT: Artist Banner Rectangle --
    fill(32, 32, 32);
    noStroke();
    rect(20, 20, 320, 70, 8);
    fill(29, 185, 84);
    ellipse(55, 55, 46, 46);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(18);
    text("A", 55, 53);
    textAlign(LEFT, CENTER);
    textSize(15);
    text("Track: Independent Single", 92, 45);
    fill(179, 179, 179);
    textSize(12);
    text("Artist: Independent Creator", 92, 65);

    // -- B. CENTER ELEMENT: Album Art Square --
    fill(40, 40, 40);
    rect(35, 120, 290, 290, 12);
    fill(29, 185, 84, 40);
    rect(55, 140, 250, 250, 8);
    fill(255);
    textSize(20);
    textAlign(CENTER, CENTER);
    text("ALBUM COVER ART", 180, 260);

    // -- C. BOTTOM ELEMENT: Timeline & Dashboard Assets --
    stroke(60, 60, 60);
    strokeWeight(4);
    line(sliderX, sliderY, sliderX + sliderW, sliderY);

    float progressPercent = 0;

    if (track != null && isPlaying) {
      try {
        float d = track.duration();
        float pos = track.position();

        if (d > 0 && pos >= 0) {
          progressPercent = pos / d;
          float thumbX = sliderX + (progressPercent * sliderW);

          stroke(29, 185, 84);
          line(sliderX, sliderY, thumbX, sliderY);

          noStroke();
          fill(255);
          ellipse(thumbX, sliderY, 10, 10);

          fill(179, 179, 179);
          textSize(11);
          textAlign(LEFT, CENTER);
          text(formatTime(pos), sliderX, sliderY + 14);
          textAlign(RIGHT, CENTER);
          text(formatTime(d), sliderX + sliderW, sliderY + 14);
        } else {
          drawFallbackTimeline();
        }
      } catch (Exception e) {
        drawFallbackTimeline();
      }
    } else {
      drawFallbackTimeline();
    }

    checkLoopTracking();

    // Control Buttons Row 1 (Core Audio Controls)
    drawControlBtn(40, 540, 30, 20, "FR", "Reset");
    drawControlBtn(85, 540, 30, 20, "<-", "Prev");
    drawControlBtn(130, 540, 30, 20, "ST", "Stop");

    noStroke();
    if (isPlaying) {
      fill(255);
      ellipse(180, 550, 44, 44);
      fill(18, 18, 18);
      rect(174, 540, 4, 18, 2);
      rect(182, 540, 4, 18, 2);
    } else {
      fill(29, 185, 84);
      ellipse(180, 550, 44, 44);
      fill(255);
      triangle(176, 541, 176, 559, 188, 550);
    }

    drawControlBtn(215, 540, 30, 20, "->", "Next");
    drawControlBtn(260, 540, 30, 20, "FF", "FF");

    // Control Buttons Row 2 (Loops & Volume)
    int loop1Color = (loopMode == 1) ? color(29, 185, 84) : color(120);
    int loopInfColor = (loopMode == 2) ? color(29, 185, 84) : color(120);
    int loopAmtColor = (loopMode == 3) ? color(29, 185, 84) : color(120);

    drawCustomTintBtn(40, 600, 35, 20, "L1", loop1Color);
    drawCustomTintBtn(90, 600, 35, 20, "LI", loopInfColor);
    drawCustomTintBtn(140, 600, 45, 20, "Loop:" + customLoopTarget, loopAmtColor);

    int muteColor = isMuted ? color(239, 68, 68) : color(120);
    drawCustomTintBtn(210, 600, 30, 20, "MT", muteColor);
    drawControlBtn(250, 600, 30, 20, "V-", "Vol Down");
    drawControlBtn(290, 600, 30, 20, "V+", "Vol Up");

    fill(60);
    rect(210, 635, 110, 4, 2);
    fill(isMuted ? 100 : 255);
    rect(210, 635, 110 * (isMuted ? 0 : currentVolume), 4, 2);
  }

  void drawFallbackTimeline() {
    noStroke();
    fill(255);
    ellipse(sliderX, sliderY, 10, 10);
    fill(179, 179, 179);
    textSize(11);
    textAlign(LEFT, CENTER);
    text("0:00", sliderX, sliderY + 14);
    textAlign(RIGHT, CENTER);
    try {
      if (track != null && track.duration() > 0) {
        text(formatTime(track.duration()), sliderX + sliderW, sliderY + 14);
      } else {
        text("0:00", sliderX + sliderW, sliderY + 14);
      }
    } catch (Exception e) {
      text("0:00", sliderX + sliderW, sliderY + 14);
    }
  }

  // =========================================================================
  // INTERACTIONS & SYSTEMS LOGIC
  // =========================================================================
  public void mousePressed() {
    if (track == null) return;

    try {
      if (mouseX >= sliderX && mouseX <= sliderX + sliderW && mouseY >= sliderY - 10 && mouseY <= sliderY + 10) {
        if (track.duration() > 0) {
          float clickRatio = (mouseX - sliderX) / sliderW;
          track.jump(clickRatio * track.duration());
        }
      }
    } catch (Exception e) {}

    if (checkClick(40, 540, 30, 20)) { // FR
      try {
        track.jump(0);
      } catch (Exception e) {}
    } else if (checkClick(85, 540, 30, 20)) { // Previous (<-)
      try {
        track.jump(0);
      } catch (Exception e) {}
    } else if (checkClick(130, 540, 30, 20)) { // ST
      track.stop();
      isPlaying = false;
    } else if (dist(mouseX, mouseY, 180, 550) < 22) {
      if (isPlaying) {
        track.pause();
        isPlaying = false;
      } else {
        try {
          track.play();
          isPlaying = true;
        } catch (Exception e) {
          println("Connecting audio lines...");
        }
      }
    } else if (checkClick(215, 540, 30, 20)) { // Next (->)
      try {
        track.jump(0);
      } catch (Exception e) {}
    } else if (checkClick(260, 540, 30, 20)) { // FF
      try {
        if (track.duration() > 0) {
          float targetTime = min(track.position() + 5.0f, track.duration() - 0.5f);
          track.jump(targetTime);
        }
      } catch (Exception e) {}
    } else if (checkClick(40, 600, 35, 20)) { // L1
      loopMode = (loopMode == 1) ? 0 : 1;
      loopsRemaining = (loopMode == 1) ? 1 : 0;
    } else if (checkClick(90, 600, 35, 20)) { // LI
      loopMode = (loopMode == 2) ? 0 : 2;
    } else if (checkClick(140, 600, 45, 20)) {
      if (loopMode == 3) {
        customLoopTarget = (customLoopTarget % 5) + 1;
        loopsRemaining = customLoopTarget;
      } else {
        loopMode = 3;
        loopsRemaining = customLoopTarget;
      }
    } else if (checkClick(210, 600, 30, 20)) { // MT
      isMuted = !isMuted;
      if (isMuted) {
        storedVolume = currentVolume;
        track.amp(0);
      } else {
        currentVolume = storedVolume;
        track.amp(currentVolume);
      }
    } else if (checkClick(250, 600, 30, 20)) { // V-
      isMuted = false;
      currentVolume = max(currentVolume - 0.1f, 0.0f);
      track.amp(currentVolume);
    } else if (checkClick(290, 600, 30, 20)) { // V+
      isMuted = false;
      currentVolume = min(currentVolume + 0.1f, 1.0f);
      track.amp(currentVolume);
    }
  }

  void drawControlBtn(float x, float y, float w, float h, String symbol, String label) {
    int normalColor = color(180);
    if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) {
      if (symbol.equals("ST") || symbol.equals("MT")) {
        normalColor = color(239, 68, 68);
      } else {
        normalColor = color(29, 185, 84);
      }
    }
    drawCustomTintBtn(x, y, w, h, symbol, normalColor);
  }

  void drawCustomTintBtn(float x, float y, float w, float h, String symbol, int textColor) {
    fill(28, 28, 28);
    if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) {
      fill(40);
      if (symbol.equals("L1") || symbol.equals("LI") || symbol.startsWith("Loop:")) {
        textColor = color(29, 185, 84);
      }
      if (symbol.equals("MT") && isMuted) {
        textColor = color(239, 68, 68);
      }
    }
    rect(x, y, w, h, 6);
    fill(textColor);
    textSize(11);
    textAlign(CENTER, CENTER);
    text(symbol, x + (w / 2), y + (h / 2) - 1);
  }

  boolean checkClick(float x, float y, float w, float h) {
    return (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h);
  }

  String formatTime(float seconds) {
    int m = floor(seconds / 60);
    int s = floor(seconds % 60);
    return m + ":" + (s < 10 ? "0" : "") + s;
  }

  // Fixed: SoundFile has no isPlaying() method in the Processing Sound
  // library, so end-of-track is now detected by comparing position() to
  // duration() instead of relying on that nonexistent call.
  void checkLoopTracking() {
    if (track == null || !isPlaying) return;
    try {
      float d = track.duration();
      float pos = track.position();

      if (d > 0 && pos >= d - 0.05f) {
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
      }
    } catch (Exception e) {}
  }
}
