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

String filePath = "D:/Users/Max/Music/Electronic/Fresch/KDrew - Last Train To Paradise (Dr. Fresch Remix).mp3";

byte[] songBytes;

final int BYTES_PER_ROW = 32;


int index = 0;
Header currentHeader;

void setup()
{
  size(1600, 800);
  
  minim = new Minim(this);
  
  player = minim.loadFile(filePath, 1024);
  songBytes = loadBytes(filePath);
  
  println("Loaded", songBytes.length, "bytes from", filePath);
  
  
  runTests();
}


void draw()
{
  if (player == null && frameCount == 1)
  {
    selectInput("Select an MP3 file to use: ", "onFileSelected", new File(filePath));
  }
  
  background(0);
  
  if (songBytes != null)
    drawByteStream(g);
    
  if (currentHeader != null)
  {
    int x = 20 * BYTES_PER_ROW + 40;
    int y = 20;
    text("Index: " + index + " of " + songBytes.length, x, y); y += 20;
    text("Frame length in bytes: " +  currentHeader.getFrameLengthInBytes(), x, y); y += 20;
    text(currentHeader.version.toString(), x, y); y += 20;
    text(currentHeader.layer.toString(), x, y); y += 20;
    text("Bit Rate: " + currentHeader.bitrateKbps, x, y); y += 20;
    text("Sample Rate: " + currentHeader.sampleRateHz, x, y); y += 20;
  }
}

void keyPressed()
{
  seekNextFrame();
}

void drawByteStream(PGraphics g)
{
  ByteBuffer buf = ByteBuffer.wrap(songBytes);
  int y = 10;
  int localIndex = index;
  g.fill(200);
  while (y < g.height)
  {
    for (int i = 0; i < BYTES_PER_ROW; ++i)
    {
      byte b = buf.get(localIndex);
      ++localIndex;
      g.fill(255);
      if (currentHeader != null && localIndex - index <= currentHeader.getFrameLengthInBytes())
        g.fill(0, 255, 0);
      if (b == (byte)0xFB)
        g.fill(255, 0, 0);
      g.text(hex(b, 2), 20 * i, y);
    }
    
    y += 20;
  }
}

void onFileSelected(File file)
{
}

void seekNextFrame()
{  
  ByteBuffer buf = ByteBuffer.wrap(songBytes);
  do
  {
    ++index;
    currentHeader = tryMakeHeader(buf, index);
    if (currentHeader != null) {
      return;
    }
  } while(index < songBytes.length - 4);
  
  println("Did not find another frame header!", buf.remaining());
  index = 0;
}