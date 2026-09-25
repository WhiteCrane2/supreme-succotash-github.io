import processing.sound.*;

// Core Audio Engine State Variables
SoundFile track;
boolean isPlaying = false;
boolean isMuted = false;
float currentVolume = 0.8f; // Range: 0.0 to 1.0
float storedVolume = 0.8f;  // Restores level after unmuting

// Operational Looping Logic State Registers
int loopMode = 0; // 0 = standard, 1 = repeat 1x, 2 = continuous infinite, 3 = variable target
int customLoopTarget = 1;
int loopsRemaining = 0;
boolean wasPlayingLastFrame = false;

// Layout Grid Canvas Scalars
int winW = 360, winH = 680;
float sliderX = 35, sliderY = 490, sliderW = 290;

void setup() {
  size(360, 680);
  surface.setTitle("Advanced Spotify-ish Engine");
  
  // Audio Content Stream Payload Engine
  try {
    // Drop your background file track directly inside the sketch's /data/ directory
    track = new SoundFile(this, "music.mp3");
    track.amp(currentVolume);
  } catch (Exception e) {
    println("File read failure. Please check that music.mp3 exists inside the /data/ folder.");
  }
}

void draw() {
  background(18, 18, 18); // Deep Spotify Dark Background
  
  // ==========================================
  // 1. TOP ELEMENT: Artist & Track Info Rectangle 
  // ==========================================
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

  // ==========================================
  // 2. CENTER ELEMENT: Large Album Artwork Square
  // ==========================================
  fill(40, 40, 40); // Charcoal gray background card color
  rect(35, 120, 290, 290, 12); // Outer art block frame with 12px rounded corners
  
  // Inner Accent Glow Layer
  fill(29, 185, 84, 40); // Translucent Spotify Green tint (40% alpha)
  rect(55, 140, 250, 250, 8); // Floating accent card frame
  
  fill(255); // White icon color
  textSize(54); 
  textAlign(CENTER, CENTER); 
  text("🎵", 180, 260); // Centered placeholder music glyph

  // ==========================================
  // 3. BOTTOM ELEMENT: The 14 Dashboard Assets
  // ==========================================
  
  // -- A. Timeline Slider Bar & Timestamps --
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

  // -- B. ROW 1: Principal Audio Control Buttons (Y = 540) --
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

  // -- C. ROW 2: Advanced Loop Rules and Volume Panel Assets (Y = 600) --
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
