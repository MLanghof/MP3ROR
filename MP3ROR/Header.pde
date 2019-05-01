import java.util.*;

  enum MPEGVersion { MPEG1, MPEG2 }; 
  enum Layer { LAYER1, LAYER2, LAYER3, RESERVED }; 
  enum Mode { STEREO, SINGLE_CHANNEL, DUAL_CHANNEL, JOINT_STEREO }; 
  enum ModeExtension { IS_OFF_MS_OFF, IS_ON_MS_OFF, IS_OFF_MS_ON, IS_ON_MS_ON }; 

class Header
{
  // 12 sync word bits (all set)
  
  MPEGVersion id; // 1 bit
  
  Layer layer; // 2 bits
  
  boolean crcProtection; // 1 bit
  
  int bitrateIndex; // 4 bit
  int bitrateKbps;
  
  int frequencyIndex; // 2 bit
  int samplingFrequency;
  
  boolean padding; // 1 bit
  
  boolean privateBit; // 1 bit
  
  Mode mode; // 2 bit
  ModeExtension modeExtension; // 2 bit
  
  boolean copyrighted; // 1 bit
  
  boolean original; // 1 bit
  
  int emphasis; // 2 bit (meaning?)
}

int getBitrateFromIndex(MPEGVersion mpegVersion, Layer layer, int bitrateIndex)
{
  assert(layer == Layer.LAYER3);
  if (mpegVersion == MPEGVersion.MPEG1)
  {
    int[] bitrates = {-1, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, -1};
    return bitrates[bitrateIndex];
  }
  else
  {
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

int getFrameLengthInBytes(int bitrateKbps, int sampleRateHz, boolean padding)
{
  return (int)(144 * bitrateKbps / (sampleRateHz / 1000.0)) + (padding ? 1 : 0);
}