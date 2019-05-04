class LogicalFrame
{
  Header header;
  SideInformation sideInformation;
  byte[] ancillaryData;
}


    // assert(!header.crcProtection); // We cannot handle this!
    // Actually it's just 16 bits (or bytes? conflicting info...) of crc that we have to discard...