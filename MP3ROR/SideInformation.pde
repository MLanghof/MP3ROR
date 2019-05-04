class SideInformation
{
  int mainDataBegin; // 9 bits - negative offset from first byte of sync word
  
  int privateBits; // 5 (m) or 3 (s) bits - nothing we care about
  
  int scfsi; // 4 (m) or 8 (s) bits - whether scale factors for a group of bands is to be copied from granule 1 to granule 2.
  // Groups are: 0-5, 6-10, 11-15, 16-20
  // If blockType = 0b10 (short windows) each of the 3/6 granules already stores its scale factors
  // 
  
  GranuleChannelSideInformation[] gcSideInfo;
  
  ///
  
  BitSet bits;
  int byteCount;
  int channelCount;
  
  
  SideInformation(ByteBuffer buf, int pos, boolean isStereo)
  {
    byteCount = isStereo ? 32 : 17;
    channelCount = isStereo ? 2 : 1;
    
    byte[] bytes = new byte[byteCount];
    buf.position(pos);
    buf.get(bytes, 0, byteCount);
    buf.rewind();
    bits = toProperBitset(bytes);
    
    mainDataBegin = intFromBits(bits, 0, 9);
    privateBits = intFromBits(bits, 9, isStereo ? 3 : 5);
    int currentPos = 9 + (isStereo ? 3 : 5);
    scfsi = intFromBits(bits, currentPos, 4 * channelCount);
    currentPos += 4 * channelCount;
    
    gcSideInfo = new GranuleChannelSideInformation[2 * channelCount];
    
    for (int granule = 0; granule < 2; ++granule)
    {
      for (int channel = 0; channel < channelCount; ++channel)
      {
        gcSideInfo[granule * channelCount + channel] = new GranuleChannelSideInformation(bits, currentPos);
        
        currentPos += GranuleChannelSideInformation.LENGTH_IN_BITS;
      }
    }
    
    assert(currentPos == byteCount * 8);
  }
  
  void drawOn(PGraphics g)
  {
    g.fill(200);
    g.text("Main data offset: " + (-mainDataBegin), 0, 0);
    g.translate(0, 20);
    g.text("Private bits content: " + privateBits, 0, 0);
    g.translate(0, 20);
    g.text("Scale factors to be copied: " + scfsi, 0, 0);
    g.translate(0, 20);
    
    g.translate(0, 20);
    for (int granule = 0; granule < 2; ++granule)
    {
      for (int channel = 0; channel < channelCount; ++channel)
      {
        g.pushMatrix();
        g.translate(channel * 250, granule * 250);
        g.text("Granule " + granule + ", channel " + channel, 0, 0);
        g.translate(0, 20);
        gcSideInfo[granule * channelCount + channel].drawOn(g);
        g.popMatrix();
      }
    }
  }
}

class GranuleChannelSideInformation
{
  int par23length; // 12 bits - number of bits that make up scale factors and huffman data of this granule in the main data 
  
  int bigValues; // 9 bits - size of the big_values region of the frequency lines
  
  int globalGain; // 8 bits - quantization step size
  
  int scalefacCompress; // 4 bits - TODO
  
  boolean blocksplitFlag; // 1 bit - TODO 
  
  
  int moreStuff; // 22 bits, depends on blocksplitFlag...
  
  boolean preflag; // 1 bit - TODO
  
  boolean scalefacScale; // 1 bit - TODO
  float scaleFactorQuantizationStep;
  
  boolean count1TableSelect; // 1 bit - TODO
  
  static final int LENGTH_IN_BITS = 59;
  
  GranuleChannelSideInformation(BitSet bits, int bufPos)
  {
    par23length = intFromBits(bits, bufPos, 12);
    bigValues = intFromBits(bits, bufPos + 12, 9);
    globalGain = intFromBits(bits, bufPos + 21, 8);
    scalefacCompress = intFromBits(bits, bufPos + 29, 4);
    blocksplitFlag = bits.get(bufPos + 33);
    moreStuff = intFromBits(bits, bufPos + 34, 22);
    preflag = bits.get(bufPos + 56);
    scalefacScale = bits.get(bufPos + 57);
    count1TableSelect = bits.get(bufPos + 58);
    // 59 bits total
    
    scaleFactorQuantizationStep = scalefacScale ? 2 : sqrt(2);
  }
  
  void drawOn(PGraphics g)
  {
    g.text("Part 2 + 3 length: " + par23length, 0, 0);
    g.translate(0, 20);
    g.text("Big values region length: " + bigValues, 0, 0);
    g.translate(0, 20);
    g.text("Quantization step size: " + globalGain, 0, 0);
    g.translate(0, 20);
    g.text("Scalefactor index: " + scalefacCompress, 0, 0);
    g.translate(0, 20);
    g.text("Using different window: " + blocksplitFlag, 0, 0);
    g.translate(0, 20);
    g.text("moreStuff: " + moreStuff, 0, 0);
    g.translate(0, 20);
    g.text("High frequency amplification: " + preflag, 0, 0);
    g.translate(0, 20);
    g.text("Scale factor quantization:  " + scaleFactorQuantizationStep, 0, 0);
    g.translate(0, 20);
    g.text("Alternate quadruple huffman table: " + count1TableSelect, 0, 0);
    g.translate(0, 20);
  }
}