import processing.sound.*;

// =========================================================================
// PART 1: CORE VARIABLES & SETUP
// =========================================================================
SoundFile track;
boolean isPlaying = false;
boolean isMuted = false;
float currentVolume = 0.8f; // Volume Range: 0.0 to 1.0
float storedVolume = 0.8f;  // Caches volume before a mute

// Operational Looping Logic State Registers
int loopMode = 0; // 0 = standard, 1 = repeat 1x, 2 = continuous infinite, 3 = target amount
int customLoopTarget = 1;
int loopsRemaining = 0;
boolean wasPlayingLastFrame = false;

// Layout Grid Canvas Scalars
float sliderX = 35, sliderY = 490, sliderW = 290;

void setup() {
  size(360, 680);
  surface.setTitle("Advanced Spotify-ish Engine");
  
  // Audio Content Stream Payload Engine
  try {
    track = new SoundFile(this, "music.mp3");
    track.amp(currentVolume);
  } catch (Exception e) {
    println("File read failure. Please check that music.mp3 exists inside the /data/ folder.");
  }
}

// =========================================================================
// PART 2: THE DESIGN LAYOUT (Top, Middle, and Bottom)
// =========================================================================
void draw() {
  background(18, 18, 18); // Deep Spotify Dark Background
  
  // ------------------------------------------
  // A. TOP ELEMENT: Artist & Track Info Rectangle 
  // ------------------------------------------
  fill(32, 32, 32); // Slate gray banner card
  noStroke();
  rect(20, 20, 320, 70, 8); // Rectangle profile with 8px rounded corners
  
  // Circular Portrait Profile Frame Placeholder inside the banner
  fill(29, 185, 84); // Vibrant green accent ring color context
  ellipse(55, 55, 46, 46); // Centered circular headshot circle frame
  
  fill(255); 
  textAlign(CENTER, CENTER);
  textSize(18);
  text("A", 55, 53); // Central text thumbnail graphic character
  
  // Metadata Text Layer (Track Identity Rules)
  textAlign(LEFT, CENTER); // Switch to left alignment grid for texts
  textSize(15);
  text("Track: Independent Single", 92, 45); 
  
  fill(179, 179, 179); // Muted lower contrast gray
  textSize(12);
  text("Artist: Independent Creator", 92, 65);

  // ------------------------------------------
  // B. CENTER ELEMENT: Large Album Artwork Square
  // ------------------------------------------
  fill(40, 40, 40); // Charcoal gray background card color
  rect(35, 120, 290, 290, 12); // Outer art block frame with 12px rounded corners
  
  // Inner Accent Glow Layer
  fill(29, 185, 84, 40); // Translucent Spotify Green tint (40% alpha)
  rect(55, 140, 250, 250, 8); // Floating accent card frame
  
  fill(255); // White icon color
  textSize(54); 
  textAlign(CENTER, CENTER); 
  text("🎵", 180, 260); // Centered placeholder music glyph

  // ------------------------------------------
  // C. BOTTOM ELEMENT: The 14 Dashboard Assets
  // ------------------------------------------
  
  // -- Timeline Slider Bar & Timestamps --
  stroke(60, 60, 60);
  strokeWeight(4);
  line(sliderX, sliderY, sliderX + sliderW, sliderY); // Background Track Line
  
  float progressPercent = 0;
  if (track != null && track.duration() > 0) {
    progressPercent = track.currentTime() / track.duration();
    float thumbX = sliderX + (progressPercent * sliderW);
    
    stroke(29, 185, 84); // Active Playback Green Line
    line(sliderX, sliderY, thumbX, sliderY);
    
    noStroke();
    fill(255);
    ellipse(thumbX, sliderY, 10, 10); // Handle scrubbing point
    
    // Live Text Timestamp Renderings
    fill(179, 179, 179);
    textSize(11);
    textAlign(LEFT, CENTER);
    text(formatTime(track.currentTime()), sliderX, sliderY + 14);
    textAlign(RIGHT, CENTER);
    text(formatTime(track.duration()), sliderX + sliderW, sliderY + 14);
  }

  // Automates native looping functions behind the scenes
  checkLoopTracking();

  // -- ROW 1: Principal Audio Control Buttons (Y = 540) --
  drawControlBtn(40, 540, 30, 20, "⏮", "Reset");
  drawControlBtn(85, 540, 30, 20, "◀◀", "Prev");
  drawControlBtn(130, 540, 30, 20, "⬛", "Stop");
  
  // Core Circular Master Action Toggle Button (Play/Pause)
  noStroke();
  if (isPlaying) {
    fill(255); // White pause circle layout
    ellipse(180, 550, 44, 44);
    fill(18, 18, 18);
    rect(174, 540, 4, 20, 2);
    rect(182, 540, 4, 20, 2);
  } else {
    fill(29, 185, 84); // Green play circle layout
    ellipse(180, 550, 44, 44);
    fill(255);
    triangle(176, 540, 176, 560, 189, 550);
  }
  
  drawControlBtn(215, 540, 30, 20, "▶▶", "Next");
  drawControlBtn(260, 540, 30, 20, "⏭", "FF");

  // -- ROW 2: Advanced Loop Rules and Volume Panel Assets (Y = 600) --
  int loop1Color = (loopMode == 1) ? color(29, 185, 84) : color(120);
  int loopInfColor = (loopMode == 2) ? color(29, 185, 84) : color(120);
  int loopAmtColor = (loopMode == 3) ? color(29, 185, 84) : color(120);
  
  drawCustomTintBtn(40, 600, 35, 20, "🔂", loop1Color);
  drawCustomTintBtn(90, 600, 35, 20, "🔁", loopInfColor);
  drawCustomTintBtn(140, 600, 45, 20, "Loop:" + customLoopTarget, loopAmtColor);

  // Volume Action Assets Rendering Setup
  int muteColor = isMuted ? color(239, 68, 68) : color(120);
  drawCustomTintBtn(210, 600, 30, 20, "🔇", muteColor);
  drawControlBtn(250, 600, 30, 20, "🔉", "Vol Down");
  drawControlBtn(290, 600, 30, 20, "🔊", "Vol Up");
  
  // Volume bar value meter indicator
  fill(60);
  rect(210, 635, 110, 4, 2);
  fill(isMuted ? 100 : 255);
  rect(210, 635, 110 * (isMuted ? 0 : currentVolume), 4, 2);
}

