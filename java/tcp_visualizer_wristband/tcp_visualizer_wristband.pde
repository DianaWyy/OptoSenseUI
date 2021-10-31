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
float delta[] = new float [8];
float prevDelta[] = new float [8];
float maxMeasurements [] = new float [8];
float minMeasurements [] = new float [8];
int mostSignificant = -1;
//float prevDifference = -1;
//float keyFrame[] = new float [8];
//long keyFrameIndex = -1;
//float prevCorr = -1;
float threshold = 0.2;
//float corrThreshold = 0.5; // Threshold of similarity
//float differenceThreshold = 500; //Threshold of change
//long frameThreshold = 300; //Threshold of periodic patterns
String direction = "";
int frameCounter = 0;
long periodicCounter = 0;
float pixel [] = new float [300];
int pixelIndex = 0;
int period = 0;
int searchFreq = 20;
boolean firstPeak = false;

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
    table = loadTable("measurements_walking.csv", "header");  
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
  
  //Direction information
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
      
      float maxDiff = 0;
      for(int i = 0; i < 8; i++) {
        delta[i] = measurements[i] - prevMeasurements[i];
        if(mostSignificant < 0) { //Only find most significant pixel for once for now
          if(maxMeasurements[i] < measurements[i])
            maxMeasurements[i] = measurements[i];
          if(minMeasurements[i] > measurements[i])
            minMeasurements[i] = measurements[i];
          if(maxDiff < maxMeasurements[i] - minMeasurements[i]){
            maxDiff = maxMeasurements[i] - minMeasurements[i];
            //println(maxDiff);
            mostSignificant = i;
          }
        }
      }
      if(mostSignificant > -1 && frameCounter > 10) {
        pixel[pixelIndex] = measurements[mostSignificant];
        pixelIndex ++;
        if(pixelIndex == searchFreq) {
          findPeriod();
          pixelIndex = 0;
        }
      }
      //if(keyFrameIndex < 0){//keyFrame not found yet
      //  if(prevDifference > difference) {// Local maximum as key frame
      //    keyFrameIndex = frameCounter;//Update keyFrame
      //    for(int i = 0; i < 8; i++) 
      //      keyFrame[i] = prevDelta[i];
      //  }
      //}
      //else { //keyFrame already set
      //  if(difference > differenceThreshold) {
      //    if(frameCounter - keyFrameIndex < frameThreshold){
      //      float linearCorr = Correlation.linear(keyFrame, delta, true);
      //      println(linearCorr);
      //      if(flip && prevCorr > linearCorr && prevCorr > corrThreshold){
      //        flip = !flip;
      //        periodicCounter ++;
      //        keyFrameIndex = frameCounter;//Update keyFrame
      //        for(int i = 0; i < 8; i++) 
      //          keyFrame[i] = prevDelta[i];
      //        prevCorr = -1; //Reset comparison
      //      }
      //      else if(!flip && prevCorr < linearCorr && prevCorr < -corrThreshold){
      //        flip = !flip;
      //        periodicCounter ++;
      //        keyFrameIndex = frameCounter;//Update keyFrame
      //        for(int i = 0; i < 8; i++) 
      //          keyFrame[i] = prevDelta[i];
      //        prevCorr = -1; //Reset comparison
      //      }
      //      else
      //        prevCorr = linearCorr;
      //    }
      //    else {
      //      keyFrameIndex = -1; //reset keyFrame
      //    }
      //  }
      float[] leftOrRight = movingLeftOrRight(prevMeasurements, measurements, 8);
      float movingLeft = leftOrRight[0] - leftOrRight[1];
      println(movingLeft);
      if(movingLeft > threshold)
        direction = "Left";
      else if(movingLeft < -1 * threshold){
        if(direction == "Left")
          periodicCounter++;
        direction = "Right";
      }
      for(int i = 0; i < 8; i++) {
        prevMeasurements[i] = measurements[i];
        prevDelta[i] = delta[i];
        //print(measurements[i] + " ");
      }
      //prevDifference = difference; 
    }
  }
  String display = direction + " Count: " + periodicCounter + " Freq: " + float(fps) / float(period) + "";
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

float[] movingLeftOrRight(float[] inputPrev, float[] inputCur, int len) {
  float[] dataPrev = new float[len];
  for(int i = 0; i < len - 1; i++){
     dataPrev[i] = inputPrev[i + 1];
  }
  dataPrev[len - 1] = inputPrev[0];
  float linearCorrMovingRight = Correlation.linear(dataPrev, inputCur, true);
  for(int i = 0; i < len - 1; i++){
     dataPrev[i + 1] = inputPrev[i];
  }
  dataPrev[0] = inputPrev[len - 1];
  float linearCorrMovingLeft = Correlation.linear(dataPrev, inputCur, true);
  float[] rst = {linearCorrMovingLeft, linearCorrMovingRight};
  //println(linearCorrMovingLeft + " " + linearCorrMovingRight);
  return rst;
}

void findPeriod() {
  float maxCorr = 0;
  for(int i = 1; i < pixelIndex; i++) {
    float template0[] = new float[pixelIndex - i];
    float template1[] = new float[pixelIndex - i];
    for(int j = 0; j < pixelIndex - i; j++) {
      template0[j] = pixel[j];
      template1[j] = pixel[j + i];
    }
    float corr = Correlation.linear(template0, template1, true);
    //println(i + " " + corr);
    if(corr > maxCorr) {
      maxCorr = corr;
      if(i > 1)
        firstPeak = true;
    }
    else if(firstPeak) {
      period = i;
      firstPeak = false;
      return;
    }
  }
}


void reset() {
  for(int i = 0; i < 8; i++){
    measurements[i] = 0;
    measurementsDraw[i] = 0;
    prevMeasurements[i] = 0;
    delta[i] = 0;
    prevDelta[i] = 0;
    maxMeasurements[i] = -1;
    minMeasurements[i] = Float.MAX_VALUE;
  }
  mostSignificant = -1;
  direction = "";
  frameCounter = 0;
  periodicCounter = 0;
  period = 0;
  pixelIndex = 0;
  pixel = new float [300];
}
