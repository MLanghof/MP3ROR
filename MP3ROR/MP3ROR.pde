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

byte[] songBytes;

final int BYTES_PER_ROW = 64;


int byteIndex = 0;
int currentFrameIndex = 0;


ArrayList<PhysicalFrame> frames;

void setup()
{
  size(1800, 900, P2D);
  
  minim = new Minim(this);
  
  runTests();
}


void draw()
{
  if (player == null && frameCount == 1)
  {
    //selectInput("Select an MP3 file to use: ", "onFileSelected", new File(filePath));
    thread("loadHardcodedFile");
  }
  
  background(0);
  
  
  if (songBytes != null)
    drawByteStream(g);
    
  if (frames != null)
  {
    PhysicalFrame currentFrame = frames.get(currentFrameIndex);
    Header currentHeader = currentFrame.header;
    int x = 20 * BYTES_PER_ROW + 40;
    int y = 20;
    text("Index: " + byteIndex + " of " + songBytes.length, x, y); y += 20;
    text("Frame length in bytes: " +  currentHeader.frameLengthInBytes, x, y); y += 20;
    text(currentHeader.version.toString(), x, y); y += 20;
    text(currentHeader.layer.toString(), x, y); y += 20;
    text("Bit Rate: " + currentHeader.bitrateKbps, x, y); y += 20;
    text("Sample Rate: " + currentHeader.sampleRateHz, x, y); y += 20;
    
    
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
      float fy2 = map(frame.movingAverage, 0, frame.header.frameLengthInBytes, height, 0);
      
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
  }
  
  if (player != null)
  {
    float fpos = map(player.position(), 0, getRealPlayerLength(), 0, width);
    stroke(255, 0, 0);
    line(fpos, 0, fpos, height);
    
    if (frames != null && songBytes != null && player.isPlaying()) {
      currentFrameIndex = (int)map(player.position(), 0, getRealPlayerLength(), 0, frames.size()) - 1; 
      
      seekNextFrame(+1);
    }
    
    if (frames != null && currentFrameIndex >= 0)
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
  }
  
  if (songBytes != null && frames != null)
  {
    float fpos = map(byteIndex, frames.get(0).startByte, songBytes.length, 0, width);
    stroke(0, 0, 255);
    line(fpos, 0, fpos, height);
  }
  
  text(frameRate, width - 90, 20);
}

void keyPressed()
{
  if (keyCode == RIGHT)
    seekNextFrame(+1);
  if (keyCode == LEFT)
    seekNextFrame(-1);
    
  if (key == ' ')
    player.pause();
}

void mousePressed()
{
  if (player == null)
    return;
  
  float fpos = float(mouseX) / width;
  int startFrom = round(fpos * getRealPlayerLength());
  player.play(startFrom);
  player.cue(startFrom);
  
  println("Player position:", player.position());
  println("Player length:", getRealPlayerLength());
}


void drawByteStream(PGraphics g)
{
  PhysicalFrame currentFrame = frames != null ? frames.get(currentFrameIndex) : null;
  ByteBuffer buf = ByteBuffer.wrap(songBytes);
  
  int localIndex = currentFrame != null ? currentFrame.startByte : byteIndex;
  localIndex = max(0, localIndex);
  
  int y = 10;
  g.fill(200);
  while (y < g.height)
  {
    for (int i = 0; i < BYTES_PER_ROW; ++i)
    {
      if (localIndex >= buf.limit())
        return;
      byte b = buf.get(localIndex);
      ++localIndex;
      g.fill(255);
      if (currentFrame != null && localIndex - byteIndex <= currentFrame.header.frameLengthInBytes)
        g.fill(0, 255, 0);
      if (b == (byte)0xFB)
        g.fill(255, 0, 0);
      g.text(hex(b, 2), 20 * i, y);
    }
    
    y += 20;
  }
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
  
  ArrayList<PhysicalFrame> tmpFrames = new ArrayList();
  ByteBuffer buf = ByteBuffer.wrap(songBytes);
  int pos = -1;
  float movingAverage = 0;
  final float rate = 0.1;
  do
  {
    ++pos;
    PhysicalFrame frame = tryMakePhysicalFrame(buf, pos);
    if (frame != null) {
      tmpFrames.add(frame);
      movingAverage *= 1 - rate;
      movingAverage += rate * frame.getUnusedBytes();
      frame.movingAverage = movingAverage;
    }
  } while(pos < songBytes.length - 4);
  
  println("Done parsing", tmpFrames.size(), "frames!");
  frames = tmpFrames;
}

void seekNextFrame(int diff)
{
  if (frames == null)
    return;
  
  currentFrameIndex = constrain(currentFrameIndex + diff, 0, frames.size()-1);
  
  byteIndex = frames.get(currentFrameIndex).startByte;
}

int getRealPlayerLength()
{
  assert(frames != null);
  return frames.size() * 26;
}