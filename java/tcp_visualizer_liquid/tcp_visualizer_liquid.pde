import processing.net.*;
import papaya.*;

Server myServer;

int numRow = 8;
int numCol = 1;
int numPixel = numRow * numCol;

float[] gdata = new float[numPixel];
ColorMap cm = new ColorMap();
int fpsCounter = 0;
String fpsIndicator = "";
int fps = 0;
long lastTime = -1;
float maxV = 4095;
float maxPeriod = 100;

// for saving measurements
Table table;
float measurements [] = new float [8];
float measurementsDraw[] = new float [8];
float prevMeasurements[] = new float [8];
float gradient[] = new float [8];
float thresholds [] = {0.1, 0.5, 0.7};
String liquids [] = {"Tea", "Juice", "Coffee"};
String  display = "";
float level = 0;
int frameCounter = 0;


boolean simulation = true;

// for liquid detection
float minSlope = Float.MAX_VALUE;

void setup() {
  ////Test
  //float testPrev[] = {2.0f, 3.0f, 5.0f, 4.0f};
  //float testCur[] = {1.0f, 2.0f, 3.0f, 5.0f};
  //println(isMovingRight(testPrev, testCur, 4));
  
  size(600, 600);
  // Starts a myServer on port 2337
  myServer = new Server(this, 2337); 
  background(255);
  lastTime = millis();
  
  //Simulation
  if(simulation) {
    frameRate(10);
    table = loadTable("measurements_oolong_01.csv", "header");  
  }
  else {
    table = new Table();
    for(int i = 0; i < 8; i++){
      table.addColumn("position_" + i);
    }
  }
}

void draw() {
  background(255);
  
  if(simulation) {
    TableRow row = table.getRow(frameCounter);
    for(int i = 0; i < 8; i++){
      gdata[i] = row.getFloat("position_" + i);
    }
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
  }
  
  float size = height/numRow;
  
  for (int j = 0; j < numRow; j++){
    for(int i = 0; i < numCol; i++){
        float colorVal = gdata[i*numRow + j];
        int[] rgb = cm.getColor((float) ((maxV-colorVal)/maxV));
        fill(rgb[0], rgb[1], rgb[2]);
        noStroke();
        rect(i*size, j*size, size-3, size-3);
        //break; //show only the first row (since we only have one diode)
    }
    //break;
  }
  
  // show FPS
  fill(0);
  textSize(20);
  text("FPS: "+fpsIndicator, 20, 20);
 
  
  for(int i = 0; i < 8; i++){
    measurements[i] = gdata[i];
    //measurementsDraw[i] = map(prevDelta[i], 4096, -4096, 0, height-20);
    measurementsDraw[i] = map(gdata[i], 4096, 0, 0, height-20);
  }
  
  minSlope = Float.MAX_VALUE;
  
  for(int i = 1; i < 8; i++){
    stroke(0);
    strokeWeight(5);
    line(i*60 + 100, measurementsDraw[i], (i-1)*60 + 100, measurementsDraw[i-1]);
    
    float slope = gdata[i] - gdata[i-1];
    
    if(slope < minSlope){
      minSlope = slope;
    }
  }
  
  textSize(20);
  text("Min Slope: "+minSlope, width/2, 20);
  
  //Liquid
  if(fpsCounter > 0 || simulation){
    float difference = computeDistance(prevMeasurements, measurements, 8); // Euclidean distance between frames
    if(difference > 0) { //
      frameCounter++; //count valid frames
      
      if(!simulation) {
        TableRow newRow = table.addRow();
        for(int i = 0; i < 8; i++){
           newRow.setFloat("position_"+i, measurements[i]); 
        }
      }
      
      float maximum = -1;
      float secondMaximum = -1;
      int indexMaximum = -1;
      int indexSecond = -1;
      for(int i = 0; i < numRow - 1; i++) {
        gradient[i] = abs(measurements[i + 1] - measurements[i]);
        if(gradient[i] > maximum){
          secondMaximum = maximum;
          indexSecond = indexMaximum;
          maximum = gradient[i];
          indexMaximum = i;
        } 
        else if(gradient[i] > secondMaximum) {
          secondMaximum = gradient[i];
          indexSecond = i;
        }
      }
      level = indexMaximum + 1; //the higher pixel of maximum gradient 
      int indexBefore = indexMaximum;
      int indexAfter = indexSecond;
      if(indexBefore > indexAfter) {
        indexBefore = indexSecond;
        indexAfter = indexMaximum;
      }
      float beforeAvg = 0;
      float afterAvg = 0;
      int count = 0;
      for(int i = 0; i < indexBefore + 1; i++) {
        beforeAvg += measurements[i];
        count++;
      }
      beforeAvg /= count;
      count = 0;
      for(int i = indexAfter + 1; i < numRow; i++) {
        afterAvg += measurements[i];
        count++;
      }
      afterAvg /= count;
      float activation = abs(afterAvg - beforeAvg) / beforeAvg;
      int index = -1;
      String liquid = "";
      for(int i = 0; i < thresholds.length; i++){
        if(activation > thresholds[i]){
          liquid = liquids[i];
          index = i;
        }
      }
      println(activation);
      if(index > -1 && level < 8) {//Has liquid
        display = liquid + " Level: " + level;
        
        noStroke();
        rect(size, level*size, size-3, 3);
      }
      else
        display = "No liquid detected";
    }
  }
  text(display, width/2, height - 30);
}

void calculateFPS(){
  // calculate frames per second
  long currentTime = millis();
  if(currentTime - lastTime > 1000){
    lastTime = currentTime;
    fps = fpsCounter;
    fpsIndicator = "" + fpsCounter;
    fpsCounter = 0;
  }else{
    fpsCounter++;
  }
}

void processData(String resultString){
  String[] data = split(resultString, " ");
  
      if(data.length != numPixel) return;
      
      for(int i = 0; i < data.length; i++){
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
  
  gdata[7] = tdata[4];
   gdata[6] = tdata[5];
    gdata[5] = tdata[6];
     gdata[4] = tdata[7];
  gdata[3] = tdata[0];
   gdata[2] = tdata[1];
    gdata[1] = tdata[2];
     gdata[0] = tdata[3];
}
  
void keyPressed(){
  
  if (!simulation && key == 's'){
    TableRow newRow = table.addRow();
    for(int i = 0; i < 8; i++){
       newRow.setFloat("position_"+i, gdata[i]); 
       print(gdata[i]);
       print(' ');
    }
    println();
    saveTable(table, "data/measurements.csv");
    println("measurements saved into data/measurements.csv");
  }
  if (key == 'r'){
    reset();
    println("Reset");
  }
  
}

float computeDistance(float[] inputPrev, float[] inputCur, int len) {
  float[][] data = new float[2][len];
  for(int i = 0; i < len; i++){
     data[0][i] = inputPrev[i];
     data[1][i] = inputCur[i];
  }
  float[][] distance = Distance.euclidean(data); 
  return distance[0][1];
}
void reset() {
  for(int i = 0; i < 8; i++){
    measurements[i] = 0;
    measurementsDraw[i] = 0;
    prevMeasurements[i] = 0;
    gradient[i] = 0;
  }
  display = "";
  level = 0;
  frameCounter = 0;
}
