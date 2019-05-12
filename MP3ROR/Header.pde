import java.util.*;

enum MPEGVersion { MPEG1, MPEG2 }; 
enum Layer { RESERVED, LAYER3, LAYER2, LAYER1 }; 
enum Mode { STEREO, JOINT_STEREO, DUAL_CHANNEL, SINGLE_CHANNEL }; 
enum ModeExtension { IS_OFF_MS_OFF, IS_ON_MS_OFF, IS_OFF_MS_ON, IS_ON_MS_ON }; 

class Header
{
  BitSet bits;
  
  // 12 sync word bits (all set)
  boolean valid = false;
  
  MPEGVersion version; // 1 bit
  
  Layer layer; // 2 bits
  
  boolean crcProtection; // 1 bit
  
  int bitrateIndex; // 4 bit
  int bitrateKbps;
  
  int frequencyIndex; // 2 bit
  int sampleRateHz;
  
  boolean padding; // 1 bit
  
  boolean privateBit; // 1 bit
  
  Mode mode; // 2 bit
  ModeExtension modeExtension; // 2 bit
  
  boolean copyrighted; // 1 bit
  
  boolean original; // 1 bit
  
  int emphasis; // 2 bit (meaning?)
  
  ////
  
  int frameLengthInBytes;
  
  Header(ByteBuffer buf, int pos)
  {
    byte[] bytes = new byte[4];
    buf.position(pos);
    buf.get(bytes, 0, 4);
    buf.rewind();
    bits = toProperBitset(bytes);
    
    BitSet syncBits = bits.get(0, 12);
    syncBits.flip(0, 12);
    if (!syncBits.isEmpty())
      return;
    
    version = bits.get(12) ? MPEGVersion.MPEG1 : MPEGVersion.MPEG2;
    layer = Layer.values()[intFromBits(bits, 13, 2)];
    if (layer == Layer.RESERVED)
      return;
    crcProtection = !bits.get(15);
    
    bitrateIndex = intFromBits(bits, 16, 4);
    bitrateKbps = getBitrateFromIndex(version, layer, bitrateIndex);
    if (bitrateKbps <= 0)
      return;
    
    frequencyIndex = intFromBits(bits, 20, 2);
    sampleRateHz = getSamplingFrequencyFromIndex(version, frequencyIndex);
    if (sampleRateHz <= 0)
      return;
    
    padding = bits.get(22);
    privateBit = bits.get(23);
    
    mode = Mode.values()[intFromBits(bits, 24, 2)];
    modeExtension = ModeExtension.values()[intFromBits(bits, 26, 2)];
    
    copyrighted = bits.get(28);
    original = bits.get(29);
    
    emphasis = intFromBits(bits, 30, 2);
    
    valid = true;
    
    if (layer != Layer.LAYER1)
      frameLengthInBytes = (int)(144 * bitrateKbps / (sampleRateHz / 1000.0)) + (padding ? 1 : 0);
    else
      frameLengthInBytes = (int)(12 * bitrateKbps / (sampleRateHz / 1000.0)) + (padding ? 1 : 0);
  }
  
  void drawOn(PGraphics g)
  {
    g.fill(200);
    g.text("Frame length in bytes: " +  frameLengthInBytes, 0, 0);
    g.translate(0, 20);
    g.text(version.toString(), 0, 0);
    g.translate(0, 20);
    g.text(layer.toString(), 0, 0);
    g.translate(0, 20);
    g.text("Has CRC: " + crcProtection, 0, 0);
    g.translate(0, 20);
    g.text("Bit Rate: " + bitrateKbps, 0, 0);
    g.translate(0, 20);
    g.text("Sample Rate: " + sampleRateHz, 0, 0);
    g.translate(0, 20);
    g.text("Mode: " + mode.toString(), 0, 0);
    g.translate(0, 20);
    g.text("Mode extension: " + modeExtension.toString(), 0, 0);
    g.translate(0, 20);
    g.text("Copyrighted: " + copyrighted, 0, 0);
    g.translate(0, 20);
  }
}

Header tryMakeHeader(ByteBuffer buf, int pos, boolean beExtraSafe)
{
  // First 8 bits must be inside the sync word.
  if (buf.get(pos) != (byte)0xFF)
    return null;
  
  // Form a header (does the check for sync word).
  Header header = new Header(buf, pos);
  if (!header.valid)
    return null;
  
  // If we're not at the end, check that another header starts after this frame.
  int frameLength = header.frameLengthInBytes;
  if (beExtraSafe && pos + frameLength + 1 < buf.limit()) {
    if (buf.get(pos + frameLength) != (byte)0xFF)
      return null;
    if (!new Header(buf, pos + frameLength).valid)
      return null;
  }
  
  return header;
}


int getBitrateFromIndex(MPEGVersion mpegVersion, Layer layer, int bitrateIndex)
{
  if (mpegVersion == MPEGVersion.MPEG1)
  {
    int[] bitratesL1 = {-1, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, -1};
    int[] bitratesL2 = {-1, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, -1};
    int[] bitratesL3 = {-1, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, -1};
    if (layer == Layer.LAYER1)
      return bitratesL1[bitrateIndex];
    else if (layer == Layer.LAYER2)
      return bitratesL2[bitrateIndex];
    else
      return bitratesL3[bitrateIndex];
  }
  else
  {
    if (layer != Layer.LAYER3)
      return -1;
    int[] bitrates = {-1, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, -1};
    return bitrates[bitrateIndex];
  }
}

int getSamplingFrequencyFromIndex(MPEGVersion mpegVersion, int samplingRateIndex)
{
  if (mpegVersion == MPEGVersion.MPEG1)
  {
    int[] frequencies = {44100, 48000, 32000, -1};
    return frequencies[samplingRateIndex];
  }
  else
  {
    int[] frequencies = {22050, 24000, 16000, -1};
    return frequencies[samplingRateIndex];
  }
}


BitSet getSyncWord()
{
  BitSet ret = new BitSet(12);
  ret.flip(0, 12);
  return ret;
}