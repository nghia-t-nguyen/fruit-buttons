import processing.serial.*;
import processing.video.*;
import processing.sound.*;
import com.barneycodes.spicytext.*;

// --- GLOBAL VARIABLES ---
Serial myPort;
SoundFile backgroundMusic, incorrectSound, correctSound;
PFont boldFont;

// SpicyText objects and themes
SpicyText titleText, hintText;
SpicyTextTheme titleTheme, hintTheme;

// Game State Management
Animal currentAnimal;
boolean isVideoPlaying = false;

// Incorrect State Management
String incorrectAnswer = "[EFFECT=BOUNCE]Hmm[END_EFFECT]...I think I'd like something else please!";
boolean showingIncorrect = false;
int incorrectStartTime = 0;
final int INCORRECT_DURATION = 3000; 

// --- ANIMAL CLASS ---
class Animal {
  PImage photo;
  Movie video;
  String title;
  String hint;
  char keyInput;    // Keyboard key (a, s, d)
  char serialInput; // Serial input (1, 2, 3)
  Animal next;      // Pointer to the next animal
  
  Animal(PApplet p, String imgPath, String vidPath, String t, String h, char k, char s) {
    this.photo = p.loadImage(imgPath);
    this.video = new Movie(p, vidPath);
    this.title = t;
    this.hint = h;
    this.keyInput = k;
    this.serialInput = s;
  }
}

void setup() {
  fullScreen(JAVA2D);
  pixelDensity(1);
  noCursor();
  frameRate(30);

  // 1. Initialize Assets
  boldFont = createFont("Arial Bold", 128);
  incorrectSound = new SoundFile(this, "incorrect.mp3");
  correctSound = new SoundFile(this, "correct.mp3");
  backgroundMusic = new SoundFile(this, "tropicalMusic.mp3");
  backgroundMusic.loop();
  backgroundMusic.amp(0.3);

  // 2. Initialize SpicyText Styles
  titleTheme = new SpicyTextTheme();
  titleTheme.textBackgroundMargin = 20; 
  titleTheme.cornerRadius = 20; 
  
  hintTheme = new SpicyTextTheme();
  hintTheme.textBackgroundMargin = 80;
  hintTheme.textColour = 255;
  hintTheme.cornerRadius = 20; 

  // 3. Create Animals
  Animal toucan = new Animal(this, "toucan.jpg", "toucan.mp4", 
    "[BACKGROUND=#FF7499FA]Mr. Toucan[END_BACKGROUND]", 
    "I like to eat fruits that are small, [COLOUR=#FF7499FA]blue[END_COLOUR] and round. What should I eat?", 
    'a', '1');

  Animal capybara = new Animal(this, "capybara.jpg", "capybara.mp4", 
    "[BACKGROUND=#FFFF9E00]Mrs. Capybara[END_BACKGROUND]", 
    "I like to eat fruits that are round, [COLOUR=#FFFF9E00]orange[END_COLOUR] and football-shaped. What should I eat?", 
    's', '2');

  Animal tortoise = new Animal(this, "tortoise.jpg", "tortoise.mp4", 
    "[BACKGROUND=#FFFC5252]Mr. Tortoise[END_BACKGROUND]", 
    "I like to eat fruits that are soft, [COLOUR=#FFFC5252]red[END_COLOUR] and refreshing. What should I eat?", 
    'd', '3');

  // 4. Link Animals (Loop)
  toucan.next = capybara;
  capybara.next = tortoise;
  tortoise.next = toucan;

  // 5. Start Game
  currentAnimal = toucan;
  
  // Init text objects
  titleText = new SpicyText(this, currentAnimal.title, 50, titleTheme);
  hintText = new SpicyText(this, currentAnimal.hint, 40, width-300, hintTheme);

  // Initialize Serial
  // printArray(Serial.list());
  // String portName = Serial.list()[0]; 
  // myPort = new Serial(this, portName, 9600);
  // myPort.bufferUntil('\n'); 
}

void draw() {
  background(0);

  if (isVideoPlaying) {
    playVideoState();
  } else {
    showImageState();
  }

  // Handle incorrect message timer
  if (showingIncorrect && millis() - incorrectStartTime >= INCORRECT_DURATION) {
    showingIncorrect = false;
    hintText.setText(currentAnimal.hint); // Restore hint
  }
}

// --- STATE FUNCTIONS ---

void showImageState() {
  displayAnimal(currentAnimal.photo);
  
  // UI Box
  pushStyle();
  rectMode(CENTER);
  fill(#E6664C36);
  stroke(#331C08);
  strokeWeight(16);
  rect(width/2, height-height/7, width-200, height/5, 20);
  popStyle();

  // Draw Text
  hintText.draw(width/2, height-height/7, CENTER, CENTER);
  titleText.draw(80, height-240);
}

void playVideoState() {
  if (currentAnimal.video.available()) {
    currentAnimal.video.read();
  }
  image(currentAnimal.video, 0, 0, width, height);

  // "Correct!" Overlay
  fill(154, 205, 50); 
  textFont(boldFont);
  textAlign(CENTER, CENTER);
  text("Correct!", width/2, height - 120);

  // Check if video finished
  if (currentAnimal.video.time() >= currentAnimal.video.duration() - 0.05) {
    finishVideo();
  }
}

void finishVideo() {
  // Stop current video
  currentAnimal.video.stop();
  currentAnimal.video.jump(0);
  
  // Switch to next animal
  currentAnimal = currentAnimal.next;
  
  // Update text for next animal
  titleText.setText(currentAnimal.title);
  hintText.setText(currentAnimal.hint);
  
  isVideoPlaying = false;
}

// --- INPUT HANDLING ---

void handleInput(char inputChar) {
  // If video is already playing or incorrect message is showing, ignore input
  if (isVideoPlaying || showingIncorrect) return;

  // Check if input matches current animal's keys
  if (inputChar == currentAnimal.keyInput || inputChar == Character.toUpperCase(currentAnimal.keyInput) || inputChar == currentAnimal.serialInput) {
    // Correct!
    correctSound.play();
    currentAnimal.video.loop();
    isVideoPlaying = true;
    
    // While video plays, pre-set the hint text for the *next* animal 
    // (Or you can wait until finishVideo to update text, simpler to wait)
    
  } else {
    // Incorrect!
    triggerIncorrect();
  }
}

void keyPressed() {
  handleInput(key);
}

void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil('\n');
  if (inString != null) {
    inString = trim(inString);
    if (inString.length() > 0) {
      handleInput(inString.charAt(0));
    }
  }
}

// --- HELPERS ---

void triggerIncorrect() {
  if (!showingIncorrect) {
    showingIncorrect = true;
    incorrectStartTime = millis();
    incorrectSound.play();
    hintText.setText(incorrectAnswer);
  }
}

void displayAnimal(PImage animalPhoto) {
  imageMode(CENTER);
  float imgAspect = (float) animalPhoto.width / animalPhoto.height;
  float windowAspect = (float)width / height;
  
  if (imgAspect < windowAspect) {
    image(animalPhoto, width/2, height/2, width, width / imgAspect);
  } else {
    image(animalPhoto, width/2, height/2, height * imgAspect, height);
  }
  imageMode(CORNER);
}
