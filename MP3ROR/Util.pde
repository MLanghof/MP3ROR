

BitSet toProperBitset(byte[] bytes)
{
  // See: https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/Mp3filestructure.svg/1920px-Mp3filestructure.svg.png
  // But with BitSet, if you throw new byte[] { 0xFF, 0xFB } into a BitSet, the 10th bit (1-based index as in the chart) will be 0.
  // So, we have to reverse the bit order of each byte first >_>
  // Also see the Test page.
  //java.lang.Byte.reverse((byte)0x0F);
  byte[] reversed = new byte[bytes.length];
  for (int i = 0; i < bytes.length; ++i)
    reversed[i] = (byte)(Integer.reverse(bytes[i]) >>> 24);
  return BitSet.valueOf(reversed);
}


int intFromBits(BitSet bits, int start, int count)
{
  int ret = 0;
  for (int i = 0; i < count; ++i)
    if (bits.get(start + i))
      ret += 1 << (count - 1 - i);
  return ret;
}


float[] map(float[] input, float min, float max, float newMin, float newMax)
{
  float[] ret = new float[input.length];
  for (int i = 0; i < input.length; ++i)
    ret[i] = map(input[i], min, max, newMin, newMax);
  return ret;
}


float[] getMovingAverage(float[] input, float rate)
{
  float[] ret = new float[input.length];
  
  if (input.length > 0)
  {
    ret[0] = input[0];
    for (int i = 1; i < input.length; ++i)
      ret[i] = rate * input[i] + (1-rate) * ret[i-1];
  }

  return ret;
}