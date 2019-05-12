import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;

import ddf.minim.analysis.*;
import ddf.minim.spi.*;
import ddf.minim.*;

import java.nio.ByteBuffer;
import java.nio.FloatBuffer;

import java.awt.Toolkit;
import java.awt.datatransfer.StringSelection;

Minim minim;  
AudioPlayer player;

//String hardcodedFilePath = "D:/Users/Max/Music/Electronic/Fresch/KDrew - Last Train To Paradise (Dr. Fresch Remix).mp3";
//String hardcodedFilePath = "D:/Users/Max/Music/Electronic/Fresch/02_-_Destroy_Everything_You_Touch.mp3";
//String hardcodedFilePath = "D:/Users/Max/Music/Electronic/Fresch/06_-_Know_Your_Enemy.mp3";
//String hardcodedFilePath = "D:/Users/Max/Music/Electronic/Fresch/07_-_Last_Nite.mp3";
//String hardcodedFilePath = "D:/Users/Max/Music/Electronic/Fresch/01 Sehnsucht.mp3";
String hardcodedFilePath = "D:/Users/Max/Music/Electronic/Fresch/potatocbr.mp3";

byte[] songBytes;

final int BYTES_PER_ROW = 64;

int byteOffset = 0;
int currentFrameIndex = 0;


ArrayList<PhysicalFrame> frames;
LogicalFrame[] logicalFrames;

ArrayList<ICache> caches = new ArrayList();
FrameValueCache totalGranuleLengths = register(new FrameValueCache(new AverageAllGranuleLengthCalc(), true));
FrameValueCache leftGranuleLengths = register(new FrameValueCache(new AverageChannelGranuleLengthCalc(0), true));
FrameValueCache rightGranuleLengths = register(new FrameValueCache(new AverageChannelGranuleLengthCalc(1), true));

FrameValueCache allGranuleGains = register(new FrameValueCache(new AverageAllGranuleGlobalGainCalc(), true));
FrameValueCache leftGranuleGains = register(new FrameValueCache(new AverageChannelGranuleGlobalGainCalc(0), true));
FrameValueCache rightGranuleGains = register(new FrameValueCache(new AverageChannelGranuleGlobalGainCalc(1), true));

boolean doneLoading = false;

boolean showByteStream = true;
boolean showFrameInfo = true;
boolean showWaveform = true;

float plotFramesPerDot = 1.0;

void setup()
{
  size(1800, 900, P2D);
  
  minim = new Minim(this);
  
  hint(ENABLE_KEY_REPEAT);
  
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
  
  float percent = currentFrameIndex / float(frames.size());
  g.pushMatrix();
  g.translate(0, 300);
  g.stroke(200, 200, 200, 150);
  drawMovingPlot(g, totalGranuleLengths.values, percent, width, height / 3);
  g.stroke(140, 200, 140, 100);
  drawMovingPlot(g, leftGranuleLengths.values, percent, width, height / 3);
  g.stroke(200, 140, 140, 100);
  drawMovingPlot(g, rightGranuleLengths.values, percent, width, height / 3);
  
  g.translate(0, 300);
  g.stroke(200, 200, 200);
  drawMovingPlot(g, allGranuleGains.values, percent, width, height / 3);
  g.stroke(140, 200, 240, 100);
  drawMovingPlot(g, leftGranuleGains.values, percent, width, height / 3);
  g.stroke(200, 140, 240, 100);
  drawMovingPlot(g, rightGranuleGains.values, percent, width, height / 3);
  g.popMatrix();
  
  float fpos = map(player.position(), 0, getRealPlayerLength(), 0, width);
  stroke(255, 0, 0, 120);
  line(fpos, 0, fpos, height);
  fpos = percent * width;
  stroke(0, 255, 0, 120);
  line(fpos, 0, fpos, height);
  
  float forecastPercent = float(mouseX) / width;
  float forecastFrameDiff = (forecastPercent - percent) * frames.size();
  float plotPixelsPerFrame = 1.0 / plotFramesPerDot;
  float clickForecastX = percent * width + plotPixelsPerFrame * forecastFrameDiff;
  stroke(0, 120, 0, 120);
  line(clickForecastX, 0, clickForecastX, height);
  
  
  if (player.isPlaying()) {
    currentFrameIndex = (int)map(player.position(), 0, getRealPlayerLength(), 0, frames.size()) - 1; 
    
    seekNextFrame(+1);
  }
  
  if (showWaveform)
  {
    g.stroke(80);
    for(int i = 0; i < player.bufferSize() - 1; i++)
    {
      float x1 = map(i, 0, player.bufferSize(), 0, width);
      float x2 = map(i+1, 0, player.bufferSize(), 0, width);
      line(x1, 50 + player.left.get(i)*50, x2, 50 + player.left.get(i+1)*50);
      line(x1, 150 + player.right.get(i)*50, x2, 150 + player.right.get(i+1)*50);
    }
  }
  
  fpos = map(frames.get(currentFrameIndex).headerStartByte, frames.get(0).headerStartByte, songBytes.length, 0, width);
  stroke(0, 0, 255);
  line(fpos, 0, fpos, height);
  
  text("FPS: " + frameRate, width - 120, 20);
  text("Player: " + player.position() / 1000.0, width - 120, 40);
}

void keyPressed(KeyEvent e)
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
    case 'w':
      showWaveform = !showWaveform;
      break;
      
    case 'c':
      //if (e.isControlDown()) //<>//
        copyBytesToClipboard();
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

void mouseWheel(MouseEvent event)
{
  plotFramesPerDot *= pow(0.98, -event.getCount());
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

void copyBytesToClipboard()
{
  int index = frames.get(currentFrameIndex).headerStartByte - byteOffset;
  index = constrain(index, 0, songBytes.length - 1);
  
  StringBuilder sb = new StringBuilder();
  for (int i = 0; i < 100 * BYTES_PER_ROW; ++i)
    sb.append(hex(songBytes[index + i], 2)).append(" ");
  
  Toolkit toolkit = Toolkit.getDefaultToolkit();
  toolkit.getSystemClipboard().setContents(new StringSelection(sb.toString()), null);
  println("Copied visible bytes to clipboard");
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
  
  parseBytes(songBytes);
  //logicalFrames = convertToLogicalFrames(frames, ByteBuffer.wrap(songBytes));
  
  println("Done parsing", frames.size(), "frames!");
  
  for (ICache cache : caches)
    cache.update();
  
  println("Done updating caches!");
  
  doneLoading = true;
}

void parseBytes(byte[] songBytes)
{
  ByteBuffer buf = ByteBuffer.wrap(songBytes);
  frames = new ArrayList();
  int pos = 0;
  
  int start = millis();
  while (pos < songBytes.length - 4)
  {
    // If we haven't found any valid headers yet, make sure that we get the
    // first one right.
    boolean beExtraSafe = (frames.size() == 0);
    PhysicalFrame frame = tryMakePhysicalFrame(buf, pos, beExtraSafe);
    if (frame != null) {
      frames.add(frame);
      pos += frame.header.frameLengthInBytes;
    }
    else {
      ++pos;
    }
  }
  println(millis() - start, "ms");
}

void seekNextFrame(int diff)
{
  currentFrameIndex = constrain(currentFrameIndex + diff, 0, frames.size()-1);
}

int getRealPlayerLength()
{
  return frames.size() * 26;
}