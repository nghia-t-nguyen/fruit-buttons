
const int buzzerPin = 7;
const int buttonPin = 2; // Pin for the button
const int buttonPin2 = 4;
const int buttonPin3 = 8;

void setup() {
  pinMode(buzzerPin, OUTPUT);
  // Initialize the button pin as an input with an internal pull-up resistor.
  // The button should connect the pin to GND when pressed.
  pinMode(buttonPin, INPUT_PULLUP);
  pinMode(buttonPin2, INPUT_PULLUP);
  pinMode(buttonPin3, INPUT_PULLUP);
  Serial.begin(9600);
}

void loop() {
  // Read the state of the button
  int buttonState = digitalRead(buttonPin);
  int buttonState2 = digitalRead(buttonPin2);
  int buttonState3 = digitalRead(buttonPin3);

  // A LOW reading means the button is pressed (due to INPUT_PULLUP)
  if (buttonState == LOW) {
    Serial.println("1");
    tone(buzzerPin, 1000); 
  }
  else if (buttonState2 == LOW) {
    Serial.println("2");
    tone(buzzerPin, 900); 
  }
  else if (buttonState3 == LOW) {
    Serial.println("3");
    tone(buzzerPin, 800); 
  } else {
    noTone(buzzerPin);
  }
}