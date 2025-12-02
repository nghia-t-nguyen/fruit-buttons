const int buttonPin = 2; // Pin for button 1
const int buttonPin2 = 4; // Pin for button 2
const int buttonPin3 = 8; // Pin for button 3

void setup() {
  // Initialize the button pin as an input with an internal pull-up resistor.
  // The button should connect the pin to GND when pressed.
  pinMode(buttonPin, INPUT_PULLUP);
  pinMode(buttonPin2, INPUT_PULLUP);
  pinMode(buttonPin3, INPUT_PULLUP);
  Serial.begin(9600); // init serial
}

void loop() {
  // Read the state of the button
  int buttonState = digitalRead(buttonPin);
  int buttonState2 = digitalRead(buttonPin2);
  int buttonState3 = digitalRead(buttonPin3);

  // A LOW reading means the button is pressed (due to INPUT_PULLUP)
  if (buttonState == LOW) {
    Serial.println("1"); // output "1" if pressed
  }
  else if (buttonState2 == LOW) {
    Serial.println("2"); // output "2" if pressed
  }
  else if (buttonState3 == LOW) {
    Serial.println("3"); // output "3" if pressed
  }
}