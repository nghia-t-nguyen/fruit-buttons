import processing.serial.*;
import processing.video.*;
import processing.sound.*;
import com.barneycodes.spicytext.*;

// Global variables
Serial myPort;
SoundFile backgroundMusic, incorrectSound, correctSound;
PFont boldFont;

// SpicyText objects and themes
SpicyText titleText, hintText, funFactText; 
SpicyTextTheme titleTheme, hintTheme, funFactTheme; 

// Game State Management
Animal currentAnimal;
boolean isVideoPlaying = false;

// Incorrect State Management
String incorrectAnswer = "[EFFECT=BOUNCE]Hmm[END_EFFECT]...I think I'd like something else please!";
boolean showingIncorrect = false;
int incorrectStartTime = 0;
final int INCORRECT_DURATION = 3000; // Reduced to 3 seconds for better flow

// Animal class
class Animal {
  PImage photo;
  Movie video;
  String title;
  String hint;
  String funFact; 
  char keyInput;
  char serialInput;
  Animal next;
  
  Animal(PApplet p, String imgPath, String vidPath, String t, String h, String f, char k, char s) {
    this.photo = p.loadImage(imgPath);
    this.video = new Movie(p, vidPath);
    this.title = t;
    this.hint = h;
    this.funFact = f; 
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

  // Theme for the fun fact box
  funFactTheme = new SpicyTextTheme();
  funFactTheme.textBackgroundMargin = 40;
  funFactTheme.textColour = 255;
  funFactTheme.cornerRadius = 20; 

  // 3. Create Animals
  Animal toucan = new Animal(this, "toucan.jpg", "toucan.mp4", 
    "[BACKGROUND=#FF7499FA]Mr. Toucan[END_BACKGROUND]", 
    "I like to eat fruits that are small, [COLOUR=#FF7499FA]blue[END_COLOUR] and round. What should I eat?", 
    "Toucans use their large beaks to reach berries on branches that are too weak to support their weight. Once they have the berries, they toss it back to swallow it whole.",
    'a', '1');

  Animal capybara = new Animal(this, "capybara.jpg", "capybara.mp4", 
    "[BACKGROUND=#FFFF9E00]Mrs. Capybara[END_BACKGROUND]", 
    "I like to eat fruits that are soft, [COLOUR=#FFFC5252]red[END_COLOUR] and refreshing. What should I eat?", 
    "Capybaras usually eat grass, but they love watermelon as a special treat! It is sweet and juicy. They only eat it sometimes because it has a lot of sugar.",
    's', '2');

  Animal tortoise = new Animal(this, "tortoise.jpg", "tortoise.mp4", 
    "[BACKGROUND=#FFFC5252]Mr. Tortoise[END_BACKGROUND]", 
    "I like to eat fruits that are round, [COLOUR=#FFFF9E00]orange[END_COLOUR] and football-shaped. What should I eat?", 
    "Tortoises dont have teeth! They use their sharp beaks to chop up the soft, sticky papaya like a pair of scissors.", 
    'd', '3');
    
  // 4. Link Animals
  toucan.next = capybara;
  capybara.next = tortoise;
  tortoise.next = toucan;

  // 5. Start Game
  currentAnimal = toucan;
  
  // Init text objects
  titleText = new SpicyText(this, currentAnimal.title, 50, titleTheme);
  hintText = new SpicyText(this, currentAnimal.hint, 40, width-300, hintTheme);
  
  // Init Fun Fact Text (Dynamic width to fit inside the box)
  funFactText = new SpicyText(this, "", 30,  width-350, funFactTheme);

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
  drawUIBox(); // Helper function

  // Draw Text
  hintText.draw(width/2, height-height/7, CENTER, CENTER);
  titleText.draw(80, height-240);
  
  // Draw Timer if incorrect
  if (showingIncorrect) {
    float elapsed = millis() - incorrectStartTime;
    float remaining = INCORRECT_DURATION - elapsed;
    drawTimerRing(remaining, INCORRECT_DURATION);
  }
}

void playVideoState() {
  if (currentAnimal.video.available()) {
    currentAnimal.video.read();
  }
  image(currentAnimal.video, 0, 0, width, height);
  drawUIBox(); // Helper function
  
  // Draw Text
  funFactText.draw(width/2, height-height/7, CENTER, CENTER);
  titleText.draw(80, height-240);
  
  // Draw Video Timer
  float remaining = currentAnimal.video.duration() - currentAnimal.video.time();
  drawTimerRing(remaining, currentAnimal.video.duration());

  // Check if video finished
  if (currentAnimal.video.time() >= currentAnimal.video.duration() - 0.05) {
    finishVideo();
  }
}

// --- HELPER FUNCTIONS ---

void drawUIBox() {
  pushStyle();
  rectMode(CENTER);
  fill(#E6664C36);
  stroke(#331C08);
  strokeWeight(16);
  rect(width/2, height-height/7, width-200, height/5, 20);
  popStyle();
}

// Draws the countdown ring in the bottom-right corner of the box
void drawTimerRing(float remainingTime, float totalTime) {
  if (remainingTime < 0) remainingTime = 0;
  
  // Calculate Box Dimensions
  float boxCenterY = height - height/7;
  float boxHeight = height/5;
  
  // Calculate corners
  float boxBottomEdge = boxCenterY + (boxHeight / 2);
  float boxRightEdge = width - 100; // Since box width is width-200, right edge is width-100

  // Timer Settings
  float timerSize = 40; 
  float padding = 35;   
  
  float timerX = boxRightEdge - padding;
  float timerY = boxBottomEdge - padding;
  
  float angle = map(remainingTime, 0, totalTime, 0, TWO_PI);
  
  pushStyle();
  noFill();
  strokeWeight(5);
  strokeCap(ROUND);
  
  // Background ring
  stroke(255, 50); 
  ellipse(timerX, timerY, timerSize, timerSize);
  
  // Active ring
  stroke(255); 
  arc(timerX, timerY, timerSize, timerSize, -HALF_PI, -HALF_PI + angle);
  
  popStyle();
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

// =============== INPUT HANDLERS =================

void handleInput(char inputChar) {
  // Debug info
  println("Key pressed: " + inputChar);

  // If video is already playing or incorrect message is showing, ignore input
  if (isVideoPlaying || showingIncorrect) return;

  // Check if input matches current animal's keys
  if (inputChar == currentAnimal.keyInput || inputChar == Character.toUpperCase(currentAnimal.keyInput) || inputChar == currentAnimal.serialInput) {
    // Correct!
    correctSound.play();
    
    // Update Fun Fact Text immediately before video plays
    funFactText.setText(currentAnimal.funFact);
    
    currentAnimal.video.play();
    isVideoPlaying = true;
    
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

// trigger incorrect
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
