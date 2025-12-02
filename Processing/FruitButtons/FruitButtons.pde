import processing.serial.*;
import processing.video.*;
import processing.sound.*;
import com.barneycodes.spicytext.*;

// Global variables
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
final int INCORRECT_DURATION = 5000; 

// Animal class
class Animal {
  PImage photo; // photo of the animal
  Movie video; // video of animal if user is correct
  String title; // titular name for the animal
  String hint; // hint of the fruit the animal eats
  char keyInput; // keyboard input for testing purposes
  char serialInput; // serial input for integration with Arduino
  Animal next; // next animal to display after correct input
  
  // Constructor
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
  // set up screen and rendering
  fullScreen(JAVA2D);
  pixelDensity(1);
  noCursor();
  frameRate(30);

  // 1. Initialize assets
  // Load in sound fx
  incorrectSound = new SoundFile(this, "incorrect.mp3");
  correctSound = new SoundFile(this, "correct.mp3");
  // Load in music
  backgroundMusic = new SoundFile(this, "tropicalMusic.mp3");
  backgroundMusic.loop();
  backgroundMusic.amp(0.3); // set volume

  // 2. Initialize SpicyText styles and theme
  // Theme for animal titles
  titleTheme = new SpicyTextTheme();
  titleTheme.textBackgroundMargin = 20; 
  titleTheme.cornerRadius = 20; 
  
  // Theme for hints
  hintTheme = new SpicyTextTheme();
  hintTheme.textBackgroundMargin = 80;
  hintTheme.textColour = 255;
  hintTheme.cornerRadius = 20; 

  // 3. Create animals with class constructors
  // Toucan
  Animal toucan = new Animal(this, "toucan.jpg", "toucan.mp4", 
    "[BACKGROUND=#FF7499FA]Mr. Toucan[END_BACKGROUND]", 
    "I like to eat fruits that are small, [COLOUR=#FF7499FA]blue[END_COLOUR] and round. What should I eat?", 
    'a', '1');

  // Capybara
  Animal capybara = new Animal(this, "capybara.jpg", "capybara.mp4", 
    "[BACKGROUND=#FFFF9E00]Mrs. Capybara[END_BACKGROUND]", 
    "I like to eat fruits that are soft, [COLOUR=#FFFC5252]red[END_COLOUR] and refreshing. What should I eat?", 
    's', '2');

  // Tortoise
  Animal tortoise = new Animal(this, "tortoise.jpg", "tortoise.mp4", 
    "[BACKGROUND=#FFFC5252]Mr. Tortoise[END_BACKGROUND]", 
    "I like to eat fruits that are round, [COLOUR=#FFFF9E00]orange[END_COLOUR] and football-shaped. What should I eat?", 
    'd', '3');

  // 4. link Animals (Loop)
  toucan.next = capybara;
  capybara.next = tortoise;
  tortoise.next = toucan;

  // 5. start Game
  currentAnimal = toucan;
  
  // init text objects
  titleText = new SpicyText(this, currentAnimal.title, 50, titleTheme);
  hintText = new SpicyText(this, currentAnimal.hint, 40, width-300, hintTheme);

  // initialize serial
  printArray(Serial.list()); // print to check
  String portName = Serial.list()[0]; 
  myPort = new Serial(this, portName, 9600);
  myPort.bufferUntil('\n'); 
}

void draw() {
  background(0); // clear screen with black background

  // display the appropriate display state
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

// =============== STATE RELATED FUNCTIONS =================
// show animal image for the current animal state
void showImageState() {
  displayAnimal(currentAnimal.photo); // use the helper function to display animal
  
  // UI backdrop box
  pushStyle();
  rectMode(CENTER);
  fill(#E6664C36);
  stroke(#331C08);
  strokeWeight(16);
  rect(width/2, height-height/7, width-200, height/5, 20);
  popStyle();

  // Draw for hint and title
  hintText.draw(width/2, height-height/7, CENTER, CENTER);
  titleText.draw(80, height-240);
}

// plays video for the animal at the current state
void playVideoState() {
  if (currentAnimal.video.available()) {
    currentAnimal.video.read();
  }
  image(currentAnimal.video, 0, 0, width, height); // display video

  // Check if video finished
  if (currentAnimal.video.time() >= currentAnimal.video.duration() - 0.05) {
    finishVideo();
  }
}

// handles states when the video is finished
void finishVideo() {
  // Stop current video
  currentAnimal.video.stop();
  currentAnimal.video.jump(0);
  
  // Switch to next animal
  currentAnimal = currentAnimal.next;
  
  // Update text for next animal
  titleText.setText(currentAnimal.title);
  hintText.setText(currentAnimal.hint);
  
  // Set boolean flag
  isVideoPlaying = false;
}

// =============== INPUT HANDLERS =================
void handleInput(char inputChar) {
  // If video is already playing or incorrect message is showing, ignore input
  if (isVideoPlaying || showingIncorrect) return;

  // Check if input matches current animal's key input
  if (inputChar == currentAnimal.keyInput || inputChar == Character.toUpperCase(currentAnimal.keyInput) || inputChar == currentAnimal.serialInput) {
    // Correct
    correctSound.play();
    currentAnimal.video.play();
    isVideoPlaying = true;
  } else {
    // Incorrect
    triggerIncorrect();
  }
}

void keyPressed() {
  handleInput(key);
}

// handles Serial input from arduino
void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil('\n'); // read the string
  if (inString != null) {
    inString = trim(inString); // format the string
    if (inString.length() > 0) {
      handleInput(inString.charAt(0)); // handle the input from read character
    }
  }
}

// =============== HELPER FUNCTIONS =================
// handles logic and output when incorrect is triggered
void triggerIncorrect() {
  if (!showingIncorrect) {
    showingIncorrect = true; // display boolean to true
    incorrectStartTime = millis(); // start timer for incorrect
    incorrectSound.play(); // play a sound
    hintText.setText(incorrectAnswer); // set the text for the hint
  }
}

// displays photo of the animal
void displayAnimal(PImage animalPhoto) {
  imageMode(CENTER); // position image in center
  // Calculate the aspect ratios to use to scale the images properly
  float imgAspect = (float) animalPhoto.width / animalPhoto.height;
  float windowAspect = (float)width / height;
  
  // this makes sure that the image is "object-fit: cover"
  if (imgAspect < windowAspect) {
    image(animalPhoto, width/2, height/2, width, width / imgAspect);
  } else {
    image(animalPhoto, width/2, height/2, height * imgAspect, height);
  }
  imageMode(CORNER); // reset mode
}
