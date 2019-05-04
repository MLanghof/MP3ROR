class PhysicalFrame
{
  PhysicalFrame(Header header, SideInformation sideInformation, byte[] rest, int headerStartByte)
  {
    this.header = header;
    this.sideInformation = sideInformation;
    this.rest = rest;
    this.headerStartByte = headerStartByte;
    
    headerAndSideInfoLengthInBytes = 4 + sideInformation.byteCount; 
  }
  
  Header header;
  SideInformation sideInformation;
  byte[] rest;
  int headerStartByte;
  int headerAndSideInfoLengthInBytes;
  
  float movingAverage;
  
  int getUnusedBytes()
  {
    if (false)
    {
    for (int i = 0; i < rest.length; ++i)
      if (rest[rest.length - i - 1] != 0)
        return i;
    }
    else
    {
      int ret = 0;
      for (int i = 0; i < rest.length; ++i)
        if (rest[rest.length - i - 1] == (byte)0xFF)
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
    
    g.translate(0, 30);
    sideInformation.drawOn(g);
  }
}



PhysicalFrame tryMakePhysicalFrame(ByteBuffer buf, int pos)
{
  Header header = tryMakeHeader(buf, pos);
  if (header == null)
    return null;
    
  SideInformation sideInformation = new SideInformation(buf, pos + 4, header.mode != Mode.SINGLE_CHANNEL);
  
  int frameLength = header.frameLengthInBytes;
  byte[] restBytes = new byte[frameLength - 4];
  buf.position(pos+4);
  buf.get(restBytes, 0, frameLength - 4);
  buf.rewind();
  
  return new PhysicalFrame(header, sideInformation, restBytes, pos);
}