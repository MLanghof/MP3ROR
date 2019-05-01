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

String filePath = "C:/Users/Max/Music/Electronic/Fresch/Maybe.mp3";

byte[] songBytes;

final int BYTES_PER_ROW = 32;

final byte[] FRAME_HEADER_BYTES = {(byte)0xFF, (byte)0xFB, (byte)0x78, (byte)0x64};
final int FRAME_HEADER_INT = ByteBuffer.wrap(FRAME_HEADER_BYTES).getInt();

int index = 0;

void setup()
{
  size(1600, 1200);
  
  minim = new Minim(this);
  
  player = minim.loadFile(filePath, 1024);
  songBytes = loadBytes(filePath);
  
  println("Loaded", songBytes.length, "bytes from", filePath);
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
      if (b == (byte)0xFF)
        g.fill(255, 0, 0); //<>//
      else if (b == (byte)0xFB)
        g.fill(0, 255, 0);
      else
        g.fill(255);
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
  index += BYTES_PER_ROW;
  if (true)
    return;
  
  ByteBuffer buf = ByteBuffer.wrap(songBytes);
  do
  {
    ++index;
    //if (buf.getInt(index) == FRAME_HEADER_INT) {
    if (buf.get(index) == 0xFF) {
      println("Found next frame start at byte", index);
      break;
    }
  } while(index < songBytes.length - 4);
  
  println("Did not find another frame header!", buf.remaining());
  //index = 0;
}