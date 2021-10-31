import processing.net.*;

Server myServer;

int numRow = 8;
int numCol = 1;
int numPixel = numRow * numCol;

// data
float[] gdata = new float[numPixel];
float currValue = 0;

// color for pixel
ColorMap cm = new ColorMap();

// counters
long operationTime = 0;
int counter = 0;
  
// for rolling graph
float inByte;
int[] yValues;
int[] yDerivatives;
int w;

// for thresholds
int rawThreshold = 15;

// for saving measurements
Table table;
float measurements [] = new float [8];

// Image initialize
PImage img_closed;
PImage img_opened;
PImage clock_img;

// flash counter
int flashCount = 0;

// show tick
boolean showTick = false;

// pill taken times
int pillCount = 0;
float currDerivative = 0;
float formerDerivative = 0;
int derivativeThreshold = 100;
float maxVal = 4095.0;

// simulation mode
boolean simulation = false;
int frameCounter = 0;

void setup() {
  size(1680, 1000);
  //fullScreen();
  // Starts a myServer on port 2337
  myServer = new Server(this, 2337); 
  
  // white background
  background(255);
  operationTime = millis();
  
  // image
  img_closed = loadImage("bottleClose.jpg");
  img_opened = loadImage("bottleOpen.jpg");
  
  // clock image
  //clock_img = loadImage("clock.jpg");
  
  // for rolling graph
  w = width/2 - 10;
  strokeWeight(3);
  yValues = new int[w];
  yDerivatives = new int[w];
  smooth();
  
  //Simulation
  if(simulation) {
    frameRate(10);
    //table = loadTable("OptoSense - Black Coffee.csv", "header");  
    table = loadTable("test.csv", "header");  
  }
  else {
    table = new Table();
    for(int i = 0; i < 1; i++){
      table.addColumn("position_" + i);
    }
  }
}

void draw() {
  if(simulation) {
    TableRow row = table.getRow(frameCounter);
    for(int i = 0; i < 1; i++){
      gdata[i] = row.getFloat("position_" + i);
      currValue = gdata[i];
      //println(gdata[i]);
    }
  }
  else {
    Client thisClient = myServer.available();
    if (thisClient != null) {
      
      //calculateFPS();
      
      String whatClientSaid = thisClient.readString();
      if (whatClientSaid != null) {
        processData(whatClientSaid);
      } 
    }
  }
  background(255);
  
  flashCount++;
  
  stroke(0);
  strokeWeight(2);
  line(width/2, 0, width/2, height);
  line(0, height/2, width, height/2);
  
  // 0D pixel
  int[] rgb = cm.getColor((float) (currValue)/maxVal);
  fill(rgb[0], rgb[1], rgb[2]);
  noStroke();
  rect(370, 200, 100, 100);

  // show threshold text
  //fill(0);
  //textSize(22);
  //text("Threshold: "+ rawThreshold, width/2 - 175, height/2 + 400);
  
  // for rolling raw measurements
  float yOffset = height/2 + 50;
  int currValueDraw = (int) (maxVal - currValue);
  
  currValueDraw = (int)map(currValueDraw, 0, maxVal, 0, 255);
  
  // moving rolling buffer
  for(int i = 1; i < w; i++) {
        yValues[i-1] = yValues[i];
  }
  yValues[w-1] = currValueDraw;
  
  // counter for opened seconds
  //if (counter > 15) {
  //  int c = flashCount / 45;
  //  if (c % 2 == 0) {
  //    fill(255, 0, 0, 127);
  //    noStroke();
  //    rect(width/2 + 2, height/2 + 2, width/2 - 2, height/2 - 2);
  //  } else {
  //    fill(255);
  //    noStroke();
  //    rect(width/2 + 2, height/2 + 2, width/2 - 2, height/2 - 2);
  //  }
  //  fill(0);
  //  textSize(32);
  //  text("Please close the pill bottle.", 1100, 825);
  //} else {
  //  fill(255);
  //  noStroke();
  //  rect(width/2 + 2, height/2 + 2, width/2 - 2, height/2 - 2);
  //}
  
  // pill taken times
  //fill(0);
  //textSize(30);
  //text("Pill Taken: " + pillCount + " times", width/2 + 20, height/2 + 35);
  //if (currDerivative > derivativeThreshold && formerDerivative < derivativeThreshold) {
  //      pillCount++;
  //}
  
  // reminder image display
  //image(clock_img, 950, 725, 125, 125);
  //// reminder text display
  //textSize(50);
  //fill(0);
  //text("Reminder to", 1150, 770);
  //text("TAKE MEDICINE", 1100, 850);
  //// tick
  //fill(255);
  //stroke(0);
  //rect(1500, 805, 50, 50);
  
  if (currValueDraw > (255 - rawThreshold)) {
      image(img_closed, width/2 + 238, 125, 250, 375);
      textSize(60);
      fill(0);
      text("Lid", 1145, 785);
      fill(255,0,0);
      text("Close", 1250, 785);
  }else {
      image(img_opened, width/2 + 230, 119, 365, 386);
      textSize(60);
      fill(0);
      text("Lid", 1145, 785);
      fill(50,205,50);
      text("Open", 1250, 785);
      //calculateSeconds();
      //float c = counter;
      //strokeWeight(5);
      //if (c == 1) {
      //  line(1505, 835, 1510, 840);
      //} else if (c == 2) {
      //  line(1505, 835, 1515, 845);
      //} else if (c == 3) {
      //  line(1505, 835, 1520, 850);
      //} else if (c == 4) {
      //  line(1505, 835, 1525, 855);
      //} else if (c == 5) {
      //  line(1505, 835, 1525, 855);
      //  line(1525, 855, 1530, 845);
      //} else if (c == 6) {
      //  line(1505, 835, 1525, 855);
      //  line(1525, 855, 1535, 835);
      //} else if (c == 7) {
      //  line(1505, 835, 1525, 855);
      //  line(1525, 855, 1540, 825);
      //} else if (c == 8) {
      //  line(1505, 835, 1525, 855);
      //  line(1525, 855, 1545, 815);
      //} else if (c == 9) {
      //  showTick = true;
      //}
      //fill(0);
      //textSize(50);
      //text("Pill Bottle Opened", 1075, 700);
      //text(counter + "s", 1225, 775);
  } 
  
  // show tick
  if (showTick == true) {
    strokeWeight(5);
    line(1505, 835, 1525, 855);
    line(1525, 855, 1545, 815);
    // check if last pill taken was one day ago
    int day = counter / 60 / 60 / 24;
    if (day == 1) {
      showTick = false;
    }
  } 
  
  // drawing rolling buffer for intensity
  noStroke();
  fill(255);
  rect(0, yOffset, width/2 - 2, 300);
  for(int i=1; i<w; i++) {
        fill(0);
        int y = (yValues[i] - 255) * 2;
        if (y < -255) {
          y = -255;
        }
        rect(i, yOffset + 255, 1, y);
  }
  fill(0);
  textSize(35);
  text("Raw measurement:", 10, yOffset - 13);
  // text(currValueDraw, 10, yOffset + 70);
  
  // draw threshold
  stroke(255, 200, 0);
  strokeWeight(1);
  line(0, 3 * (-rawThreshold) + yOffset + 255, width/2, 3 * (-rawThreshold) + yOffset + 255);
  
  formerDerivative = currDerivative;
  frameCounter++;
}


