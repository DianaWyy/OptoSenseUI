import ddf.minim.AudioSample;
import ddf.minim.Minim;
import processing.net.*;
import java.awt.event.KeyEvent;

Minim minim; 
AudioSample kick;

//long operationTime = 0;
//int count = 0;

int numRow = 8;
int numCol = 8;
//int randI;
//int randJ;
int len = 800;

int index;

String[] strs = {"Bottom Left", "Bottom Right", "Center", "Top Left", "Top Right"};

IntList indices;
int[] finalIndices;

PImage plus;

void setup() {
  //size(1000, 1000);
  size(800, 800);
  //fullScreen();
  
  // white background
  background(255);
  //operationTime = millis();
  
  minim = new Minim(this); 
  kick = minim.loadSample("beep.mp3", 512);
  
  indices = new IntList();
  for(int i = 0; i < 4; i++){
    indices.append(0);
    indices.append(1);
    indices.append(2);
    indices.append(3);
    indices.append(4);
  }
  indices.shuffle();
  println(indices);
  finalIndices = indices.array();
  index = 0;
  
  plus = loadImage("plus.png");
}

void draw() {
  background(255);
  float size = width/numRow;
  fill(0);
  textSize(80);
  text((index + 1) + ". " + strs[finalIndices[index]], width/2 - 250, height/2 - 300);
  //for (int j = 0; j < numRow; j++){
  //  for(int i = 0; i < numCol; i++){
  //    if (randI == i && randJ == j) {
  //      image(plus, randI * size, randJ * size, size-3, size-3);
  //    }
  //  }
  //}
  if (finalIndices[index] == 0) {
    image(plus, len * 1 / 8, len* 7 / 8, size-3, size-3);
  }
  else if (finalIndices[index] == 1) {
    image(plus, size* 7 / 8, len* 7 / 8, size-3, size-3);
  }
  else if (finalIndices[index] == 2) {
    image(plus, len / 2, len / 2, size-3, size-3);
  }
  else if (finalIndices[index] == 3) {
    image(plus, len* 1 / 8, len* 1 / 8, size-3, size-3);
  }
  else if (finalIndices[index] == 4) {
    image(plus, len* 7 / 8, len* 1 / 8, size-3, size-3);
  }
  //calculateSeconds();
  //  if (count == 105) {exit();}
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
