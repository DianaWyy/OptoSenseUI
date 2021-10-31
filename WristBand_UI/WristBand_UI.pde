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
float threshold = 200.0;

//float corrThreshold = 0.5; // Threshold of similarity
//float differenceThreshold = 500; //Threshold of change
//long frameThreshold = 300; //Threshold of periodic patterns
String direction = "";
int frameCounter = 0;

int maxBuffer = 500;
long periodicCounter = 0;
float pixel [][] = new float [8][maxBuffer];
int pixelIndex = 0;
int period = 0;
int searchFreq = 20;
boolean firstPeak = false;
int[] pixelHigh = {-1, -1};
int[] pixelLow = {-1, -1};
boolean calibration_done = false;

boolean simulation = false;

int countStep = 0;
int imageIndex = 0;

//int steps = 0;

// for liquid detection
float minSlope = Float.MAX_VALUE;

// walking man
PImage pose_0, pose_1, pose_2, pose_3, pose_4, pose_5, pose_6, pose_7, pose_standing;

void setup() {
  ////Test
  //float testPrev[] = {2.0f, 3.0f, 5.0f, 4.0f};
  //float testCur[] = {1.0f, 2.0f, 3.0f, 5.0f};
  //println(isMovingRight(testPrev, testCur, 4));
  size(1680, 1000, P2D);
  //size(840, 500, P2D);
  //fullScreen();
  // Starts a myServer on port 2337
  myServer = new Server(this, 2337); 
  background(255);
  lastTime = millis();
  
  //Simulation
  if(simulation) {
    frameRate(10);
    table = loadTable("measurements_walking_2.csv", "header");  
  }
  else {
    table = new Table();
    for(int i = 0; i < 8; i++){
      table.addColumn("position_" + i);
    }
  }
  
   // image
  pose_0 = loadImage("pose_0.png");
  pose_1 = loadImage("pose_1.png");
  pose_2 = loadImage("pose_2.png");
  pose_3 = loadImage("pose_3.png");
  pose_4 = loadImage("pose_4.png");
  pose_5 = loadImage("pose_5.png");
  pose_6 = loadImage("pose_6.png");
  pose_7 = loadImage("pose_7.png");
  pose_standing = loadImage("pose_standing.png");
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
  
  float size = width/2/numRow;
  
  for (int j = 0; j < numRow; j++){
    for(int i = 0; i < numCol; i++){
        float colorVal = gdata[i*numRow + j];
        int[] rgb = cm.getColor((float) ((maxV-colorVal)/maxV));
        fill(rgb[0], rgb[1], rgb[2]);
        noStroke();
        rect(j*size, 220 + i*size, size-3, size-3);
        //break; //show only the first row (since we only have one diode)
    }
    //break;
  }
  
  //fill(255);
  //circle(400, 275, 250);
  
  // show FPS
  //fill(0);
  //textSize(20);
  //text("FPS: "+fpsIndicator, 20, 20);
  //println("FPS: "+fpsIndicator);
  // Draw grid lines
  stroke(0);
  strokeWeight(2);
  line(width/2, 0, width/2, height);
  line(0, height/2, width, height/2);
  
  for(int i = 0; i < 8; i++){
    measurements[i] = gdata[i];
    //measurementsDraw[i] = map(prevDelta[i], 4096, -4096, 0, height-20);
    measurementsDraw[i] = map(gdata[i], 4096, 0, 0, height/2-20);
  }
  
  minSlope = Float.MAX_VALUE;
  
  for(int i = 1; i < 8; i++){
    stroke(255);
    strokeWeight(5);
    fill(0);
    rect(i*60 + 175, measurementsDraw[i] + height/2 + 20, -60, measurementsDraw[i-1] - measurementsDraw[i] + height/2 + 20);
 
    float slope = gdata[i] - gdata[i-1];
    
    if(slope < minSlope){
      minSlope = slope;
    }
  }
  
  //textSize(20);
  //text("Min Slope: "+minSlope, width/2, 20);
  
  //Direction information
  if(fpsCounter > 0 || simulation){
    float difference = computeDistance(prevMeasurements, measurements, numRow); // Euclidean distance between frames
    if(difference > 0) { //
      
      if(!simulation) {
        TableRow newRow = table.addRow();
        for(int i = 0; i < 8; i++){
           newRow.setFloat("position_"+i, measurements[i]); 
        }
      }
      if(frameCounter < maxBuffer && !calibration_done){
        for(int i = 0; i < 8; i++){
             pixel[i][frameCounter] = measurements[i];
        }
      }
      float leftOrRight = 0;
      if(calibration_done) {
        leftOrRight = movingLeftOrRight_2(prevMeasurements, measurements);
        //println(leftOrRight);
      }
      
      
      //float maxDiff = 0;
      //for(int i = 0; i < 8; i++) {
      //  delta[i] = measurements[i] - prevMeasurements[i];
      //  if(mostSignificant < 0) { //Only find most significant pixel for once for now
      //    if(maxMeasurements[i] < measurements[i])
      //      maxMeasurements[i] = measurements[i];
      //    if(minMeasurements[i] > measurements[i])
      //      minMeasurements[i] = measurements[i];
      //    if(maxDiff < maxMeasurements[i] - minMeasurements[i]){
      //      maxDiff = maxMeasurements[i] - minMeasurements[i];
      //      //println(maxDiff);
      //      mostSignificant = i;
      //    }
      //  }
      //}
      //if(mostSignificant > -1 && frameCounter > 10) {
      //  pixel[pixelIndex] = measurements[mostSignificant];
      //  pixelIndex ++;
      //  if(pixelIndex == searchFreq) {
      //    findPeriod();
      //    pixelIndex = 0;
      //  }
      //}
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
      
      //int[] pixelHigh = {4,5,6};
      //int[] pixelLow = {0,7};
      
      imageIndex = -1;
      int frameBeforeStop = 6; // frames of waiting before stops 
      if(direction == "Left") {
        if(leftOrRight < -1 * threshold) {
          imageIndex = 0;
          direction = "Right";
          countStep = 0;
          //steps++;
          //println(steps);
        }
        else if(countStep == 0) {
          imageIndex = 5  ;
          countStep++;
        }
        else if(countStep == 1) {
          imageIndex = 6;
          countStep++;
        }
        else if(countStep < frameBeforeStop) {
          imageIndex = 7;
          countStep++;
        }
      }
      else {
        if(leftOrRight > threshold) {
          imageIndex = 4;
          direction = "Left";
          countStep = 0;
          periodicCounter++;
          //steps++;
          //println(steps);
        }
        else if(countStep == 0) {
          imageIndex = 1;
          countStep++;
        }
        else if(countStep == 1) {
          imageIndex = 2;
          countStep++;
        }
        else if(countStep < frameBeforeStop) {
          imageIndex = 3;
          countStep++;
        }
      }
      for(int i = 0; i < 8; i++) {
        prevMeasurements[i] = measurements[i];
        prevDelta[i] = delta[i];
        //print(measurements[i] + " ");
      }
      //prevDifference = difference; 
    }
    frameCounter++; //count valid frames
  }
  switch(imageIndex) {
    case 0:
      image(pose_0, width/2 + 250, 20, height/3, height/2);
      break;
    case 1:
      image(pose_1, width/2 + 250, 20, height/3, height/2);
      break;
    case 2:
      image(pose_2, width/2 + 250, 20, height/3, height/2);
      break;
    case 3:
      image(pose_3, width/2 + 250, 20, height/3, height/2);
      break;
    case 4:
      image(pose_4, width/2 + 250, 20, height/3, height/2);
      break;
    case 5:
      image(pose_5, width/2 + 250, 20, height/3, height/2);
      break;
    case 6:
      image(pose_6, width/2 + 250, 20, height/3, height/2);
      break;
    case 7:
      image(pose_7, width/2 + 250, 20, height/3, height/2);
      break;
    default:
      image(pose_standing, width/2 + 250, 20, height/3, height/2);
      break;
  }
  String display = periodicCounter + " Steps";
  //+ " Freq: " + float(fps) / float(period) + "";
  fill(0);
  textSize(45);
  text(display, width*3/4 - 100, height*3/4);
  
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
  if (key == ' ') {
    float stdev[] = new float[8];
    for(int i = 0; i < 8; i++){
      float data[] = new float[frameCounter];
      int len = frameCounter;
      if(frameCounter > maxBuffer)
        len = maxBuffer;
      for(int j = 0; j < len; j++)
        data[j] = pixel[i][j];
      stdev[i] = Descriptive.std(data,true); 
    }
    float stdev_sorted[] = sort(stdev);
    for(int i = 0; i < 8; i++){
      println(i + " " + stdev_sorted[i]);
      if(stdev_sorted[0] == stdev[i])
        pixelLow[0] = i;
      if(stdev_sorted[1] == stdev[i])
        pixelLow[1] = i;
      if(stdev_sorted[7] == stdev[i])
        pixelHigh[0] = i;
      if(stdev_sorted[6] == stdev[i])
        pixelHigh[1] = i;
    }
    calibration_done = true;
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

float[] movingLeftOrRight(float[] inputPrev, float[] inputCur, int start, int len) {
  float[] dataCur = new float[len];
  for(int i = 0; i < len; i++){
     dataCur[i] = inputCur[start + i];
  }
  
  float[] dataPrev = new float[len];
  for(int i = 0; i < len - 1; i++){
     dataPrev[i] = inputPrev[start + i + 1];
  }
  
  if(start + len == numRow)
    dataPrev[len - 1] = inputPrev[0];
  else
    dataPrev[len - 1] = inputPrev[start + len];
    
  //float distanceMovingRight = computeDistance(dataPrev, dataCur, numRow);
  float linearCorrMovingRight = Correlation.linear(dataPrev, dataCur, true);

  for(int i = 0; i < len - 1; i++){
     dataPrev[i + 1] = inputPrev[start + i];
  }
  
  if(start == 0)
    dataPrev[0] = inputPrev[numRow - 1];
  else
    dataPrev[0] = inputPrev[start  - 1];
    
  float linearCorrMovingLeft = Correlation.linear(dataPrev, dataCur, true);
  //float distanceMovingLeft = computeDistance(dataPrev, dataCur, numRow);
  
  float[] rst = {linearCorrMovingLeft, linearCorrMovingRight};
  //float[] rst = {distanceMovingLeft, distanceMovingRight};
  //println(linearCorrMovingLeft + " " + linearCorrMovingRight);
  return rst;
}

float movingLeftOrRight_2(float[] inputPrev, float[] inputCur) {
  float dataCurHigh = 0;
  float dataPrevHigh = 0;
  float dataCurLow = 0;
  float dataPrevLow = 0;
  
  for(int i = 0; i < pixelHigh.length; i++){
     dataCurHigh += inputCur[pixelHigh[i]];
     dataPrevHigh += inputPrev[pixelHigh[i]];
  }
  dataCurHigh /= pixelHigh.length;
  dataPrevHigh /= pixelHigh.length;
  
  for(int i = 0; i < pixelLow.length; i++){
     dataCurLow += inputCur[pixelLow[i]];
     dataPrevLow += inputPrev[pixelLow[i]];
  }
  dataCurLow /= pixelLow.length;
  dataPrevLow /= pixelLow.length;
  
  float dataCur = dataCurHigh - dataCurLow;
  float dataPrev = dataPrevHigh - dataPrevLow;
   
  return dataCur - dataPrev;
}


//void findPeriod() {
//  float maxCorr = 0;
//  for(int i = 1; i < pixelIndex; i++) {
//    float template0[] = new float[pixelIndex - i];
//    float template1[] = new float[pixelIndex - i];
//    for(int j = 0; j < pixelIndex - i; j++) {
//      template0[j] = pixel[j];
//      template1[j] = pixel[j + i];
//    }
//    float corr = Correlation.linear(template0, template1, true);
//    //println(i + " " + corr);
//    if(corr > maxCorr) {
//      maxCorr = corr;
//      if(i > 1)
//        firstPeak = true;
//    }
//    else if(firstPeak) {
//      period = i;
//      firstPeak = false;
//      return;
//    }
//  }
//}


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
}
