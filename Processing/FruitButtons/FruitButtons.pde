import processing.serial.*;
import processing.video.*;
import processing.sound.*;

Serial myPort;

// sound files
SoundFile backgroundMusic;
SoundFile incorrectSound;
SoundFile correctSound;

// video files
Movie toucanVideo;
Movie capybaraVideo;
Movie tortoiseVideo;

// init variables for default image
PImage toucanImage;
PImage capybaraImage;
PImage tortoiseImage;
//init variables for image when user is incorrect
PImage toucanImageIncorrect;
PImage capybaraImageIncorrect;
PImage tortoiseImageIncorrect;
PImage animalImage;
// booleans for which video is playing
boolean playingToucanVideo = false;
boolean playingCapybaraVideo = false;
boolean playingTortoiseVideo = false;

// game states
final int STATE_SHOW_TOUCAN = 1; // state that displays toucan image
final int STATE_PLAY_TOUCAN = 2; // state when toucan video is playing
final int STATE_SHOW_CAPYBARA = 3; // state that displays capybara image
final int STATE_PLAY_CAPYBARA = 4; // state when capybara video is playing
final int STATE_SHOW_TORTOISE = 5; // state that displays tortoise image
final int STATE_PLAY_TORTOISE = 6; // state when tortoise video is playing

// init state to start off with toucan
int state = STATE_SHOW_TOUCAN;

// for incorrect message
boolean showingIncorrect = false; // showing incorrect image flag used for timer
int incorrectStartTime = 0;
final int INCORRECT_DURATION = 3000; 
boolean incorrectTriggered = false; // flag to play incorrect sound only once

// font
PFont boldFont;

void setup() {
  pixelDensity(1);
  fullScreen(JAVA2D);
  noCursor(); // Hide cursor in fullscreen
  
  // Load the default images
  toucanImage = loadImage("toucan2.jpg");
  capybaraImage = loadImage("capybara2.jpg");
  tortoiseImage = loadImage("tortoise2.jpg");
  animalImage = toucanImage; // init the animalImage to the toucan
  
  // Load the images when user is incorrect
  toucanImageIncorrect = loadImage("toucan3.jpg");
  capybaraImageIncorrect = loadImage("capybara3.jpg");
  tortoiseImageIncorrect = loadImage("tortoise3.jpg");
  
  // Load video files
  toucanVideo = new Movie(this, "toucan.mp4");
  capybaraVideo = new Movie(this, "capybara.mp4");
  tortoiseVideo = new Movie(this, "tortoise.mp4");
  frameRate(30);
  
  boldFont = createFont("Arial Bold", 128); // set font
  
  // load music and sound files
  incorrectSound = new SoundFile(this, "incorrect.mp3");
  correctSound = new SoundFile(this, "correct.mp3");
  backgroundMusic = new SoundFile(this, "tropicalMusic.mp3");
  backgroundMusic.loop();  // Loop the music continuously
  backgroundMusic.amp(0.3);
  
  // Initialize Serial
  //String portName = Serial.list()[0]; // Use first available port
  //myPort = new Serial(this, portName, 9600); // Match Arduino
  //myPort.bufferUntil('\n'); // Buffer string until newline character
}

