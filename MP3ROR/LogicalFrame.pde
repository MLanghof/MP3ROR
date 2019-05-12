class LogicalFrame
{
  Header header;
  SideInformation sideInformation;
  byte[] mainData;
}



LogicalFrame[] convertToLogicalFrames(ArrayList<PhysicalFrame> physicalFrames, ByteBuffer buffer)
{
  LogicalFrame[] logicalFrames = new LogicalFrame[physicalFrames.size()];
  
  // currentPhysicalFrame denotes which physical frame contains the main data we will read next 
  int currentPhysicalFrame = 0;
  
  int leftoverMainDataCountLastFrame = 0;
  
  buffer.position(physicalFrames.get(0).headerStartByte + physicalFrames.get(0).headerAndSideInfoLengthInBytes);
  
  for (int i = 0; i < logicalFrames.length; ++i)
  {
    LogicalFrame logicalFrame = new LogicalFrame(); //<>//
    PhysicalFrame physicalFrame = physicalFrames.get(i);
    
    logicalFrame.header = physicalFrame.header;
    logicalFrame.sideInformation = physicalFrame.sideInformation;
    
    // Currently unhandled. It's theoretically simple but without a test case I don't want to do it.
    assert(!logicalFrame.header.crcProtection);
    
    // In the following illustration (adapted from Figure 3-A.7.2 of the MPEG standard):
    // H = header byte (here 2 instead of 4 for illustration only)
    // S = side info byte
    // 0 = frame 0 main data
    // 1 = frame 1 main data
    // etc.
    //
    // Header 0                    Header 1          Header 2            Header 3          Header 4
    // | Side info 0               | SI1             | SI2               | SI3             |
    // | |  HSI0=9                 | |  HSI1=5       | |  HSI2=7         | |  HSI3=6       |
    // | |                         | |               | |                 | |               |
    // HHSSSSSSS0000000111112223333HHSSS3333333333333HHSSSSS3333333333333HHSSSSS33333334444HH...
    // .               |    |  |   .                 .                   .             |   .
    // .               |    |  <-------------------42--------------------|             <---|
    // .               |    |      .   main data end 2: 42-5-7 = 30      .       main data end 3: 4
    // .               |    |      .                 .                   .                 .
    // .               |    <-----------25-----------|                   .                 .
    // .               |    main data end 1: 25-5 = 20                   .                 .
    // .               |           .                 .                   .                 .
    // .               <-----12----|                 .                   .                 .
    // .             main data end 0: 12             .                   .                 .
    // .                           .                 .                   .                 .
    // |-------------------------->|---------------->|------------------>|---------------->|
    // Physical frame 0 length: 28      PF1L: 18           PF2L: 20           PF3L: 18

    // That looks complicated but there is a simple invariant: We always have a non-negative amount of
    // main data bytes from previous frames left. If you add this frame's main data bytes, then the
    // current Each frame adds (frame length - header length - side info length) bytes
    // and "owns"

    int mainDatBytesInThisFrame = physicalFrame.header.frameLengthInBytes - physicalFrame.headerAndSideInfoLengthInBytes;
    int availableMainDataBytes = leftoverMainDataCountLastFrame + mainDatBytesInThisFrame;
    
    int mainDataBytesForThisFrame = availableMainDataBytes - physicalFrame.sideInformation.mainDataBegin;
    if (mainDataBytesForThisFrame < 0)
      println("Ooops");
    
    logicalFrame.mainData = new byte[mainDataBytesForThisFrame];
    
    // Read N bytes. Whenever at the end of a physical frame, skip over the header and side information of the next one.
    // byte-for-byte version:
    int bytesRead = 0;
    int currentPhysicalFrameEnd = physicalFrames.get(currentPhysicalFrame).headerStartByte + physicalFrames.get(currentPhysicalFrame).header.frameLengthInBytes;
    while (bytesRead < mainDataBytesForThisFrame)
    {
      if (buffer.position() < currentPhysicalFrameEnd)
      {
        logicalFrame.mainData[bytesRead] = buffer.get();
        bytesRead++;
      }
      else
      {
        // Advance to the next physical frame and skip its header + side information.
        currentPhysicalFrame++;
        if (currentPhysicalFrame == physicalFrames.size())
          println("Ooops...");
        currentPhysicalFrameEnd = physicalFrames.get(currentPhysicalFrame).headerStartByte + physicalFrames.get(currentPhysicalFrame).header.frameLengthInBytes;
        buffer.position(buffer.position() + physicalFrames.get(currentPhysicalFrame).headerAndSideInfoLengthInBytes);
      }
    }
    
    leftoverMainDataCountLastFrame = availableMainDataBytes - mainDataBytesForThisFrame;
    assert(leftoverMainDataCountLastFrame == physicalFrame.sideInformation.mainDataBegin);
    
    logicalFrames[i] = logicalFrame;
  }
  
  return logicalFrames;
}