void calculateSeconds() {
  long currentTime = millis();
  if(currentTime - operationTime > 100){
    operationTime = currentTime;
    counter ++;
  }
}

void keyPressed(){
 // adjust threshold 
  //if(key == CODED){
  // if(keyCode == UP){
  //   rawThreshold+= 5;
  // }else if (keyCode == DOWN){
  //   rawThreshold -= 5;
  // }
  //}
  
  // press 0, 1, ..., 7 to save 8 measurements to a csv file
  if( key>= '0' && key <= '7'){ 
    int index = Integer.parseInt(key+"");
    measurements[index] = currValue;
    
    for(int i = 0; i < measurements.length; i++){
      print(measurements[i]);
      print(' ');
    }
    println();
    
  }else if (!simulation && key == 's'){
    //TableRow newRow = table.addRow();
    //for(int i = 0; i < 8; i++){
    //   newRow.setFloat("position_"+i, measurements[i]); 
    //}
    saveTable(table, "data/measurements.csv");
    println("measurements saved into data/measurements.csv");
  } else if (key == 'r'){
    reset();
    println("Reset");
  }
}
// Process data method
void processData(String resultString) {
  String[] data = split(resultString, " ");
  
      if(data.length != numPixel) return;
      
      for(int i = 0; i < data.length; i++){
        gdata[i] = Float.parseFloat(data[i]);
      }
      
      currDerivative = gdata[4] - currValue;
      currValue = gdata[4];
      TableRow newRow = table.addRow();
      
      for(int i = 0; i < 1; i++){
         newRow.setFloat("position_"+i, currValue); 
      }
}

void reset() {
  for(int i = 0; i < 8; i++){
    measurements[i] = 0;
  }
  
  operationTime = millis();
  
  // for rolling graph
  w = width/2 - 10;
  strokeWeight(3);
  yValues = new int[w];
  yDerivatives = new int[w];
  smooth();
  // tick
  showTick = false;
  //counter
  counter = 0;
  //table
  table = new Table();
  for(int i = 0; i < 1; i++){
    table.addColumn("position_" + i);
  }
}
