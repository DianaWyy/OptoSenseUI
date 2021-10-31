import processing.net.*;

Server myServer;

int numRow = 8;
int numCol = 8;
int numPixel = numRow * numCol;

float[] gdata = new float[numPixel];
ColorMap cm = new ColorMap();
int fpsCounter = 0;
String fpsIndicator = "";
long lastTime = -1;



void setup() {
  size(600, 600);
  // Starts a myServer on port 2337
  myServer = new Server(this, 2337); 
  background(255);
  lastTime = millis();
}

void draw() {
  background(255);
  
  Client thisClient = myServer.available();

      if (thisClient != null) {
        
        calculateFPS();
        
        String whatClientSaid = thisClient.readString();
        if (whatClientSaid != null) {
          processData(whatClientSaid);
        } 
      }
      
      float size = height/numRow;
      
      for (int j = 0; j < numRow; j++){
        for(int i = 0; i < numCol; i++){
            float colorVal = gdata[i*numRow + j];
            int[] rgb = cm.getColor((float) ((255-colorVal)/255.0));
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
  
      if(data.length != numPixel) return;
      
      for(int i = 0; i < data.length; i++){
        gdata[i] = Float.parseFloat(data[i]);
      }
}