void draw() {
  background(0);
  
  if (state == STATE_SHOW_TOUCAN) {
    displayAnimal(animalImage); // display animal image (toucan)
    setIncorrectImage(toucanImageIncorrect, toucanImage); // changes to incorrect image if user is incorrect
  } else if (state == STATE_PLAY_TOUCAN) {
    // display toucan eating
    if (toucanVideo.available()) {
      toucanVideo.read();
    }
    image(toucanVideo, 0, 0, width, height);
    
    // display user is correct
    fill(154, 205, 50);  // Yellow-green
    textFont(boldFont);
    textAlign(CENTER, CENTER);
    text("Correct!", width/2, height - 120);
    if (toucanVideo.time() >= toucanVideo.duration() - 0.05) {   // if the video is over
      state = STATE_SHOW_CAPYBARA; // move on to next state
      resetVideo();
      animalImage = capybaraImage; // set image to capybara
      incorrectTriggered = false;// reset image to the original (correct) image
    }
  } else if (state == STATE_SHOW_CAPYBARA) {
    displayAnimal(animalImage); // display animal image (capybara)
    setIncorrectImage(capybaraImageIncorrect, capybaraImage); // changes to incorrect image if user is incorrect
  } else if (state == STATE_PLAY_CAPYBARA) {
    // display capybara eating
    if (capybaraVideo.available()) {
      capybaraVideo.read();
    }
    
    // display user is correct
    image(capybaraVideo, 0, 0, width, height);
    fill(154, 205, 50);  // Yellow-green
    textFont(boldFont);
    textAlign(CENTER, CENTER);
    text("Correct!", width/2, height - 120);
    if (capybaraVideo.time() >= capybaraVideo.duration() - 0.05) {   // if the video is over
      state = STATE_SHOW_TORTOISE; // move on to the next state
      resetVideo();
      animalImage = tortoiseImage; // set image to tortoise
      incorrectTriggered = false; // reset image to the original (correct) image
    }
  } else if (state == STATE_SHOW_TORTOISE) {
    displayAnimal(animalImage); // display animal image (tortoise)
    setIncorrectImage(tortoiseImageIncorrect, tortoiseImage); // changes to incorrect image if user is incorrect
  } else if (state == STATE_PLAY_TORTOISE) {
    // display tortoise eating
    if (tortoiseVideo.available()) {
      tortoiseVideo.read();
    }
    
    // display user is correct
    image(tortoiseVideo, 0, 0, width, height);
    fill(154, 205, 50);  // Yellow-green
    textFont(boldFont);
    textAlign(CENTER, CENTER);
    text("Correct!", width/2, height - 120);
    if (tortoiseVideo.time() >= tortoiseVideo.duration() - 0.05) {   // if the video is over
      state = STATE_SHOW_TOUCAN; // move on to the next state
      resetVideo();
      animalImage = toucanImage; // set image baack to toucan
      incorrectTriggered = false; // reset image to the original (correct) image
    }
  }
}


void keyPressed() {
  //// reset
  //if (key == 'r' || key == 'R') {
  //  resetVideo();
  //  state = STATE_SHOW_TOUCAN;
  //  return;
  //}
  
  // toucan state
  if (state == STATE_SHOW_TOUCAN) {
    if (key == 'a' || key == 'A') { // if correct button
      playingToucanVideo = true; // play toucan video
      correctSound.play(); // play correct sound fx
      toucanVideo.loop();
      state = STATE_PLAY_TOUCAN; // change state to video playing
      incorrectTriggered = false; // reset incorrect triggered flag
    } else {
      triggerIncorrect(); // if incorrect button, trigger incorrect image
    }
  }
  
  // capybara state
  if (state == STATE_SHOW_CAPYBARA) {
    if (key == 's' || key == 'S') { // if correct button
      playingCapybaraVideo = true; // play capybara video
      correctSound.play(); // play correct sound fx
      capybaraVideo.loop();
      state = STATE_PLAY_CAPYBARA; // change state to video playing
      incorrectTriggered = false; // reset incorrect triggered flag
    } else {
      triggerIncorrect(); // if incorrect button, trigger incorrect image
    }
  }
  
  // tortoise state
  if (state == STATE_SHOW_TORTOISE) {
    if (key == 'd' || key == 'D') { // if correct button
      playingTortoiseVideo = true; // play tortoise video
      correctSound.play(); // play correct sound fx
      tortoiseVideo.loop();
      state = STATE_PLAY_TORTOISE; // chage state to video playing
      incorrectTriggered = false; // reset incorrect triggered flag
    } else {
      triggerIncorrect(); // if incorrect button, trigger incorrect image
    }
  }
}


