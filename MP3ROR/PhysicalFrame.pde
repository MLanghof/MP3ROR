class PhysicalFrame
{
  PhysicalFrame(Header header, byte[] rest, int startByte)
  {
    this.header = header;
    this.rest = rest;
    this.startByte = startByte;
  }
  
  Header header;
  byte[] rest;
  int startByte;
  
  float movingAverage;
  
  int getUnusedBytes()
  {
    for (int i = 0; i < rest.length; ++i)
      if (rest[rest.length - i - 1] != 0)
        return i;
    assert(false);
    return -1;
  }
}



PhysicalFrame tryMakePhysicalFrame(ByteBuffer buf, int pos)
{
  Header header = tryMakeHeader(buf, pos);
  if (header == null)
    return null;
  
  int frameLength = header.frameLengthInBytes;
  byte[] restBytes = new byte[frameLength - 4];
  buf.position(pos+4);
  buf.get(restBytes, 0, frameLength - 4);
  buf.rewind();
  
  return new PhysicalFrame(header, restBytes, pos);
}