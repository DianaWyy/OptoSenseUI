//////////SWIPE
import processing.net.*;
Server myServer;

int numRow = 8;
int numCol = 8;
int actualNumRow = 8;
int actualNumCol = 8;
int numTouchPoints = 5;
int numPixel = numRow * numCol;
int numAllData = numPixel + numTouchPoints*2;
int actualNumPixel = actualNumRow * actualNumCol;

float[] gdata = new float[numAllData];
ColorMap cm = new ColorMap();
int fpsCounter = 0;
String fpsIndicator = "";
long lastTime = -1;
float maxV = 256.0;

// for saving measurements
Table table;
float background = maxV;
float threshold = 10.0;

boolean simulation = false;

int frameCounter = 0;

//float[][] touchPoints = new float[numTouchPoints][2];
//float[][] touchPointsArray = new float[5][2];

int index;
String[] strs = {"", "Swipe Up", "Swipe Down", "Swipe Left", "Swipe Right"};
PImage arrowUp;
PImage arrowDown;
PImage arrowLeft;
PImage arrowRight;
PImage[] imgs = new PImage[5];

float[] swipe = {127.0, 127.0};
int[][] MHI = new int[actualNumRow][actualNumCol];
float[][] measurements = new float[actualNumRow][actualNumCol];
int TAU = 10;
int MAX_VAL = 65535;

// In-air swipe gesture detection using motion history image
void motion_history(float input[][], float max_back, float threshold, int m_adc_evt_counter) {
    int count = 0;
    for(int i = 0; i < actualNumRow; i += 1) {
        for(int j = 0; j < actualNumCol; j += 1) {
            if(input[i][j] < max_back*threshold){
                //println(input[i][j]);
                if(MHI[i][j] == MAX_VAL)
                    MHI[i][j] = m_adc_evt_counter;
            }
            else if(MHI[i][j] < m_adc_evt_counter - TAU)
                MHI[i][j] = 0;
//            if(MHI[i][j] > 0 && MHI[i][j] < MAX_VAL)
//                MHI[i][j] -= 1;
            if(MHI[i][j] == 0 || MHI[i][j] == MAX_VAL)
                count += 1;
        }
    }
    if(count == actualNumRow * actualNumCol){
        for(int i = 0; i < actualNumRow; i += 1)
            for(int j = 0; j < actualNumCol; j += 1)
                MHI[i][j] = MAX_VAL;
    }
}

// Simple MHI gradient calc in two directions
float gradient(int input[][], int axis) { // axis = 0 horizontal, axis = 1 vertical
    float rst = 0;
    if(axis == 0){
        for(int i = 0; i < actualNumRow; i += 1)
            for(int j = 0; j <  actualNumCol - 1; j += 1)
                rst += (float)(input[i][j + 1])/(float)MAX_VAL - (float)(input[i][j])/(float)MAX_VAL;
    }
    else{
        for(int i = 0; i < actualNumRow - 1; i += 1)
            for(int j = 0; j < actualNumCol; j += 1)
                rst += (float)(input[i + 1][j])/(float)MAX_VAL - (float)(input[i][j])/(float)MAX_VAL;
    }
    return rst;
}

void setup() {
  //fullScreen();
  //size(1680, 1000);
  size(1260, 750);
  // Starts a myServer on port 2337
  myServer = new Server(this, 2337); 
  background(255);
  lastTime = millis();
  
  //Simulation
  if(simulation) {
    frameRate(60);
    table = loadTable("measurements.csv", "header");  
  }
  else {
    table = new Table();
    for(int i = 0; i < numAllData; i++){
      table.addColumn("position_" + i);
    }
  }
  
  arrowUp = loadImage("arrowUp.png");
  arrowDown = loadImage("arrowDown.png");
  arrowLeft = loadImage("arrowLeft.png");
  arrowRight = loadImage("arrowRight.png");
  imgs[1] = arrowUp;
  imgs[2] = arrowDown;
  imgs[3] = arrowLeft;
  imgs[4] = arrowRight;
  
  for(int i = 0; i < actualNumRow; i += 1)
    for(int j = 0; j < actualNumCol; j += 1)
      MHI[i][j] = MAX_VAL;
}

