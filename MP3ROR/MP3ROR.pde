import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;

import ddf.minim.analysis.*;
import ddf.minim.spi.*;
import ddf.minim.*;

import java.nio.ByteBuffer;
import java.nio.FloatBuffer;

Minim minim;  
AudioPlayer player;

String hardcodedFilePath = "D:/Users/Max/Music/Electronic/Fresch/KDrew - Last Train To Paradise (Dr. Fresch Remix).mp3";
//String hardcodedFilePath = "D:/Users/Max/Music/Electronic/Fresch/02_-_Destroy_Everything_You_Touch.mp3";
//String hardcodedFilePath = "D:/Users/Max/Music/Electronic/Fresch/06_-_Know_Your_Enemy.mp3";
//String hardcodedFilePath = "D:/Users/Max/Music/Electronic/Fresch/07_-_Last_Nite.mp3";
//String hardcodedFilePath = "D:/Users/Max/Music/Electronic/Fresch/01 Sehnsucht.mp3";
//String hardcodedFilePath = "D:/Users/Max/Music/Electronic/Fresch/potato.mp3";

byte[] songBytes;

final int BYTES_PER_ROW = 64;

int byteOffset = 0;
int currentFrameIndex = 0;


ArrayList<PhysicalFrame> frames;

boolean doneLoading = false;

boolean showByteStream = true;
boolean showFrameInfo = true;

void setup()
{
  size(1800, 900, P2D);
  
  minim = new Minim(this);
  
  runTests();
}


void draw()
{
  background(0);
  
  if (player == null && frameCount == 1)
  {
    //selectInput("Select an MP3 file to use: ", "onFileSelected", new File(filePath));
    thread("loadHardcodedFile");
  }
  
  if (!doneLoading)
    return;
  
  PhysicalFrame currentFrame = frames.get(currentFrameIndex);
  
  if (showByteStream && songBytes != null)
    drawByteStream(g, currentFrame);
  
  if (showFrameInfo)
  {
    pushMatrix();
    translate(20 + (showByteStream ? 20 * BYTES_PER_ROW : 0), 20);
    currentFrame.drawOn(g);
    popMatrix();
  }
    
  
  beginShape(LINES);
  strokeWeight(0.5);
  float prevFX = 0;
  float prevFY1 = 0;
  float prevFY2 = 0;
  for (int i = 0; i < frames.size(); ++i)
  {
    PhysicalFrame frame = frames.get(i);
    float fx = map(i, 0, frames.size(), 0, width);
    float fy1 = map(frame.getUnusedBytes(), 0, frame.header.frameLengthInBytes, height, 0);
    //float fy1 = map(frame.header.frameLengthInBytes, 0, 4096, height, 0);
    //float fy2 = map(frame.movingAverage, 0, frame.header.frameLengthInBytes, height, 0);
    float fy2 = map(frame.movingAverage, 0, 4096, height, 0);
    
    stroke(200);
    vertex(prevFX, prevFY1);
    vertex(fx, fy1);
    
    stroke(100);
    vertex(fx, height);
    vertex(fx, fy1);
    
    stroke(255, 0, 0);
    if (i > 0) {
      vertex(prevFX, prevFY2);
      vertex(fx, fy2);
    }
    prevFX = fx;
    prevFY1 = fy1;
    prevFY2 = fy2;
  }
  endShape();
  
  float fpos = map(player.position(), 0, getRealPlayerLength(), 0, width);
  stroke(255, 0, 0);
  line(fpos, 0, fpos, height);
  
  if (player.isPlaying()) {
    currentFrameIndex = (int)map(player.position(), 0, getRealPlayerLength(), 0, frames.size()) - 1; 
    
    seekNextFrame(+1);
  }
  
  if (currentFrameIndex >= 0)
  {
    float fpos2 = map(26 * currentFrameIndex, 0, getRealPlayerLength(), 0, width);
    stroke(0, 255, 0);
    line(fpos2, 0, fpos2, height);
  }
  
  for(int i = 0; i < player.bufferSize() - 1; i++)
  {
    float x1 = map(i, 0, player.bufferSize(), 0, width);
    float x2 = map(i+1, 0, player.bufferSize(), 0, width);
    line(x1, 50 + player.left.get(i)*50, x2, 50 + player.left.get(i+1)*50);
    line(x1, 150 + player.right.get(i)*50, x2, 150 + player.right.get(i+1)*50);
  }
  
  fpos = map(frames.get(currentFrameIndex).headerStartByte, frames.get(0).headerStartByte, songBytes.length, 0, width);
  stroke(0, 0, 255);
  line(fpos, 0, fpos, height);
  
  text("FPS: " + frameRate, width - 90, 20);
}

