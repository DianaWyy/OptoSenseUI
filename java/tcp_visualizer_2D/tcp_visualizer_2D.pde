import processing.net.*;

Server myServer;

int numRow = 8;
int numCol = 8;
int numTouchPoints = 5;
int numPixel = numRow * numCol;
int numAllData = numPixel + numTouchPoints*2;

int actualNumPixel = 64;

float[] gdata = new float[numAllData];
ColorMap cm = new ColorMap();
int fpsCounter = 0;
String fpsIndicator = "";
long lastTime = -1;
float maxV = 256.0;

// for saving measurements
Table table;
float background = maxV;

boolean simulation = true;

int frameCounter = 0;

float[][] touchPoints = new float[numTouchPoints][2];

void setup() {
  size(600, 600);
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
}

void draw() {
  background(255);
  
  if(simulation) {
    TableRow row = table.getRow(frameCounter);
    for(int i = 0; i < numAllData; i++){
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
    TableRow newRow = table.addRow();
    for(int i = 0; i < numAllData; i++){
       newRow.setFloat("position_"+i, gdata[i]); 
    }
  }
  float size = height/numRow;
  //println(frameCounter);
  for (int j = 0; j < numRow; j++){
    for(int i = 0; i < numCol; i++){
        float measurement = gdata[(numCol - 1 - i)*numRow + j];
        //float colorVal = map(measurement, 4096, 0, 0, height-20);
        float colorVal = measurement;
        //println(j + " " + i + " " + colorVal);
        float remap = (background-colorVal)/background;
        if(remap < 0)
          remap = 0;
        int[] rgb = cm.getColor(remap);
        fill(rgb[0], rgb[1], rgb[2]);
        noStroke();
        rect(i*size, j*size, size-3, size-3);
        //break; //show only the first row (since we only have one diode)
    }
    //break;
  }
  for(int i = 0; i < numTouchPoints; i++){ 
    touchPoints[i][0] = gdata[actualNumPixel + i * 2];
    touchPoints[i][1] = gdata[actualNumPixel + i * 2 + 1];
    //println(i + " " + touchPoints[i][0] + " " + touchPoints[i][1]);
  }
  float maxValue = 224.0;
  //println(touchPoints[4][1] + ", " + touchPoints[4][0]);
  for(int i = 4; i < 5; i++){ 
    if(touchPoints[i][0] < 255 && touchPoints[i][1] < 255 && touchPoints[i][0] > 0 && touchPoints[i][1] > 0 ) { 
      fill(0, 0, 0);
      noStroke();
      circle((maxValue - touchPoints[i][1]) * height / maxValue, touchPoints[i][0] * width / maxValue, 30);
      //println(touchPoints[0][0] + ", " + touchPoints[0][1]);
    }
  }
  frameCounter++;
  //// show FPS
  //fill(0);
  //textSize(20);
  //text("FPS: "+fpsIndicator, 20, 20);
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
  if (key == 'b'){
    float avg = 0;
    float max = 0;
    for(int i = 0; i < actualNumPixel; i++){
      avg += gdata[i];
      if(max < gdata[i])
        max = gdata[i];
    }
    avg /= actualNumPixel;
    println(max);
    background = max;
    //background = 4;
    //background = 100 - gdata[0];
  }
}