void draw() {
  background(255);
  
  if(simulation) {
    TableRow row = table.getRow(frameCounter);
    for(int i = 0; i < numAllData; i++){
      gdata[i] = row.getFloat("position_" + i);
    }
    //println(gdata[0]);
  }
  else {
    Client thisClient = myServer.available();
    if (thisClient != null) {
      
      calculateFPS();
      
      String whatClientSaid = thisClient.readString();
      if (whatClientSaid != null) {
        processData(whatClientSaid);
      } 
    }
    TableRow newRow = table.addRow();
    for(int i = 0; i < numAllData; i++){
       newRow.setFloat("position_"+i, gdata[i]); 
    }
  }
  float size = width/2/numRow;
    for (int j = 0; j < actualNumRow; j++){
    for(int i = 0; i < actualNumCol; i++){
        float measurement = gdata[(numCol - 1 - (i + numCol - actualNumCol))*numRow + j];
        measurements[i][j] = measurement;
        //float colorVal = map(measurement, 4096, 0, 0, height-20);
        float colorVal = measurement;
        //println(j + " " + i + " " + colorVal);
        float remap = (background-colorVal)/background;
        if(remap < 0)
          remap = 0;
        int[] rgb = cm.getColor(remap);
        fill(rgb[0], rgb[1], rgb[2]);
        noStroke();
        rect(i*size, 100+j*size, size-3, size-3);
        //break; //show only the first row (since we only have one diode)
    }
    //break;
  }
  
  float max_back = gdata[numPixel + 2];
  //println(max_back);
  //float max_back = 100.0;
  motion_history(measurements, max_back, 0.7, frameCounter);
  float horizontal_gradient = gradient(MHI, 0) * 4.0;
  float vertical_gradient = gradient(MHI, 1) * -4.0;
  
  //swipe[0] = gdata[numPixel] - 127;
  //swipe[1] = gdata[numPixel + 1] - 127;
  swipe[0] = horizontal_gradient;
  swipe[1] = vertical_gradient;
  index = 0;
  if(abs(swipe[0]) > threshold || abs(swipe[1]) > threshold){
    //println(swipe[0] + ", " + swipe[1]);
    //println(horizontal_gradient + ", " + vertical_gradient);
    if(abs(swipe[0]) > abs(swipe[1])) {
      if(swipe[0] < 0)
        index = 1;
      else
        index = 2;
    }
    else if(abs(swipe[0]) < abs(swipe[1])){
      if(swipe[1] < 0)
        index = 4;
      else
        index = 3;
    }
    println(index);
  }
  //println(index);
  
  //index = 1;
  fill(0);
  textSize(40);
  text(strs[index], width/2 + 80, 35);
  
  if(index > 0) {
    if (index < 3) {image(imgs[index], width/2 + 125, 100, 116, 275);}
    else {image(imgs[index], width/2 + 0, 200, 275, 116);}
  }
  frameCounter++;
}

void calculateFPS(){
  // calculate frames per second
  long currentTime = millis();
  if(currentTime - lastTime > 1000){
    lastTime = currentTime;
    fpsIndicator = "" + fpsCounter;
    fpsCounter = 0;
  }else{
    fpsCounter++;
  }
}

void processData(String resultString){
  String[] data = split(resultString, " ");
  
      if(data.length != numAllData) return;
      
      for(int i = 0; i < data.length; i++){
        //println(i + " " + data[i]);
        gdata[i] = Float.parseFloat(data[i]);
        //println(gdata[i]);
      }
      reorg(gdata);
      
}
void reorg(float[] gdata){
  
  float[] tdata = new float[8];
  for(int i = 0; i < 8; i++){
    tdata[i] = gdata[i];
  }
  
  gdata[7] = tdata[7];
   gdata[6] = tdata[6];
    gdata[5] = tdata[5];
     gdata[4] = tdata[4];
  gdata[3] = tdata[3];
   gdata[2] = tdata[2];
    gdata[1] = tdata[1];
     gdata[0] = tdata[0];
}

void keyPressed(){
  
  if (key == 's'){
    //TableRow newRow = table.addRow();
    //for(int i = 0; i < 8; i++){
    //   newRow.setFloat("position_"+i, gdata[i]); 
    //   print(gdata[i]);
    //   print(' ');
    //}
    //println();
    saveTable(table, "data/measurements.csv");
    println("measurements saved into data/measurements.csv");
  }
  if (key == 'p'){
    for (int j = 0; j < numRow; j++){
        for(int i = 0; i < numCol; i++){
            float colorVal = gdata[(numCol - 1 - i)*numRow + j];
            print(colorVal);
            print(" ");
        }
    }
    println();
  }
}