void keyPressed()
{
  if (!doneLoading)
    return;
    
  switch (keyCode)
  {
    case RIGHT:
      seekNextFrame(+1);
      break;
    case LEFT:
      seekNextFrame(-1);
      break;
    
    case UP:
      byteOffset -= BYTES_PER_ROW;
      break;
    case DOWN:
      byteOffset += BYTES_PER_ROW;
      break;
  }
  
  switch (key)
  {
    case ' ':
      if (player.isPlaying())
        player.pause();
      else
        player.play();
      break;
    
    case 'o':
      player.close();
      doneLoading = false;
      selectInput("Select an MP3 file to use: ", "onFileSelected", new File(hardcodedFilePath));
      break;
    
    case 'b':
      showByteStream = !showByteStream;
      break;
    case 'i':
      showFrameInfo = !showFrameInfo;
      break;
  }
    
}

void mousePressed()
{
  if (!doneLoading)
    return;
  
  float fpos = float(mouseX) / width;
  int startFrom = round(fpos * getRealPlayerLength());
  player.play(startFrom);
  player.cue(startFrom);
  
  println("Player position:", player.position());
  println("Player length:", getRealPlayerLength());
}


void drawByteStream(PGraphics g, PhysicalFrame frameToDisplay)
{
  int index = frameToDisplay.headerStartByte - byteOffset;
  index = constrain(index, 0, songBytes.length - 1);
  
  int y = 10;
  g.fill(200);
  while (y < g.height)
  {
    for (int i = 0; i < BYTES_PER_ROW; ++i)
    {
      if (index >= songBytes.length)
        return;
        
      byte b = songBytes[index];
      
      g.fill(getByteColor(index, frameToDisplay));
      g.text(hex(b, 2), 20 * i, y);
      
      ++index;
    }
    
    y += 20;
  }
}

color getByteColor(int index, PhysicalFrame frame)
{
  int frameLocalIndex = index - frame.headerStartByte;
  
  // Outside of this frame
  if (frameLocalIndex < 0 || frameLocalIndex >= frame.header.frameLengthInBytes)
    return color(255);
  
  // Header
  if (frameLocalIndex < 4)
    return color(255, 40, 70);
  
  // Side information
  if (frameLocalIndex < frame.headerAndSideInfoLengthInBytes)
    return color(80, 100, 255);
  
  // Main data (not necessarily of this frame)
  return color(50, 255, 50);
}

void loadHardcodedFile()
{
  onFileSelected(new File(hardcodedFilePath));
}

void onFileSelected(File file)
{
  String filePath = file.getAbsolutePath();
  
  player = minim.loadFile(filePath, 1024);
  player.setGain(-20);
  
  songBytes = loadBytes(filePath);
  
  println("Loaded", songBytes.length, "bytes from", filePath);
  
  frames = new ArrayList();
  ByteBuffer buf = ByteBuffer.wrap(songBytes);
  int pos = -1;
  float movingAverage = 0;
  final float rate = 0.1;
  do
  {
    ++pos;
    PhysicalFrame frame = tryMakePhysicalFrame(buf, pos);
    if (frame != null) {
      frames.add(frame);
      movingAverage *= 1 - rate;
      //movingAverage += rate * frame.getUnusedBytes();
      movingAverage += rate * frame.header.frameLengthInBytes;
      frame.movingAverage = movingAverage;
    }
  } while(pos < songBytes.length - 4);
  
  println("Done parsing", frames.size(), "frames!");
  
  doneLoading = true;
}

void seekNextFrame(int diff)
{
  currentFrameIndex = constrain(currentFrameIndex + diff, 0, frames.size()-1);
}

int getRealPlayerLength()
{
  return frames.size() * 26;
}