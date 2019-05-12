class PhysicalFrame
{
  PhysicalFrame(Header header, SideInformation sideInformation, byte[] rest, int headerStartByte)
  {
    this.header = header;
    this.sideInformation = sideInformation;
    this.bytes = rest;
    this.headerStartByte = headerStartByte;
    
    headerAndSideInfoLengthInBytes = 4 + sideInformation.byteCount; 
  }
  
  Header header;
  SideInformation sideInformation;
  byte[] bytes;
  int headerStartByte;
  int headerAndSideInfoLengthInBytes;
  
  int getUnusedBytes()
  {
    if (false)
    {
    for (int i = 0; i < bytes.length; ++i)
      if (bytes[bytes.length - i - 1] != 0)
        return i;
    }
    else
    {
      int ret = 0;
      for (int i = 0; i < bytes.length; ++i)
        if (bytes[bytes.length - i - 1] == (byte)0xFF)
          ++ret;
      return ret;
    }
    assert(false);
    return -1;
  }
  
  void drawOn(PGraphics g)
  {
    g.fill(255);
    g.text("Index: " + headerStartByte + " of " + songBytes.length, 0, 0);
    
    g.translate(0, 30);
    header.drawOn(g);
    
    g.text("Header + side info length: " + headerAndSideInfoLengthInBytes, 0, 20);
    
    g.translate(0, 60);
    sideInformation.drawOn(g);
  }
}



PhysicalFrame tryMakePhysicalFrame(ByteBuffer buf, int pos, boolean beExtraSafe)
{
  Header header = tryMakeHeader(buf, pos, beExtraSafe);
  if (header == null)
    return null;
    
  SideInformation sideInformation = new SideInformation(buf, pos + 4, header.mode != Mode.SINGLE_CHANNEL);
  
  int frameLength = header.frameLengthInBytes;
  
  // I've seen files that were one byte short...
  if (buf.limit() < pos+frameLength)
    return null;
  
  byte[] frameBytes = new byte[frameLength];
  buf.position(pos);
  buf.get(frameBytes, 0, frameLength);
  buf.rewind();
  
  return new PhysicalFrame(header, sideInformation, frameBytes, pos);
}