// =========================================================================
// PART 3: THE PHYSICAL ACTIONS (Mouse Clicks & Hover Hue Math Engines)
// =========================================================================
void mousePressed() {
  if (track == null) return;

  // Timeline Slider Click-To-Seek Logic
  if (mouseX >= sliderX && mouseX <= sliderX + sliderW && mouseY >= sliderY - 10 && mouseY <= sliderY + 10) {
    float clickRatio = (mouseX - sliderX) / sliderW;
    track.jump(clickRatio * track.duration());
  }

  // Row 1 Button Trigger Evaluations
  if (checkClick(40, 540, 30, 20)) { // Fast Reset (⏮)
    track.jump(0);
  }
  else if (checkClick(85, 540, 30, 20)) { // Previous Track (◀◀)
    track.jump(0);
  }
  else if (checkClick(130, 540, 30, 20)) { // Stop (⬛)
    track.stop();
    isPlaying = false;
  }
  else if (dist(mouseX, mouseY, 180, 550) < 22) { // Center Play/Pause Circle
    if (isPlaying) {
      track.pause();
      isPlaying = false;
    } else {
      track.play();
      isPlaying = true;
    }
  }
  else if (checkClick(215, 540, 30, 20)) { // Next Track Mock Button (▶▶)
    track.jump(0);
  }
  else if (checkClick(260, 540, 30, 20)) { // Fast Forward 5 Seconds (⏭)
    float targetTime = min(track.currentTime() + 5.0f, track.duration() - 0.5f);
    track.jump(targetTime);
  }

  // Row 2 Button Trigger Evaluations
  else if (checkClick(40, 600, 35, 20)) { // Loop 1 Time (🔂)
    loopMode = (loopMode == 1) ? 0 : 1;
    loopsRemaining = (loopMode == 1) ? 1 : 0;
  }
  else if (checkClick(90, 600, 35, 20)) { // Loop Infinitely (🔁)
    loopMode = (loopMode == 2) ? 0 : 2;
  }
  else if (checkClick(140, 600, 45, 20)) { // Set Custom Loop Target Amount (Loop:X)
    if (loopMode == 3) {
      customLoopTarget = (customLoopTarget % 5) + 1; // Rotates loop limit between 1 and 5
      loopsRemaining = customLoopTarget;
    } else {
      loopMode = 3;
      loopsRemaining = customLoopTarget;
    }
  }
  else if (checkClick(210, 600, 30, 20)) { // Master Mute Toggle (🔇)
    isMuted = !isMuted;
    if (isMuted) {
      storedVolume = currentVolume;
      track.amp(0);
    } else {
      currentVolume = storedVolume;
      track.amp(currentVolume);
    }
  }
  else if (checkClick(250, 600, 30, 20)) { // Volume Down (🔉)
    isMuted = false;
    currentVolume = max(currentVolume - 0.1f, 0.0f);
    track.amp(currentVolume);
  }
  else if (checkClick(290, 600, 30, 20)) { // Volume Up (🔊)
    isMuted = false;
    currentVolume = min(currentVolume + 0.1f, 1.0f);
    track.amp(currentVolume);
  }
}

// Custom UI Button Core Renderer
void drawControlBtn(float x, float y, float w, float h, String symbol, String label) {
  int normalColor = color(180); // Soft grey icons by default
  
  // DYNAMIC HOVER HUE DETECTOR
  if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) {
    if (symbol.equals("⬛") || symbol.equals("🔇")) {
      normalColor = color(239, 68, 68); // Changes hue to a warm RED if hovering over Stop/Mute
    } else {
      normalColor = color(29, 185, 84);  // Changes hue to SPOTIFY GREEN for all other controls
    }
  }
  drawCustomTintBtn(x, y, w, h, symbol, normalColor);
}

void drawCustomTintBtn(float x, float y, float w, float h, String symbol, int textColor) {
  fill(28, 28, 28); 
  if (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h) {
    fill(40); // Button container dims slightly on hover
    if (symbol.equals("🔂") || symbol.equals("🔁") || symbol.startsWith("Loop:")) {
       textColor = color(29, 185, 84); // Forces green text hue hover feedback loop
    }
    if (symbol.equals("🔇") && isMuted) {
       textColor = color(239, 68, 68); // Keeps red warning hue active
    }
  }
  rect(x, y, w, h, 6);
  fill(textColor);
  textSize(12);
  textAlign(CENTER, CENTER);
  text(symbol, x + (w/2), y + (h/2) - 1);
}

boolean checkClick(float x, float y, float w, float h) {
  return (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h);
}

String formatTime(float seconds) {
  int m = floor(seconds / 60);
  int s = floor(seconds % 60);
  return m + ":" + (s < 10 ? "0" : "") + s;
}

void checkLoopTracking() {
  if (track == null) return;
  boolean isPlayingThisFrame = track.isPlaying();
  
  if (wasPlayingLastFrame && !isPlayingThisFrame && isPlaying) {
    if (loopMode == 1) { 
      track.play();
      loopMode = 0; 
    } 
    else if (loopMode == 2) { 