void serialEvent(Serial myPort) {
  // Read the incoming string and trim whitespace
  String inString = myPort.readStringUntil('\n');
  
  if (inString != null) {
    inString = trim(inString); // Remove any whitespace/newline characters
    
    if (inString.length() > 0) {
      char key = inString.charAt(0); // Get first character
      
      // toucan state
      if (state == STATE_SHOW_TOUCAN) {
        if (key == '1') { // if correct button
          playingToucanVideo = true; // play toucan video
          correctSound.play(); // play correct sound fx
          toucanVideo.loop();
          state = STATE_PLAY_TOUCAN; // change state to video playing
          incorrectTriggered = false; // reset incorrect triggered flag
        } else {
          triggerIncorrect(); // if incorrect button, trigger incorrect image
        }
      }
      
      // capybara state
      if (state == STATE_SHOW_CAPYBARA) {
        if (key == '2') { // if correct button
          playingCapybaraVideo = true; // play capybara video
          correctSound.play(); // play correct sound fx
          capybaraVideo.loop();
          state = STATE_PLAY_CAPYBARA; // change state to video playing
          incorrectTriggered = false; // reset incorrect triggered flag
        } else {
          triggerIncorrect(); // if incorrect button, trigger incorrect image
        }
      }
      
      // tortoise state
      if (state == STATE_SHOW_TORTOISE) {
        if (key == '3') { // if correct button
          playingTortoiseVideo = true; // play tortoise video
          correctSound.play(); // play correct sound fx
          tortoiseVideo.loop();
          state = STATE_PLAY_TORTOISE; // chage state to video playing
          incorrectTriggered = false; // reset incorrect triggered flag
        } else {
          triggerIncorrect(); // if incorrect button, trigger incorrect image
        }
      }
   }
  }

}

void resetVideo() {
  // reset toucan video if playing
  if (playingToucanVideo) {
    playingToucanVideo = false;
    toucanVideo.stop(); // stop
    toucanVideo.jump(0); // rewind
  }
  // reset capybara video if playing
  if (playingCapybaraVideo) {
    playingCapybaraVideo = false;
    capybaraVideo.stop(); // stop
    capybaraVideo.jump(0); // rewind
  }
  // reset tortoise video if playing
  if (playingTortoiseVideo) {
    playingTortoiseVideo = false;
    tortoiseVideo.stop(); // stop
    tortoiseVideo.jump(0); // rewind
  }
}

// displays animal photo centered and covered (with crop)
void displayAnimal(PImage animalPhoto) {
    imageMode(CENTER); // center image mode
    float imgAspect = (float) animalPhoto.width / animalPhoto.height; // image aspect ratio
    float windowAspect = (float)width / height; // window aspect ratio
    
    if (imgAspect < windowAspect) { // if window is winder
      image(animalPhoto, width/2, height/2, width, width / imgAspect); // fit to width
    } else { // if window is taller
      image(animalPhoto, width/2, height/2, height * imgAspect, height); // fit to height
    }

    imageMode(CORNER); // reset image mode
}

void triggerIncorrect() {
  if (!incorrectTriggered) {
    incorrectTriggered = true;
    showingIncorrect = true;
    incorrectStartTime = millis(); // start timer for incorrect image
    incorrectSound.play(); // play incorrect sound fx
  }
}

void setIncorrectImage(PImage animalPhotoIncorrect, PImage animalPhotoCorrect) {
  if (showingIncorrect) {  
    // set the image
    animalImage = animalPhotoIncorrect;

    // stop showing after a few seconds
    if (millis() - incorrectStartTime > INCORRECT_DURATION) {
      showingIncorrect = false;
      animalImage = animalPhotoCorrect; // reset image to the original (correct) image
      incorrectTriggered = false;
    }
  }
}
