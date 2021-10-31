import ddf.minim.AudioSample;
import ddf.minim.Minim;
import processing.net.*;

Minim minim; 
AudioSample kick;

//long operationTime = 0;
//int count = -5;
int index;

String[] strs = {"Swipe Up", "Swipe Down", "Swipe Left", "Swipe Right"};
int rand;
//boolean changed = false;

PImage arrowUp;
PImage arrowDown;
PImage arrowLeft;
PImage arrowRight;
PImage[] imgs = new PImage[4];

IntList indices;
int[] finalIndices;

void setup() {
  //size(1680, 1000);
  //size(840, 500);
  fullScreen();
  
  // white background
  background(255);
  //operationTime = millis();
  
  minim = new Minim(this); 
  kick = minim.loadSample("beep.mp3", 512);
  
  indices = new IntList();
  for(int i = 0; i < 5; i++){
    indices.append(0);
    indices.append(1);
    indices.append(2);
    indices.append(3);
  }
  indices.shuffle();
  println(indices);
  finalIndices = indices.array();
  index = 0;
  
  arrowUp = loadImage("arrowUp.png");
  arrowDown = loadImage("arrowDown.png");
  arrowLeft = loadImage("arrowLeft.png");
  arrowRight = loadImage("arrowRight.png");
  imgs[0] = arrowUp;
  imgs[1] = arrowDown;
  imgs[2] = arrowLeft;
  imgs[3] = arrowRight;
}

void draw() {
  background(255);
  if (index == 20) {
    exit();
  }
  //calculateSeconds();
  //if (count < 0) {
  //  fill(0);
  //  textSize(80);
  //  text("Testing Start", width/2 - 225, height/2);
  //} else {
    fill(0);
    textSize(80);
    text((index + 1) + ". " + strs[finalIndices[index]], width/2 - 250, height/2 - 300);
    if (finalIndices[index] < 2) {image(imgs[finalIndices[index]], width/2 - 130, 325, 231, 550);}
    else {image(imgs[finalIndices[index]], width/2 - 225, height/2 - 100, 550, 231);}
    
    //if (count % 5 == 0 && !changed) {
    //  fill(255);
    //  noStroke();
    //  rect(width/2 - 200, height/2 - 100, 400, 400);
    //  rand = int(random(strs.length));
    //  index++;
    //  kick.trigger(); // play beep sound
    //  //fill(0);
    //  //textSize(80);
    //  //text(index + ". " + strs[rand], width/2 - 225, height/2);
    //  changed = true;
    //}
    //if (count % 5 == 1) {changed = false;}
    //if (count == 105) {exit();}
  //}
}
  
//void calculateSeconds() {
//  long currentTime = millis();
//  if(currentTime - operationTime > 1000){
//    operationTime = currentTime;
//    count ++;
//  }
//}

void keyPressed(){
  if (keyPressed) {
    if(key == ' '){
      fill(255);
      noStroke();
      rect(width/2 - 200, height/2 - 100, 400, 400);
      //rand = int(random(strs.length));
      index++;
      kick.trigger(); // play beep sound
      //println(index);
     }
  }
}
