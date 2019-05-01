void runTests()
{
  test1();
  test2();
  test3();
  test4();
}

void test1()
{
  byte[] bytes = new byte[] { (byte)0xFF, (byte)0x00 };
  BitSet bits = BitSet.valueOf(bytes);
  for (int i = 0; i < 16; ++i)
    print(bits.get(i) ? "1" : "0");
  println(" <- test1 bits");
  assert(bits.get(0));
  assert(bits.get(1));
  assert(bits.get(6));
  assert(bits.get(7));
  assert(!bits.get(8));
  assert(!bits.get(9));
  assert(!bits.get(14));
  assert(!bits.get(15));
  
  println("Passed Test 1");
}

void test2()
{
  byte[] bytes = new byte[] { (byte)0xFF, (byte)0xFB };
  BitSet bits = BitSet.valueOf(bytes);
  for (int i = 0; i < 16; ++i)
    print(bits.get(i) ? "1" : "0");
  println(" <- awful test2 bits");
    
  // This is not what we want:
  assert(bits.get(0));
  assert(bits.get(9));
  assert(!bits.get(10));
  assert(bits.get(11));
  
  BitSet goodBits = toProperBitset(bytes);
  for (int i = 0; i < 16; ++i)
    print(bits.get(i) ? "1" : "0");
  println(" <- good test2 bits");
  
  // This is what we want:
  assert(goodBits.get(0));
  assert(goodBits.get(12));
  assert(!goodBits.get(13));
  assert(goodBits.get(14));
  
  println("Passed Test 2");
}

void test3()
{
  byte a = (byte)0b00000001;
  byte[] bytes = new byte[] { a };
  BitSet bits = BitSet.valueOf(bytes);
  for (int i = 0; i < 8; ++i)
    print(bits.get(i) ? "1" : "0");
  println(" <- test3 bits");
  
  assert(bits.get(0));
  assert(!bits.get(1));
  assert(!bits.get(6));
  assert(!bits.get(7));
  
  println("Passed Test 3");
}

void test4()
{
  // Check if we get the same as https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/Mp3filestructure.svg/1920px-Mp3filestructure.svg.png
  byte[] bytes = new byte[] { (byte)0xFF, (byte)0xFB, (byte)0xA0, (byte)0x40 };
  ByteBuffer buf = ByteBuffer.wrap(bytes);
  Header header = new Header(buf, 0);
  
  for (int i = 0; i < 32; ++i)
    print(header.bits.get(i) ? "1" : "0");
  println(" <- test4 bits");
  
  assert(header.valid);
  assert(header.version == MPEGVersion.MPEG1);
  assert(header.layer == Layer.LAYER3); //<>//
  //assert(header.crcProtection == false); // TODO!
  assert(header.bitrateKbps == 160);
  assert(header.sampleRateHz == 44100);
  assert(header.padding == false);
  //assert(header.privateBit == ?); // Who cares
  assert(header.mode == Mode.JOINT_STEREO);
  assert(header.modeExtension == ModeExtension.IS_OFF_MS_OFF);
  assert(header.copyrighted == false);
  assert(header.original == false);
  assert(header.emphasis == 0);
  
  println("Passed Test 4");
}